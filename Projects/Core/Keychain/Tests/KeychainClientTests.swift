//
//  KeychainClientTests.swift
//  Manifests
//
//  Created by Seoyeon Choi on 11/18/25.
//

import XCTest
@testable import Keychain

final class KeychainTests: XCTestCase {
    var keychain: KeychainClient!

    override func setUp() {
        super.setUp()
        keychain = KeychainClient(service: "TestKeychainService")
    }

    override func tearDown() {
        try? keychain.delete(forKey: "testKey")
        try? keychain.delete(forKey: "duplicateTest")
        try? keychain.delete(forKey: "missingKey")
        try? keychain.delete(forKey: "saveTest")
        keychain = nil
        super.tearDown()
    }

    func testCreateReadUpdateDelete() throws {
        let key = "testKey"
        let value = "Hello Keychain"

        // Create
        try keychain.create(value: value, forKey: key)
        let read1 = try keychain.value(forKey: key)
        XCTAssertEqual(read1, value)

        // Update
        try keychain.update(value: "Updated", forKey: key)
        let read2 = try keychain.value(forKey: key)
        XCTAssertEqual(read2, "Updated")

        // Delete
        try keychain.delete(forKey: key)
        let read3 = try keychain.value(forKey: key)
        XCTAssertNil(read3)
    }

    func testDuplicateCreateThrowsError() throws {
        let key = "duplicateTest"
        try keychain.create(value: "One", forKey: key)

        XCTAssertThrowsError(try keychain.create(value: "Two", forKey: key)) { error in
            guard case KeychainError.duplicateItem = error else {
                return XCTFail("Expected KeychainError.duplicateItem")
            }
        }
    }

    func testUpdateMissingItemThrowsItemNotFound() {
        XCTAssertThrowsError(try keychain.update(value: "Updated", forKey: "missingKey")) { error in
            guard case KeychainError.itemNotFound = error else {
                return XCTFail("Expected KeychainError.itemNotFound")
            }
        }
    }

    func testSaveCreatesAndUpdatesItem() throws {
        let key = "saveTest"

        try keychain.save(value: "One", forKey: key)
        XCTAssertEqual(try keychain.value(forKey: key), "One")

        try keychain.save(value: "Two", forKey: key)
        XCTAssertEqual(try keychain.value(forKey: key), "Two")
    }
}
