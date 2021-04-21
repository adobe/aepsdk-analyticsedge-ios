/*
 Copyright 2021 Adobe. All rights reserved.
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
import AEPCore
@testable import AEPAnalytics

class Analytics_PublicAPITests: XCTestCase {

    func testAPI_getQueueSize() {
        let expectation = XCTestExpectation(description: "Verify API returns error")
        expectation.assertForOverFulfill = true

        Analytics.getQueueSize() { (size:Int, err:Error?) in
            XCTAssertEqual(0, size)
            XCTAssertEqual(AEPError.unexpected, err as? AEPError)
            expectation.fulfill()
        }        
    }

    func testAPI_getVisitorIdentifier() {
        let expectation = XCTestExpectation(description: "Verify API returns error")
        expectation.assertForOverFulfill = true

        Analytics.getVisitorIdentifier() { (vid:String?, err:Error?) in
            XCTAssertNil(vid)
            XCTAssertEqual(AEPError.unexpected, err as? AEPError)
            expectation.fulfill()
        }
    }

    func testAPI_getTrackingIdentifier() {
        let expectation = XCTestExpectation(description: "Verify API returns error")
        expectation.assertForOverFulfill = true

        Analytics.getTrackingIdentifier() { (aid:String?, err:Error?) in
            XCTAssertNil(aid)
            XCTAssertEqual(AEPError.unexpected, err as? AEPError)
            expectation.fulfill()
        }
    }
}
