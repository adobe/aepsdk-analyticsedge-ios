/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License")
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

enum AnalyticsConstants {
    static let EXTENSION_NAME = "com.adobe.module.analytics"
    static let FRIENDLY_NAME = "AnalyticsEdge"
    static let EXTENSION_VERSION = "1.0.0-beta.3"
    static let DATASTORE_NAME = EXTENSION_NAME

    static let APP_STATE_FOREGROUND = "foreground"
    static let APP_STATE_BACKGROUND = "background"

    static let ACTION_PREFIX = "AMACTION:"
    static let INTERNAL_ACTION_PREFIX = "ADBINTERNAL:"
    static let VAR_ESCAPE_PREFIX = "&&"
    static let IGNORE_PAGE_NAME_VALUE = "lnk_o"
    static let CHARSET = "UTF-8"

    enum Assurance {
        static let SHARED_STATE_NAME =  "com.adobe.assurance"
        static let SESSION_ID = "sessionid"
    }

    enum Configuration {
        static let SHARED_STATE_NAME = "com.adobe.module.configuration"
        static let GLOBAL_CONFIG_PRIVACY = "global.privacy"
    }

    enum AnalyticsRequestKeys {
        static let VISITOR_ID = "vid"
        static let CHARSET = "ce"
        static let FORMATTED_TIMESTAMP = "t"
        static let STRING_TIMESTAMP = "ts"
        static let CONTEXT_DATA = "c"
        static let PAGE_NAME = "pageName"
        static let IGNORE_PAGE_NAME = "pe"
        static let CUSTOMER_PERSPECTIVE = "cp"
        static let ACTION_NAME = "pev2"
        static let ANALYTICS_ID = "aid"
        static let PRIVACY_MODE = "a.privacy.mode"

    }

    enum EventDataKeys {
        static let FORCE_KICK_HITS  = "forcekick"
        static let CLEAR_HITS_QUEUE = "clearhitsqueue"
        static let ANALYTICS_ID     = "aid"
        static let GET_QUEUE_SIZE   = "getqueuesize"
        static let QUEUE_SIZE       = "queuesize"
        static let TRACK_INTERNAL   = "trackinternal"
        static let TRACK_ACTION     = "action"
        static let TRACK_STATE      = "state"
        static let CONTEXT_DATA = "contextdata"
        static let ANALYTICS_SERVER_RESPONSE = "analyticsserverresponse"
        static let VISITOR_IDENTIFIER = "vid"
        static let HEADERS_RESPONSE = "headers"
        static let ETAG_HEADER = "ETag"
        static let SERVER_HEADER = "Server"
        static let CONTENT_TYPE_HEADER = "Content-Type"
        static let HIT_HOST = "hitHost"
        static let HIT_URL = "hitUrl"

        static let TRIGGERED_CONSEQUENCE = "triggeredconsequence"
        static let ID = "id"
        static let DETAIL = "detail"
        static let TYPE = "type"
    }

    enum ConsequenceTypes {
        static let TRACK = "an"
    }

    enum ContextDataKeys {
        static let ACTION_KEY = "a.action"
        static let INTERNAL_ACTION_KEY = "a.internalaction"
        static let EVENT_IDENTIFIER_KEY = "a.DebugEventIdentifier"
    }

    enum XDMDataKeys {
        static let LEGACY = "_legacy"
        static let ANALYTICS = "analytics"
        static let EVENTTYPE = "eventType"
        static let CONTEXT_DATA = "c"
        static let DATA = "data"
        static let XDM = "xdm"
    }

    static let ANALYTICS_XDM_EVENTTYPE = "legacy.analytics"
    static let ANALYTICS_XDM_EVENTNAME = "Analytics Edge Request"

    enum DataStoreKeys {
        static let AID = "aid"
        static let IGNORE_AID = "ignoreaid"
        static let VID = "vid"
        static let DATA_MIGRATED = "data.migrated"
    }

    enum V4Migration {
        // Migrate
        static let AID = "ADOBEMOBILE_STOREDDEFAULTS_AID"
        static let IGNORE_AID = "ADOBEMOBILE_STOREDDEFAULTS_IGNOREAID"
        static let VID = "AOMS_AppMeasurement_StoredDefaults_VisitorID"
        // Delete
        static let AID_SYNCED = "ADOBEMOBILE_STOREDDEFAULTS_AIDSYNCED"
        static let LAST_TIMESTAMP = "ADBMobileLastTimestamp"
        static let CURRENT_HIT_ID  = "ANALYTICS_WORKER_CURRENT_ID"
        static let CURRENT_HIT_STAMP = "ANALYTICS_WORKER_CURRENT_STAMP"
    }

    enum V5Migration {
        // Migrate
        static let AID  = "Adobe.AnalyticsDataStorage.ADOBEMOBILE_STOREDDEFAULTS_AID"
        static let IGNORE_AID = "Adobe.AnalyticsDataStorage.ADOBEMOBILE_STOREDDEFAULTS_IGNOREAID"
        static let VID = "Adobe.AnalyticsDataStorage.ADOBEMOBILE_STOREDDEFAULTS_VISITOR_IDENTIFIER"
        static let IDENTITY_VID = "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITOR_ID" // In some cases VID from v4 was migrated to identity datastore.

        // Delete
        static let MOST_RECENT_HIT_TIMESTAMP = "Adobe.AnalyticsDataStorage.mostRecentHitTimestampSeconds"
    }

}
