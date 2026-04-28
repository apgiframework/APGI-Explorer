import XCTest

@testable import APGI_Explorer

@MainActor
final class SecurityManagerTests: XCTestCase {
  // swiftlint:disable:next implicitly_unwrapped_optional
  private var securityManager: SecurityManager!

  override func setUp() async throws {
    try await super.setUp()
    self.securityManager = SecurityManager.shared
    try await self.securityManager.clearAllSecureData()
  }

  override func tearDown() async throws {
    try await self.securityManager.clearAllSecureData()
    try await super.tearDown()
  }

  func testStoreAndRetrieveSessionToken() async throws {
    let testToken = "test_session_token_123"

    try await securityManager.storeSessionToken(testToken)
    let retrievedToken = try await securityManager.retrieveSessionToken()

    XCTAssertEqual(retrievedToken, testToken)
  }

  func testStoreAndRetrieveAnalyticsConsent() async throws {
    let consent = true

    try await securityManager.storeAnalyticsConsent(consent)
    let retrievedConsent = try await securityManager.retrieveAnalyticsConsent()

    XCTAssertEqual(retrievedConsent, consent)
  }

  func testStoreAndRetrieveLastBackupDate() async throws {
    let testDate = Date()

    try await securityManager.storeLastBackupDate(testDate)
    let retrievedDate = try await securityManager.retrieveLastBackupDate()

    XCTAssertEqual(retrievedDate, testDate)
  }

  func testStoreAndRetrieveAppSettings() async throws {
    let testSettings: [String: Any] = [
      "theme": "dark",
      "notifications": true,
      "autoBackup": false,
      "maxProfiles": 10
    ]

    try await securityManager.storeAppSettings(testSettings)
    let retrievedSettings = try await securityManager.retrieveAppSettings()

    XCTAssertNotNil(retrievedSettings)
    XCTAssertEqual(retrievedSettings?["theme"] as? String, "dark")
    XCTAssertEqual(retrievedSettings?["notifications"] as? Bool, true)
    XCTAssertEqual(retrievedSettings?["autoBackup"] as? Bool, false)
    XCTAssertEqual(retrievedSettings?["maxProfiles"] as? Int, 10)
  }

  func testDataIntegrityValidation() async throws {
    let result = try await self.securityManager.validateDataIntegrity()
    XCTAssertTrue(result.isValid)
    XCTAssertTrue(result.issues.isEmpty)

    try await self.securityManager.storeSessionToken("test_token")
    let resultWithData = try await self.securityManager.validateDataIntegrity()
    XCTAssertTrue(resultWithData.isValid)
  }

  func testExportAndImportSecureData() async throws {
    let testToken = "export_test_token"
    let consent = true
    let testDate = Date()
    let testSettings: [String: Any] = ["theme": "light"]

    try await securityManager.storeSessionToken(testToken)
    try await self.securityManager.storeAnalyticsConsent(consent)
    try await self.securityManager.storeLastBackupDate(testDate)
    try await self.securityManager.storeAppSettings(testSettings)

    let exportedData = try await securityManager.exportSecureData()
    XCTAssertNotNil(exportedData["sessionToken"])
    XCTAssertNotNil(exportedData["analyticsConsent"])
    XCTAssertNotNil(exportedData["lastBackupDate"])
    XCTAssertNotNil(exportedData["appSettings"])

    try await self.securityManager.clearAllSecureData()

    try await self.securityManager.importSecureData(exportedData)

    let retrievedToken = try await securityManager.retrieveSessionToken()
    let retrievedConsent = try await securityManager.retrieveAnalyticsConsent()
    let retrievedDate = try await securityManager.retrieveLastBackupDate()
    let retrievedSettings = try await securityManager.retrieveAppSettings()

    XCTAssertEqual(retrievedToken, testToken)
    XCTAssertEqual(retrievedConsent, consent)
    XCTAssertEqual(retrievedDate, testDate)
    XCTAssertEqual(retrievedSettings?["theme"] as? String, "light")
  }

  func testClearAllSecureData() async throws {
    try await self.securityManager.storeSessionToken("test_token")
    try await self.securityManager.storeAnalyticsConsent(true)
    try await self.securityManager.storeLastBackupDate(Date())
    try await self.securityManager.storeAppSettings(["test": "value"])

    try await self.securityManager.clearAllSecureData()

    let retrievedToken = try? await self.securityManager.retrieveSessionToken()
    let retrievedConsent = try? await self.securityManager.retrieveAnalyticsConsent()
    let retrievedDate = try? await self.securityManager.retrieveLastBackupDate()
    let retrievedSettings = try? await self.securityManager.retrieveAppSettings()

    XCTAssertNil(retrievedToken)
    XCTAssertNil(retrievedConsent)
    XCTAssertNil(retrievedDate)
    XCTAssertNil(retrievedSettings)
  }

  func testPerformanceOfSecurityOperations() {
    measure {
      Task {
        do {
          for i in 0..<50 {
            try await self.securityManager.storeSessionToken("token_\(i)")
            _ = try await self.securityManager.retrieveSessionToken()
          }
          try await self.securityManager.clearAllSecureData()
        } catch {
          XCTFail("Performance test failed: \(error)")
        }
      }
    }
  }
}
