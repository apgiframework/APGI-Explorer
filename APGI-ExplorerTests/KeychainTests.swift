import XCTest

@testable import APGI_Explorer

final class KeychainTests: XCTestCase {
  private var keychain: KeychainManager?
  private let testKey = "com.test.keychain.test"

  override func setUpWithError() throws {
    self.keychain = KeychainManager.shared
    try? self.keychain?.delete(forKey: self.testKey)
  }

  override func tearDownWithError() throws {
    try? self.keychain?.delete(forKey: self.testKey)
  }

  func testStoreAndRetrieveData() throws {
    let testData = Data("test_keychain_data".utf8)

    try self.keychain?.store(testData, forKey: self.testKey)
    XCTAssertTrue(try XCTUnwrap(self.keychain?.contains(forKey: self.testKey)))

    let retrievedData = try XCTUnwrap(try keychain?.retrieve(forKey: self.testKey))
    XCTAssertEqual(retrievedData, testData)
  }

  func testStoreAndRetrieveString() throws {
    let testString = "test_string_value"

    try keychain?.storeString(testString, forKey: self.testKey)
    let retrievedString = try XCTUnwrap(try keychain?.retrieveString(forKey: self.testKey))
    XCTAssertEqual(retrievedString, testString)
  }

  func testStoreAndRetrieveCodable() throws {
    struct TestStruct: Codable, Equatable {
      let id: UUID
      let name: String
      let value: Double
    }

    let testObject = TestStruct(id: UUID(), name: "Test", value: 42.0)

    try keychain?.storeCodable(testObject, forKey: self.testKey)
    let retrievedObject = try XCTUnwrap(
      try keychain?.retrieveCodable(TestStruct.self, forKey: self.testKey))
    XCTAssertEqual(retrievedObject, testObject)
  }

  func testUpdateExistingItem() throws {
    let initialData = Data("initial_data".utf8)
    let updatedData = Data("updated_data".utf8)

    try self.keychain?.store(initialData, forKey: self.testKey)
    try self.keychain?.update(updatedData, forKey: self.testKey)

    let retrievedData = try XCTUnwrap(try keychain?.retrieve(forKey: self.testKey))
    XCTAssertEqual(retrievedData, updatedData)
  }

  func testDeleteNonExistentItem() throws {
    XCTAssertThrowsError(try XCTUnwrap(try self.keychain?.retrieve(forKey: "non_existent_key"))) { error in
      XCTAssertTrue(error is KeychainManager.KeychainError)
      if case KeychainManager.KeychainError.itemNotFound = error {
        XCTAssertTrue(true)
      } else {
        XCTFail("Expected itemNotFound error")
      }
    }
  }

  func testContainsFunction() throws {
    XCTAssertFalse(try XCTUnwrap(self.keychain?.contains(forKey: self.testKey)))

    try self.keychain?.storeString("test", forKey: self.testKey)
    XCTAssertTrue(try XCTUnwrap(self.keychain?.contains(forKey: self.testKey)))

    try self.keychain?.delete(forKey: self.testKey)
    XCTAssertFalse(try XCTUnwrap(self.keychain?.contains(forKey: self.testKey)))
  }

  func testPerformanceOfKeychainOperations() {
    let testData = Data("performance_test_data".utf8)

    measure {
      do {
        for i in 0..<10 {
          let key = "\(testKey)_\(i)"
          try keychain?.store(testData, forKey: key)
          _ = try self.keychain?.retrieve(forKey: key)
          try self.keychain?.delete(forKey: key)
        }
      } catch {
        XCTFail("Performance test failed: \(error)")
      }
    }
  }
}
