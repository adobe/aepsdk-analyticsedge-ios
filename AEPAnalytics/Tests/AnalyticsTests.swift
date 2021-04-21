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

import XCTest
import AEPServices
@testable import AEPCore
@testable import AEPAnalytics

class AnalyticsAPITests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var analytics: Analytics!
    var dataStore: NamedCollectionDataStore!

    private var userDefaults: UserDefaults {
        if let appGroup = ServiceProvider.shared.namedKeyValueService.getAppGroup(), !appGroup.isEmpty {
            return UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
        }

        return UserDefaults.standard
    }

    private func resetExtension() {
        mockRuntime = TestableExtensionRuntime()
        analytics = Analytics(runtime: mockRuntime)
        analytics.onRegistered()
    }

    override func setUp() {
        UserDefaults.clear()

        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        dataStore = NamedCollectionDataStore(name: AnalyticsConstants.DATASTORE_NAME)

        resetExtension()
    }

    func testReadyForEvent() {
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: nil)
        XCTAssertEqual(analytics.readyForEvent(trackStateEvent), false)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.optedIn.rawValue], .set)
        )
        XCTAssertEqual(analytics.readyForEvent(trackStateEvent), true)
    }

    func testTrack_emptyData() {
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: nil)
        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.optedIn.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 0)
    }

    func testTrackState() {
        // test
        let trackData: [String: Any] = [
            CoreConstants.Keys.STATE : "state",
            CoreConstants.Keys.CONTEXT_DATA : [
                "key1": "value1",
                "key2": "value2"
            ]
        ]
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.optedIn.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(edgeEvent.type, EventType.edge)
        XCTAssertEqual(edgeEvent.source, EventSource.requestContent)

        let expectedData: [String:Any] = [
            AnalyticsConstants.XDMDataKeys.XDM: [
                AnalyticsConstants.XDMDataKeys.EVENTTYPE: AnalyticsConstants.ANALYTICS_XDM_EVENTTYPE,
            ],            
            AnalyticsConstants.XDMDataKeys.DATA : [
                AnalyticsConstants.XDMDataKeys.LEGACY: [
                    AnalyticsConstants.XDMDataKeys.ANALYTICS: [
                        "ndh": 1,
                        AnalyticsConstants.AnalyticsRequestKeys.PAGE_NAME : "state",
                        AnalyticsConstants.AnalyticsRequestKeys.CHARSET : AnalyticsConstants.CHARSET,
                        AnalyticsConstants.AnalyticsRequestKeys.FORMATTED_TIMESTAMP : TimeZone.current.getOffsetFromGmtInMinutes(),
                        AnalyticsConstants.AnalyticsRequestKeys.STRING_TIMESTAMP : String(trackStateEvent.timestamp.getUnixTimeInSeconds()),
                        AnalyticsConstants.AnalyticsRequestKeys.CUSTOMER_PERSPECTIVE : AnalyticsConstants.APP_STATE_FOREGROUND,
                        AnalyticsConstants.AnalyticsRequestKeys.CONTEXT_DATA : [
                            "key1" : "value1",
                            "key2" : "value2"
                        ]
                    ]
                ]
            ]
        ]

        XCTAssertTrue(NSDictionary(dictionary: edgeEvent.data!).isEqual(to: expectedData))
    }

    func testTrackAction() {
        let trackData: [String: Any] = [
            CoreConstants.Keys.ACTION : "action",
            CoreConstants.Keys.CONTEXT_DATA : [
                "key1": "value1",
                "key2": "value2"
            ]
        ]
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.optedIn.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(edgeEvent.type, EventType.edge)
        XCTAssertEqual(edgeEvent.source, EventSource.requestContent)

        let expectedData: [String:Any] = [
            AnalyticsConstants.XDMDataKeys.XDM: [
                AnalyticsConstants.XDMDataKeys.EVENTTYPE: AnalyticsConstants.ANALYTICS_XDM_EVENTTYPE,
            ],
            AnalyticsConstants.XDMDataKeys.DATA : [
                AnalyticsConstants.XDMDataKeys.LEGACY: [
                    AnalyticsConstants.XDMDataKeys.ANALYTICS: [
                        "ndh": 1,

                        AnalyticsConstants.AnalyticsRequestKeys.CHARSET : AnalyticsConstants.CHARSET,
                        AnalyticsConstants.AnalyticsRequestKeys.FORMATTED_TIMESTAMP : TimeZone.current.getOffsetFromGmtInMinutes(),
                        AnalyticsConstants.AnalyticsRequestKeys.STRING_TIMESTAMP : String(trackStateEvent.timestamp.getUnixTimeInSeconds()),
                        AnalyticsConstants.AnalyticsRequestKeys.CUSTOMER_PERSPECTIVE : AnalyticsConstants.APP_STATE_FOREGROUND,
                        AnalyticsConstants.AnalyticsRequestKeys.IGNORE_PAGE_NAME :  AnalyticsConstants.IGNORE_PAGE_NAME_VALUE,
                        AnalyticsConstants.AnalyticsRequestKeys.PAGE_NAME : AnalyticsHelper.getApplicationIdentifier(),
                        AnalyticsConstants.AnalyticsRequestKeys.ACTION_NAME:   "AMACTION:action",
                        AnalyticsConstants.AnalyticsRequestKeys.CONTEXT_DATA : [
                            "key1" : "value1",
                            "key2" : "value2",
                            AnalyticsConstants.ContextDataKeys.ACTION_KEY : "action"
                        ]
                    ]
                ]
            ]
        ]

        XCTAssertTrue(NSDictionary(dictionary: edgeEvent.data!).isEqual(to: expectedData))
    }

    func testTrackInternalAction() {
        let trackData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRACK_INTERNAL: true,
            CoreConstants.Keys.ACTION : "action",
            CoreConstants.Keys.CONTEXT_DATA : [
                "key1": "value1",
                "key2": "value2"
            ]
        ]
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.optedIn.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(edgeEvent.type, EventType.edge)
        XCTAssertEqual(edgeEvent.source, EventSource.requestContent)

        let expectedData: [String:Any] = [
            AnalyticsConstants.XDMDataKeys.XDM: [
                AnalyticsConstants.XDMDataKeys.EVENTTYPE: AnalyticsConstants.ANALYTICS_XDM_EVENTTYPE,
            ],
            AnalyticsConstants.XDMDataKeys.DATA : [
                AnalyticsConstants.XDMDataKeys.LEGACY: [
                    AnalyticsConstants.XDMDataKeys.ANALYTICS: [
                        "ndh": 1,
                        AnalyticsConstants.AnalyticsRequestKeys.CHARSET : AnalyticsConstants.CHARSET,
                        AnalyticsConstants.AnalyticsRequestKeys.FORMATTED_TIMESTAMP : TimeZone.current.getOffsetFromGmtInMinutes(),
                        AnalyticsConstants.AnalyticsRequestKeys.STRING_TIMESTAMP : String(trackStateEvent.timestamp.getUnixTimeInSeconds()),
                        AnalyticsConstants.AnalyticsRequestKeys.CUSTOMER_PERSPECTIVE : AnalyticsConstants.APP_STATE_FOREGROUND,
                        AnalyticsConstants.AnalyticsRequestKeys.IGNORE_PAGE_NAME :  AnalyticsConstants.IGNORE_PAGE_NAME_VALUE,
                        AnalyticsConstants.AnalyticsRequestKeys.PAGE_NAME : AnalyticsHelper.getApplicationIdentifier(),
                        AnalyticsConstants.AnalyticsRequestKeys.ACTION_NAME:   "ADBINTERNAL:action",
                        AnalyticsConstants.AnalyticsRequestKeys.CONTEXT_DATA : [
                            "key1" : "value1",
                            "key2" : "value2",
                            AnalyticsConstants.ContextDataKeys.INTERNAL_ACTION_KEY : "action"
                        ]
                    ]
                ]
            ]
        ]

        XCTAssertTrue(NSDictionary(dictionary: edgeEvent.data!).isEqual(to: expectedData))
    }

    func testTrack_strippedContextData() {
        let trackData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRACK_INTERNAL: true,
            CoreConstants.Keys.ACTION : "action",
            CoreConstants.Keys.CONTEXT_DATA : [
                "&&product": "value",
                "key1": "value1",
                "key2": "value2",
            ]
        ]

        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.optedIn.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: trackStateEvent)


        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        guard let eventDataDict = mockRuntime.dispatchedEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict:eventDataDict)
        XCTAssertEqual("value", eventData["data._legacy.analytics.product"] as? String)
        // Other keys are in context data
        XCTAssertEqual("value1", eventData["data._legacy.analytics.c.key1"] as? String)
        XCTAssertEqual("value2", eventData["data._legacy.analytics.c.key2"] as? String)
    }

    func testPrivacyOptOut_dropsRequest() {
        let trackData: [String: Any] = [
            CoreConstants.Keys.ACTION : "action",
            CoreConstants.Keys.CONTEXT_DATA : [:]
        ]
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.optedOut.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 0)
    }

    func testPrivacyOptUnknown_privacyModeParamPresent() {
        let trackData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRACK_INTERNAL: true,
            CoreConstants.Keys.ACTION : "action",
            CoreConstants.Keys.CONTEXT_DATA : [:]
        ]
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.unknown.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        guard let eventDataDict = mockRuntime.dispatchedEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict:eventDataDict)
        XCTAssertEqual("unknown", eventData["data._legacy.analytics.c.a.privacy.mode"] as? String)
    }

    func testAppendRequestEventUUID_activeAssuranceSession() {
        let trackData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRACK_INTERNAL: true,
            CoreConstants.Keys.ACTION : "action",
            CoreConstants.Keys.CONTEXT_DATA : [:]
        ]
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.unknown.rawValue], .set)
        )
        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Assurance.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Assurance.SESSION_ID : "assuranceactive"], .set)
        )

        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        guard let eventDataDict = mockRuntime.dispatchedEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict:eventDataDict)
        XCTAssertEqual(trackStateEvent.id.uuidString, eventData["data._legacy.analytics.c." + AnalyticsConstants.ContextDataKeys.EVENT_IDENTIFIER_KEY] as? String)
    }

    func testRuleEngineResponse_invalidData() {
        let ruleEngineEvent = Event(name: "Rule event", type: EventType.rulesEngine, source: EventSource.responseContent, data: nil)
        mockRuntime.simulateComingEvent(event: ruleEngineEvent)
        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 0)
    }

    func testRuleEngineResponse_missingConsequence() {
        let ruleEngineEvent = Event(name: "Rule event", type: EventType.rulesEngine, source: EventSource.responseContent, data: [:])
        mockRuntime.simulateComingEvent(event: ruleEngineEvent)
        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 0)
    }

    func testRuleEngineResponse_incorrectConsequenceType() {
        let eventData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRIGGERED_CONSEQUENCE: [
                AnalyticsConstants.EventDataKeys.ID: "id",
                AnalyticsConstants.EventDataKeys.TYPE: "type",
                AnalyticsConstants.EventDataKeys.DETAIL : ["action": "action"]
            ]
        ]
        let ruleEngineEvent = Event(name: "Rule event", type: EventType.rulesEngine, source: EventSource.responseContent, data: eventData)
        mockRuntime.simulateComingEvent(event: ruleEngineEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 0)
    }

    func testRuleEngineResponse_missingConsequenceID() {
        let eventData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRIGGERED_CONSEQUENCE: [
                AnalyticsConstants.EventDataKeys.TYPE: "an",
                AnalyticsConstants.EventDataKeys.DETAIL : ["action": "action"]
            ]
        ]
        let ruleEngineEvent = Event(name: "Rule event", type: EventType.rulesEngine, source: EventSource.responseContent, data: eventData)
        mockRuntime.simulateComingEvent(event: ruleEngineEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 0)
    }

    func testRuleEngineResponse_trackConsequenceMissingDetail() {
        let eventData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRIGGERED_CONSEQUENCE: [
                AnalyticsConstants.EventDataKeys.ID: "id",
                AnalyticsConstants.EventDataKeys.TYPE: "an",
            ]
        ]
        let ruleEngineEvent = Event(name: "Rule event", type: EventType.rulesEngine, source: EventSource.responseContent, data: eventData)
        mockRuntime.simulateComingEvent(event: ruleEngineEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 0)
    }

    func testRuleEngineResponse_trackConsequence() {
        let eventData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRIGGERED_CONSEQUENCE: [
                AnalyticsConstants.EventDataKeys.ID: "id",
                AnalyticsConstants.EventDataKeys.TYPE: "an",
                AnalyticsConstants.EventDataKeys.DETAIL : [
                    "contextdata": ["key1" : "value1" , "key2" : "value2"]
                ]
            ]
        ]
        let ruleEngineEvent = Event(name: "Rule event", type: EventType.rulesEngine, source: EventSource.responseContent, data: eventData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: ruleEngineEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.optedIn.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: ruleEngineEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(edgeEvent.type, EventType.edge)
        XCTAssertEqual(edgeEvent.source, EventSource.requestContent)

        let expectedData: [String:Any] = [
            AnalyticsConstants.XDMDataKeys.XDM: [
                AnalyticsConstants.XDMDataKeys.EVENTTYPE: AnalyticsConstants.ANALYTICS_XDM_EVENTTYPE,
            ],
            AnalyticsConstants.XDMDataKeys.DATA : [
                AnalyticsConstants.XDMDataKeys.LEGACY: [
                    AnalyticsConstants.XDMDataKeys.ANALYTICS: [
                        "ndh": 1,
                        AnalyticsConstants.AnalyticsRequestKeys.CHARSET : AnalyticsConstants.CHARSET,
                        AnalyticsConstants.AnalyticsRequestKeys.FORMATTED_TIMESTAMP : TimeZone.current.getOffsetFromGmtInMinutes(),
                        AnalyticsConstants.AnalyticsRequestKeys.STRING_TIMESTAMP : String(ruleEngineEvent.timestamp.getUnixTimeInSeconds()),
                        AnalyticsConstants.AnalyticsRequestKeys.CUSTOMER_PERSPECTIVE : AnalyticsConstants.APP_STATE_FOREGROUND,
                        AnalyticsConstants.AnalyticsRequestKeys.PAGE_NAME : AnalyticsHelper.getApplicationIdentifier(),
                        AnalyticsConstants.AnalyticsRequestKeys.CONTEXT_DATA : [
                            "key1" : "value1",
                            "key2" : "value2",                            
                        ]
                    ]
                ]
            ]
        ]

        XCTAssertTrue(NSDictionary(dictionary: edgeEvent.data!).isEqual(to: expectedData))
    }

    func testIds_areSentIfPresentInDatastore() {
        dataStore.set(key: AnalyticsConstants.DataStoreKeys.VID, value: "testvid")
        dataStore.set(key: AnalyticsConstants.DataStoreKeys.AID, value: "testaid")

        let trackData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRACK_INTERNAL: true,
            CoreConstants.Keys.ACTION : "action",
            CoreConstants.Keys.CONTEXT_DATA : [:]
        ]
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.unknown.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        guard let eventDataDict = mockRuntime.dispatchedEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict:eventDataDict)
        XCTAssertEqual("testaid", eventData["data._legacy.analytics.aid"] as? String)
        XCTAssertEqual("testvid", eventData["data._legacy.analytics.vid"] as? String)
    }

    func testIds_areResetAfterStatusChange() {
        dataStore.set(key: AnalyticsConstants.DataStoreKeys.VID, value: "testvid")
        dataStore.set(key: AnalyticsConstants.DataStoreKeys.AID, value: "testaid")

        let optOutEvent = Event(name: "Config change event", type: EventType.configuration, source: EventSource.responseContent, data: [AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.optedOut.rawValue])
        mockRuntime.simulateComingEvent(event: optOutEvent)

        let optInEvent = Event(name: "Config change event", type: EventType.configuration, source: EventSource.responseContent, data: [AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.optedIn.rawValue])        
        mockRuntime.simulateComingEvent(event: optInEvent)

        let trackData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRACK_INTERNAL: true,
            CoreConstants.Keys.ACTION : "action",
            CoreConstants.Keys.CONTEXT_DATA : [:]
        ]
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)
        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        guard let eventDataDict = mockRuntime.dispatchedEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict:eventDataDict)
        XCTAssertFalse(eventData.keys.contains("data._legacy.analytics.aid"))
        XCTAssertFalse(eventData.keys.contains("data._legacy.analytics.vid"))        
    }

    func testIds_areMigratedIfPresentInV4Datastore() {
        // Force data migration again by deleting this key.
        dataStore.remove(key: AnalyticsConstants.DataStoreKeys.DATA_MIGRATED)
        // Set v4 datastore with aid, vid
        userDefaults.set("testaid", forKey: AnalyticsConstants.V4Migration.AID)
        userDefaults.set("testvid", forKey: AnalyticsConstants.V4Migration.VID)
        // Analytics extension migrates the ids during setup.
        resetExtension()

        let trackData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRACK_INTERNAL: true,
            CoreConstants.Keys.ACTION : "action",
            CoreConstants.Keys.CONTEXT_DATA : [:]
        ]
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.unknown.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        guard let eventDataDict = mockRuntime.dispatchedEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict:eventDataDict)
        XCTAssertEqual("testaid", eventData["data._legacy.analytics.aid"] as? String)
        XCTAssertEqual("testvid", eventData["data._legacy.analytics.vid"] as? String)
    }

    func testIds_areMigratedIfPresentInV5Datastore() {
        // Force data migration again by deleting this key.
        dataStore.remove(key: AnalyticsConstants.DataStoreKeys.DATA_MIGRATED)
        // Set v4 datastore with aid, vid
        userDefaults.set("testaid", forKey: AnalyticsConstants.V5Migration.AID)
        userDefaults.set("testvid", forKey: AnalyticsConstants.V5Migration.VID)
        // Analytics extension migrates the ids during setup.
        resetExtension()

        let trackData: [String: Any] = [
            AnalyticsConstants.EventDataKeys.TRACK_INTERNAL: true,
            CoreConstants.Keys.ACTION : "action",
            CoreConstants.Keys.CONTEXT_DATA : [:]
        ]
        let trackStateEvent = Event(name: "Generic track event", type: EventType.genericTrack, source: EventSource.requestContent, data: trackData)

        mockRuntime.simulateSharedState(extensionName: AnalyticsConstants.Configuration.SHARED_STATE_NAME, event: trackStateEvent, data:
            ([AnalyticsConstants.Configuration.GLOBAL_CONFIG_PRIVACY : PrivacyStatus.unknown.rawValue], .set)
        )
        mockRuntime.simulateComingEvent(event: trackStateEvent)

        XCTAssertEqual(mockRuntime.dispatchedEvents.count, 1)
        guard let eventDataDict = mockRuntime.dispatchedEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict:eventDataDict)
        XCTAssertEqual("testaid", eventData["data._legacy.analytics.aid"] as? String)
        XCTAssertEqual("testvid", eventData["data._legacy.analytics.vid"] as? String)
    }
}
