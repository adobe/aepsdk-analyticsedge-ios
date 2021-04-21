/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPCore
import AEPServices
import Foundation

/// Analytics extension for the Adobe Experience Platform SDK
@objc(AEPMobileAnalytics)
public class Analytics: NSObject, Extension {
    private let LOG_TAG = "AnalyticsEdge"

    public let runtime: ExtensionRuntime

    public let name = AnalyticsConstants.EXTENSION_NAME
    public let friendlyName = AnalyticsConstants.FRIENDLY_NAME
    public static let extensionVersion = AnalyticsConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil
    private let dataStore = NamedCollectionDataStore(name: AnalyticsConstants.DATASTORE_NAME)

    // MARK: Extension

    /// Initializes the Analytics extension and it's dependencies
    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()

        AnalyticsMigrator.migrateLocalStorage(dataStore: dataStore)
    }

    /// Invoked when the Analytics extension has been registered by the `EventHub`
    public func onRegistered() {
        registerListener(type: EventType.genericTrack, source: EventSource.requestContent, listener: handleAnalyticsRequest)
        registerListener(type: EventType.rulesEngine, source: EventSource.responseContent, listener: handleRulesEngineResponse)
        registerListener(type: EventType.configuration, source: EventSource.responseContent, listener: handleConfigurationResponse)
    }

    /// Invoked when the Analytics extension has been unregistered by the `EventHub`, currently a no-op.
    public func onUnregistered() {
        Log.trace(label: LOG_TAG, "Extension unregistered from MobileCore: \(AnalyticsConstants.FRIENDLY_NAME)")
    }

    /// Analytics extension is ready for an `Event` once configuration shared state is available
    /// - Parameter event: an `Event`
    public func readyForEvent(_ event: Event) -> Bool {
        return getSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: event)?.status == .set
    }

    // MARK: Event Listeners

    /// Handler for generic analytics track events
    /// - Parameter event: an event containing track data for processing
    private func handleAnalyticsRequest(event: Event) {
        if event.data == nil {
            Log.trace(label: LOG_TAG, "Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        Log.trace(label: LOG_TAG, "handleAnalyticsRequest - Processing event with id \(event.id.uuidString).")
        track(event: event, data: event.data)
    }

    /// Handler for rules engine response events
    /// - Parameter event: an event containing consequence for processing
    private func handleRulesEngineResponse(event: Event) {
        if event.data == nil {
            Log.trace(label: LOG_TAG, "Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        Log.trace(label: LOG_TAG, "handleRulesEngineResponse - Processing event with id \(event.id.uuidString).")

        guard let consequence = event.data?[AnalyticsConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] as? [String: Any] else {
            Log.trace(label: LOG_TAG, "handleRulesEngineResponse - Ignoring as missing consequence data for \(event.id.uuidString).")
            return
        }

        guard let consequenceType = consequence[AnalyticsConstants.EventDataKeys.TYPE] as? String, consequenceType == AnalyticsConstants.ConsequenceTypes.TRACK else {
            Log.trace(label: LOG_TAG, "handleRulesEngineResponse - Ignoring as consequence type is not analytics for \(event.id.uuidString).")
            return
        }

        guard let _ = consequence[AnalyticsConstants.EventDataKeys.ID] as? String else {
            Log.trace(label: LOG_TAG, "handleRulesEngineResponse - Ignoring as consequence id is missing for \(event.id.uuidString).")
            return
        }

        let consequenceDetail = consequence[AnalyticsConstants.EventDataKeys.DETAIL] as? [String: Any] ?? [:]
        track(event: event, data: consequenceDetail)
    }

    /// Handler for configuration response event
    /// - Parameter event: an event containing configuration response event
    private func handleConfigurationResponse(event: Event) {
        if event.data == nil {
            Log.trace(label: LOG_TAG, "Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        if let privacyStatusStr = event.data?[AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? String {
            let privacyStatus = PrivacyStatus(rawValue: privacyStatusStr) ?? PrivacyStatus.unknown
            if privacyStatus == .optedOut {
                // Clear persisted ids
                clearDataStore()
            }
        }
    }

    /// Process analytics track request
    /// - Parameter event: an event containing track data for processing
    /// - Parameter data: track data for processing
    private func track(event: Event, data: [String: Any]?) {
        if getPrivacyStatus(event: event) == .optedOut {
            Log.warning(label: LOG_TAG, "track - Dropping request (Privacy is opted out).")
            return
        }

        guard let data = data, data.keys.contains(AnalyticsConstants.EventDataKeys.TRACK_STATE) ||
            data.keys.contains(AnalyticsConstants.EventDataKeys.TRACK_ACTION) ||
            data.keys.contains(AnalyticsConstants.EventDataKeys.CONTEXT_DATA) else {
            Log.warning(label: LOG_TAG, "track - Dropping request as event data is missing state, action or contextData")
            return
        }

        let analyticsVars = processAnalyticsVars(event: event, data: data)
        let analyticsData = processAnalyticsData(event: event, data: data)
        sendAnalyticsHit(analyticsVars: analyticsVars, analyticsData: analyticsData)
    }

    /// Build analytics vars from track event data
    /// - Parameter event: an event containing track data for processing
    /// - Parameter data: track data for processing
    /// - Returns: Returns dictionary containing analytics vars
    private func processAnalyticsVars(event: Event, data: [String: Any]) -> [String: String] {
        var ret = [String: String]()

        // Context: pe/pev2 values should always be present in track calls if there's action regardless of state.
        // If state is present then pageName = state name else pageName = app id to prevent hit from being discarded.
        if let actionName = data[AnalyticsConstants.EventDataKeys.TRACK_ACTION] as? String, !actionName.isEmpty {
            ret[AnalyticsConstants.AnalyticsRequestKeys.IGNORE_PAGE_NAME] =  AnalyticsConstants.IGNORE_PAGE_NAME_VALUE
            let isInternal = data[AnalyticsConstants.EventDataKeys.TRACK_INTERNAL] as? Bool ?? false
            ret[AnalyticsConstants.AnalyticsRequestKeys.ACTION_NAME] = getActionPrefix(isInternalAction: isInternal) + actionName
        }

        ret[AnalyticsConstants.AnalyticsRequestKeys.PAGE_NAME] = AnalyticsHelper.getApplicationIdentifier()

        if let stateName = data[AnalyticsConstants.EventDataKeys.TRACK_STATE] as? String, !stateName.isEmpty {
            ret[AnalyticsConstants.AnalyticsRequestKeys.PAGE_NAME] = stateName
        }

        if let aid = getAID() {
            ret[AnalyticsConstants.AnalyticsRequestKeys.ANALYTICS_ID] = aid
        }

        if let vid = getVID() {
            ret[AnalyticsConstants.AnalyticsRequestKeys.VISITOR_ID] = vid
        }

        ret[AnalyticsConstants.AnalyticsRequestKeys.CHARSET] = AnalyticsConstants.CHARSET
        ret[AnalyticsConstants.AnalyticsRequestKeys.FORMATTED_TIMESTAMP] = TimeZone.current.getOffsetFromGmtInMinutes()

        // Set timestamp for all requests.
        ret[AnalyticsConstants.AnalyticsRequestKeys.STRING_TIMESTAMP] = String(event.timestamp.getUnixTimeInSeconds())

        if let appState = AnalyticsHelper.getApplicationState() {
            ret[AnalyticsConstants.AnalyticsRequestKeys.CUSTOMER_PERSPECTIVE] = appState == .background ? AnalyticsConstants.APP_STATE_BACKGROUND : AnalyticsConstants.APP_STATE_FOREGROUND
        }

        return ret
    }

    /// Build analytics context data from track event data
    /// - Parameter event: an event containing track data for processing
    /// - Parameter data: track data for processing
    /// - Returns: Returns dictionary containing analytics context data
    private func processAnalyticsData(event: Event, data: [String: Any]) -> [String: String] {
        var ret = [String: String]()

        let contextData = data[AnalyticsConstants.EventDataKeys.CONTEXT_DATA] as? [String: String] ?? [String: String]()
        if !contextData.isEmpty {
            contextData.forEach { (key, value) in ret[key] = value }
        }

        if let actionName = data[AnalyticsConstants.EventDataKeys.TRACK_ACTION] as? String, !actionName.isEmpty {
            let isInternal = data[AnalyticsConstants.EventDataKeys.TRACK_INTERNAL] as? Bool ?? false
            ret[getActionKey(isInternalAction: isInternal)] = actionName
        }

        if getPrivacyStatus(event: event) == .unknown {
            ret[AnalyticsConstants.AnalyticsRequestKeys.PRIVACY_MODE] = "unknown"
        }

        if isAssuranceSessionActive(event: event) {
            ret[AnalyticsConstants.ContextDataKeys.EVENT_IDENTIFIER_KEY] = event.id.uuidString
        }

        return ret
    }

    /// Constructs and sends legacy analytics XDM event
    /// - Parameter analyticsVars: a dictionary containing analytics vars
    /// - Parameter analyticsData: a dictionary containing analytics data
    private func sendAnalyticsHit(analyticsVars: [String: String], analyticsData: [String: String]) {
        var legacyAnalyticsData: [String: Any] = analyticsVars
        var contextData = [String: String]()

        legacyAnalyticsData["ndh"] = 1

        // It takes the provided data map and removes key-value pairs where the key is null or is prefixed with "&&"
        // The prefixed ones will be moved in the vars map
        for (key, value) in analyticsData {
            if key.hasPrefix(AnalyticsConstants.VAR_ESCAPE_PREFIX) {
                let strippedKey = String(key.dropFirst(AnalyticsConstants.VAR_ESCAPE_PREFIX.count))
                legacyAnalyticsData[strippedKey] = value
            } else if !key.isEmpty {
                contextData[key] = value
            }
        }
        legacyAnalyticsData[AnalyticsConstants.XDMDataKeys.CONTEXT_DATA] = contextData

        let xdm = [
            AnalyticsConstants.XDMDataKeys.EVENTTYPE: AnalyticsConstants.ANALYTICS_XDM_EVENTTYPE
        ]
        let edgeEventData: [String: Any] = [
            AnalyticsConstants.XDMDataKeys.LEGACY: [
                AnalyticsConstants.XDMDataKeys.ANALYTICS: legacyAnalyticsData
            ]
        ]

        let edgeEvent = Event(name: AnalyticsConstants.ANALYTICS_XDM_EVENTNAME,
                              type: EventType.edge,
                              source: EventSource.requestContent,
                              data: [AnalyticsConstants.XDMDataKeys.XDM: xdm,
                                     AnalyticsConstants.XDMDataKeys.DATA: edgeEventData]
        )
        dispatch(event: edgeEvent)
    }

    private func getActionKey(isInternalAction: Bool) -> String {
        return isInternalAction ? AnalyticsConstants.ContextDataKeys.INTERNAL_ACTION_KEY :
            AnalyticsConstants.ContextDataKeys.ACTION_KEY
    }

    private func getActionPrefix(isInternalAction: Bool) -> String {
        return isInternalAction ? AnalyticsConstants.INTERNAL_ACTION_PREFIX : AnalyticsConstants.ACTION_PREFIX
    }

    /// Returns the privacy status from configuration shared state w.r.t the event
    /// - Parameter event: An event to get configuration shared state
    /// - Returns : Returns privacy status w.r.t the event
    private func getPrivacyStatus(event: Event) -> PrivacyStatus {
        guard let configSharedState = getSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: event)?.value else { return .unknown
        }

        let privacyStatusStr = configSharedState[AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? String ?? ""
        return PrivacyStatus(rawValue: privacyStatusStr) ?? PrivacyStatus.unknown
    }

    /// Returns if assurance session is active
    /// - Parameter event: An event to get assurance shared state
    /// - Returns : Returns if assurance session is active
    private func isAssuranceSessionActive(event: Event) -> Bool {
        guard let assuranceSharedState = getSharedState(extensionName: AnalyticsConstants.Assurance.SHARED_STATE_NAME, event: event)?.value else {
            return false
        }

        let sessionId = assuranceSharedState[AnalyticsConstants.Assurance.SESSION_ID] as? String ?? ""
        return !sessionId.isEmpty
    }

    private func getAID() -> String? {
        return dataStore.getString(key: AnalyticsConstants.DataStoreKeys.AID)
    }

    private func getVID() -> String? {
        return dataStore.getString(key: AnalyticsConstants.DataStoreKeys.VID)
    }

    private func clearDataStore() {
        dataStore.remove(key: AnalyticsConstants.DataStoreKeys.AID)
        dataStore.remove(key: AnalyticsConstants.DataStoreKeys.VID)
        dataStore.remove(key: AnalyticsConstants.DataStoreKeys.IGNORE_AID)
    }
}
