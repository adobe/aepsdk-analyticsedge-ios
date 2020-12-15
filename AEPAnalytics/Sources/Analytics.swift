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
import AEPEdge

/// Analytics extension for the Adobe Experience Platform SDK
@objc(AEPMobileAnalytics)
public class Analytics: NSObject, Extension {
    private let LOG_TAG = "Analytics"

    public let runtime: ExtensionRuntime

    public let name = AnalyticsConstants.EXTENSION_NAME
    public let friendlyName = AnalyticsConstants.FRIENDLY_NAME
    public static let extensionVersion = AnalyticsConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil

    // MARK: Extension

    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
    }

    public func onRegistered() {
        registerListener(type: EventType.genericTrack, source: EventSource.requestContent, listener: handleAnalyticsRequest)
    }

    public func onUnregistered() {
        Log.trace(label: LOG_TAG, "Extension unregistered from MobileCore: \(AnalyticsConstants.FRIENDLY_NAME)")
    }

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
        track(event: event)
    }

    /// Process
    /// - Parameter event: an event containing track data for processing
    private func track(event: Event) {
        if getPrivacyStatus(event: event) == .optedOut {
            Log.warning(label: LOG_TAG, "track - Dropping track request (Privacy is opted out).")
        }

        let analyticsVars = processAnalyticsVars(event: event)
        let analyticsData = processAnalyticsData(event: event)
        sendAnalyticsHit(analyticsVars: analyticsVars, analyticsData: analyticsData)
    }

    private func processAnalyticsVars(event: Event) -> [String: String] {
        var ret = [String: String]()

        guard let eventData = event.data else {
            return ret
        }

        // context: pe/pev2 values should always be present in track calls if there's action regardless of state.
        // If state is present then pageName = state name else pageName = app id to prevent hit from being discarded.
        if let actionName = eventData[AnalyticsConstants.EventDataKeys.TRACK_ACTION] as? String, !actionName.isEmpty {
            ret[AnalyticsConstants.AnalyticsRequestKeys.IGNORE_PAGE_NAME] =  AnalyticsConstants.IGNORE_PAGE_NAME_VALUE
            let isInternal = eventData[AnalyticsConstants.EventDataKeys.TRACK_INTERNAL] as? Bool ?? false
            ret[AnalyticsConstants.AnalyticsRequestKeys.ACTION_NAME] = getActionPrefix(isInternalAction: isInternal) + actionName
        }
        // Todo :- We currently read application id from lifecycle
        //ret[AnalyticsConstants.AnalyticsRequestKeys.PAGE_NAME] = state->GetApplicationId();

        if let stateName = eventData[AnalyticsConstants.EventDataKeys.TRACK_STATE] as? String, !stateName.isEmpty {
            ret[AnalyticsConstants.AnalyticsRequestKeys.PAGE_NAME] = stateName
        }

        // Todo:- Aid. Should we add it to identity map or vars
        // Todo:- Vid. Should we add it to identity map or vars

        ret[AnalyticsConstants.AnalyticsRequestKeys.CHARSET] = AnalyticsConstants.CHARSET
        ret[AnalyticsConstants.AnalyticsRequestKeys.FORMATTED_TIMESTAMP] = TimeZone.current.getOffsetFromGmtInMinutes()

        // Set timestamp for all requests.
        ret[AnalyticsConstants.AnalyticsRequestKeys.STRING_TIMESTAMP] = String(event.timestamp.getUnixTimeInSeconds())

        // Todo:- GetAnalyticsIdVisitorParameters ??

        if let appState = AnalyticsHelper.getApplicationState() {
            ret[AnalyticsConstants.AnalyticsRequestKeys.CUSTOMER_PERSPECTIVE] = appState == .background ? AnalyticsConstants.APP_STATE_BACKGROUND : AnalyticsConstants.APP_STATE_FOREGROUND
        }

        return ret
    }

    private func processAnalyticsData(event: Event) -> [String: String] {
        var ret = [String: String]()

        // Todo:- Should we append default lifecycle context data (os version, device name, device version, etc) to each hits?

        let contextData = event.data?[AnalyticsConstants.EventDataKeys.CONTEXT_DATA] as? [String: String] ?? [String: String]()
        if !contextData.isEmpty {
            contextData.forEach { (key, value) in ret[key] = value }
        }

        if let actionName = event.data?[AnalyticsConstants.EventDataKeys.TRACK_ACTION] as? String, !actionName.isEmpty {
            let isInternal = event.data?[AnalyticsConstants.EventDataKeys.TRACK_INTERNAL] as? Bool ?? false
            ret[getActionKey(isInternalAction: isInternal)] = actionName
        }

        // Todo :- Is TimeSinceLaunch" param is required? If so, calculate by listenining to lifecycle shared state update

        if getPrivacyStatus(event: event) == .unknown {
            ret[AnalyticsConstants.AnalyticsRequestKeys.PRIVACY_MODE] = "unknown"
        }

        if isAssuranceSessionActive(event: event) {
            ret[AnalyticsConstants.ContextDataKeys.EVENT_IDENTIFIER_KEY] = event.id.uuidString
        }

        return ret
    }

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

        let xdm = [AnalyticsConstants.XDMDataKeys.EVENTTYPE: AnalyticsConstants.ANALYTICS_XDM_EVENTTYPE]
        let edgeEventData: [String: Any] = [AnalyticsConstants.XDMDataKeys.LEGACY: [AnalyticsConstants.XDMDataKeys.ANALYTICS: legacyAnalyticsData]]

        let experienceEvent = ExperienceEvent(xdm: xdm, data: edgeEventData)
        Edge.sendEvent(experienceEvent: experienceEvent, responseHandler: nil)
    }

    private func getActionKey(isInternalAction: Bool) -> String {
        return isInternalAction ? AnalyticsConstants.ContextDataKeys.INTERNAL_ACTION_KEY :
            AnalyticsConstants.ContextDataKeys.ACTION_KEY
    }

    private func getActionPrefix(isInternalAction: Bool) -> String {
        return isInternalAction ? AnalyticsConstants.INTERNAL_ACTION_PREFIX : AnalyticsConstants.ACTION_PREFIX
    }

    private func getPrivacyStatus(event: Event) -> PrivacyStatus {
        guard let configSharedState = getSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: event)?.value else { return .unknown
        }

        let privacyStatusStr = configSharedState[AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? String ?? ""
        return PrivacyStatus(rawValue: privacyStatusStr) ?? PrivacyStatus.unknown
    }

    private func isAssuranceSessionActive(event: Event) -> Bool {
        guard let assuranceSharedState = getSharedState(extensionName: AnalyticsConstants.Assurance.SHARED_STATE_NAME, event: event)?.value else {
            return false
        }

        let sessionId = assuranceSharedState[AnalyticsConstants.Assurance.SESSION_ID] as? String ?? ""
        return !sessionId.isEmpty
    }
}

