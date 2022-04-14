//
//  PGCFNotificationCenterTests.swift
//  PGCFNotificationCenterTests
//
//  Created by CHIEN-MING LEE on 2022/4/14.
//

import XCTest
@testable import PGCFNotificationCenter

class PGCFNotificationCenterTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRegistration() throws {
        let notificationCenter = PGDarwinNotificationCenter.shared
        let receipt = notificationCenter.registerNotification("PresetLicenseNeedsUpdate") {}
        var result = notificationCenter.containsReceipt(receipt.receiptId)
        XCTAssert(result == true)
        result = notificationCenter.containsNotification("PresetLicenseNeedsUpdate")
        XCTAssert(result == true)
        result = notificationCenter.containsReceipt(UUID().uuidString)
        XCTAssert(result == false)
        result = notificationCenter.containsNotification("AABB")
        XCTAssert(result == false)
    }

    func testReceiptInvalidation() throws {
        let notificationCenter = PGDarwinNotificationCenter.shared
        let receipt = notificationCenter.registerNotification("TestReceiptInvalidation") {}
        var result = notificationCenter.containsReceipt(receipt.receiptId)
        XCTAssert(result == true)
        receipt.invalidate()
        result = notificationCenter.containsReceipt(receipt.receiptId)
        XCTAssert(result == false)
        result = notificationCenter.containsNotification(receipt.notificationId)
        XCTAssert(result == false)
    }
   
    func testPostNotification() throws {
        let expectation = XCTestExpectation(description: "Expect notification happens")
        let notificationCenter = PGDarwinNotificationCenter.shared
        let receipt = notificationCenter.registerNotification("NewAction") {
            expectation.fulfill()
        }
        notificationCenter.postNotification("NewAction")
        wait(for: [expectation], timeout: 2.0)
        receipt.invalidate()
        XCTAssert(notificationCenter.containsReceipt(receipt.receiptId) == false)
        XCTAssert(notificationCenter.containsReceipt(receipt.notificationId) == false)
    }
}
