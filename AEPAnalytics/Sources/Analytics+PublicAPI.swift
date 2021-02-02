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

/// Defines the public interface for the Analytics extension
@objc public extension Analytics {
    private static let LOG_TAG = "AnalyticsEdge"

    /// Clears all hits from the tracking queue and removes them from the database.
    @objc(clearQueue)
    static func clearQueue() {
        Log.trace(label: LOG_TAG, "clearQueue - is not currently supported with Edge")
    }

    /// Retrieves the number of hits currently in the tracking queue
    /// - Parameters:
    ///  - completion: closure invoked with the queue size value
    @objc(getQueueSize:)
    static func getQueueSize(completion: @escaping (Int, AEPError) -> Void) {
        Log.trace(label: LOG_TAG, "getQueueSize - is not currently supported with Edge")
        completion(0, .unexpected)
    }

    /// Forces analytics to send all queued hits regardless of current batch options
    @objc(sendQueuedHits)
    static func sendQueuedHits() {
        Log.trace(label: LOG_TAG, "sendQueuedHits - is not currently supported with Edge")
    }

    /// Retrieves the analytics tracking identifier.
    /// - Parameters:
    ///  - completion: closure invoked with the analytics identifier value
    @objc(getTrackingIdentifier:)
    static func getTrackingIdentifier(completion: @escaping (String?, AEPError) -> Void) {
        Log.trace(label: LOG_TAG, "getTrackingIdentifier - is not currently supported with Edge")
        completion(nil, .unexpected)
    }

    /// Retrieves the visitor tracking identifier.
    /// - Parameters:
    ///  - completion: closure invoked with the visitor identifier value
    @objc(getVisitorIdentifier:)
    static func getVisitorIdentifier(completion: @escaping (String?, AEPError) -> Void) {
        Log.trace(label: LOG_TAG, "getVisitorIdentifier - is not currently supported with Edge")
        completion(nil, .unexpected)
    }

    /// Sets the visitor tracking identifier.
    /// - Parameters:
    ///  - visitorIdentifier: new value for visitor identifier
    @objc(setVisitorIdentifier:)
    static func setVisitorIdentifier(visitorIdentifier: String) {
        Log.trace(label: LOG_TAG, "setVisitorIdentifier - is not currently supported with Edge")
    }
}
