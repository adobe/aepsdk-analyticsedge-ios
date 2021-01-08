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

import UIKit
import AEPServices

class AnalyticsHelper {
    /// The app’s current state, or that of its most active scene.
    /// - Returns: The app's current state
    static func getApplicationState() -> UIApplication.State? {
        var ret: UIApplication.State?
        DispatchQueue.main.sync {
            ret = UIApplication.shared.applicationState
        }
        return ret
    }
}

extension TimeZone {
    /// Creates timestamp string, with all fields set as 0 except timezone offset.
    /// All fields other than timezone offset are set to 0 because backend only process timezone offset from this value.
    /// - Returns: `String` Time stamp with all fields except timezone offset set to 0.
    func getOffsetFromGmtInMinutes() -> String {

        let gmtOffsetInMinutes = (secondsFromGMT() / 60) * -1
        return "00/00/0000 00:00:00 0 \(gmtOffsetInMinutes)"
    }
}
