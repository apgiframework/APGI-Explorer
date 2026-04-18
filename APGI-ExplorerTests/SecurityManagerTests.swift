import XCTest

@testable import APGI_Explorer

final class SecurityManagerTests: XCTestCase {
  private var securityManager: SecurityManager?

  override func setUpWithError() throws {
    self.securityManager = SecurityManager.shared
    try self.securityManager?.clearAllSecureData()
  }

  override func tearDownWithError() throws {
    try self.securityManager?.clearAllSecureData()
  }

  func testStoreAndRetrieveSessionToken() throws {
    let testToken = "test_session_token_123"

    try securityManager?.storeSessionToken(testToken)
    let retrievedToken = try securityManager?.retrieveSessionToken()

    XCTAssertEqual(retrievedToken, testToken)
  }

  func testStoreAndRetrieveAnalyticsConsent() throws {
    let consent = true

    try securityManager?.storeAnalyticsConsent(consent)
    let retrievedConsent = try securityManager?.retrieveAnalyticsConsent()

    XCTAssertEqual(retrievedConsent, consent)
  }

  func testStoreAndRetrieveLastBackupDate() throws {
    let testDate = Date()

    try securityManager?.storeLastBackupDate(testDate)
    let retrievedDate = try securityManager?.retrieveLastBackupDate()

    XCTAssertEqual(retrievedDate, testDate)
  }

  func testStoreAndRetrieveAppSettings() throws {
    let testSettings: [String: Any] = [
      "theme": "dark",
      "notifications": true,
      "autoBackup": false,
      "maxProfiles": 10,
    ]

    try securityManager?.storeAppSettings(testSettings)
    let retrievedSettings = try securityManager?.retrieveAppSettings()

    XCTAssertNotNil(retrievedSettings)
    XCTAssertEqual(retrievedSettings?["theme"] as? String, "dark")
    XCTAssertEqual(retrievedSettings?["notifications"] as? Bool, true)
    XCTAssertEqual(retrievedSettings?["autoBackup"] as? Bool, false)
    XCTAssertEqual(retrievedSettings?["maxProfiles"] as? Int, 10)
  }

  func testDataIntegrityValidation() throws {
    let result = self.securityManager?.validateDataIntegrity()
    XCTAssertTrue(result?.isValid ?? false)
    XCTAssertTrue(result?.issues.isEmpty ?? true)

    try self.securityManager?.storeSessionToken("test_token")
    let resultWithData = self.securityManager?.validateDataIntegrity()
    XCTAssertTrue(resultWithData?.isValid ?? false)
  }

  func testExportAndImportSecureData() throws {
    let testToken = "export_test_token"
    let consent = true
    let testDate = Date()
    let testSettings: [String: Any] = ["theme": "light"]

    try securityManager?.storeSessionToken(testToken)
    try self.securityManager?.storeAnalyticsConsent(consent)
    try self.securityManager?.storeLastBackupDate(testDate)
    try self.securityManager?.storeAppSettings(testSettings)

    let exportedData = try securityManager?.exportSecureData()
    XCTAssertNotNil(exportedData["sessionToken"])
    XCTAssertNotNil(exportedData["analyticsConsent"])
    XCTAssertNotNil(exportedData["lastBackupDate"])
    XCTAssertNotNil(exportedData["appSettings"])

    try self.securityManager?.clearAllSecureData()

    try self.securityManager?.importSecureData(exportedData ?? [:])

    let retrievedToken = try securityManager?.retrieveSessionToken()
    let retrievedConsent = try securityManager?.retrieveAnalyticsConsent()
    let retrievedDate = try securityManager?.retrieveLastBackupDate()
    let retrievedSettings = try securityManager?.retrieveAppSettings()

    XCTAssertEqual(retrievedToken, testToken)
    XCTAssertEqual(retrievedConsent, consent)
    XCTAssertEqual(retrievedDate, testDate)
    XCTAssertEqual(retrievedSettings?["theme"] as? String, "light")
  }

  func testClearAllSecureData() throws {
    try self.securityManager?.storeSessionToken("test_token")
    try self.securityManager?.storeAnalyticsConsent(true)
    try self.securityManager?.storeLastBackupDate(Date())
    try self.securityManager?.storeAppSettings(["test": "value"])

    try self.securityManager?.clearAllSecureData()

    XCTAssertNil(try? self.securityManager?.retrieveSessionToken())
    XCTAssertNil(try? self.securityManager?.retrieveAnalyticsConsent())
    XCTAssertNil(try? self.securityManager?.retrieveLastBackupDate())
    XCTAssertNil(try? self.securityManager?.retrieveAppSettings())
  }

  func testPerformanceOfSecurityOperations() {
    measure {
      do {
        for i in 0..<50 {
          try self.securityManager?.storeSessionToken("token_\(i)")
          _ = try self.securityManager?.retrieveSessionToken()
        }
        try self.securityManager?.clearAllSecureData()
      } catch {
        XCTFail("Performance test failed: \(error)")
      }
    }
  }
}
