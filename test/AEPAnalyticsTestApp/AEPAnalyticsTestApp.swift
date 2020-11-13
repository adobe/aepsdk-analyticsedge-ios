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

import SwiftUI
import AEPAnalytics
import AEPCore
import AEPEdge
import AEPIdentity
import AEPAssurance
import ACPCore

@main
struct AEPAnalyticsTestApp: App {
    // TODO: Set up the Environment File ID from your Launch property for the preferred environment
    private let LAUNCH_ENVIRONMENT_FILE_ID = ""

    init() {
        MobileCore.setLogLevel(.trace)
        MobileCore.configureWith(appId: LAUNCH_ENVIRONMENT_FILE_ID)
        MobileCore.registerExtensions([Edge.self, Identity.self, Analytics.self])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
