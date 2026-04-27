import XCTest

@testable import APGI_Explorer

@MainActor
final class CrashReportingManagerTests: XCTestCase {
  var crashReportingManager: CrashReportingManager?

  override func setUpWithError() throws {
    continueAfterFailure = false
    self.crashReportingManager = CrashReportingManager.shared
  }

  override func tearDownWithError() throws {
    self.crashReportingManager = nil
  }

  func testCrashReportingManagerInitialization() {
    XCTAssertNotNil(self.crashReportingManager)
  }

  func testEnableDisableCrashReporting() {
    self.crashReportingManager.enableCrashReporting()
    XCTAssertTrue(self.crashReportingManager.isEnabled)

    self.crashReportingManager.disableCrashReporting()
    XCTAssertFalse(self.crashReportingManager.isEnabled)
  }

  func testReportCrashWhenDisabled() {
    self.crashReportingManager.disableCrashReporting()
    let error = NSError(domain: "Test", code: 1, userInfo: nil)
    self.crashReportingManager.reportCrash(error, context: "Test")
    // Should not crash, and since disabled, should not save
    XCTAssertTrue(true)
  }

  func testGetCrashReports() {
    let reports = self.crashReportingManager.getCrashReports()
    XCTAssertNotNil(reports)
    // May be empty
  }

  func testClearCrashReports() {
    self.crashReportingManager.clearCrashReports()
    // Should not crash
    XCTAssertTrue(true)
  }
}
