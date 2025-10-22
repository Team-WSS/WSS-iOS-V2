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
}
