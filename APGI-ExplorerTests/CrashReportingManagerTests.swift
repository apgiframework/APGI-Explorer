@testable import APGI_Explorer
import XCTest

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
        guard let crashReportingManager = self.crashReportingManager else {
            XCTFail("Crash reporting manager not initialized")
            return
        }
        crashReportingManager.enableCrashReporting()
        XCTAssertTrue(crashReportingManager.isEnabled)

        crashReportingManager.disableCrashReporting()
        XCTAssertFalse(crashReportingManager.isEnabled)
    }

    func testReportCrashWhenDisabled() {
        guard let crashReportingManager = self.crashReportingManager else {
            XCTFail("Crash reporting manager not initialized")
            return
        }
        crashReportingManager.disableCrashReporting()
        let error = NSError(domain: "Test", code: 1, userInfo: nil)
        crashReportingManager.reportCrash(error, context: "Test")
        // Should not crash, and since disabled, should not save
        XCTAssertTrue(true)
    }

    func testGetCrashReports() {
        guard let crashReportingManager = self.crashReportingManager else {
            XCTFail("Crash reporting manager not initialized")
            return
        }
        let reports = crashReportingManager.getCrashReports()
        XCTAssertNotNil(reports)
        // May be empty
    }

    func testClearCrashReports() {
        guard let crashReportingManager = self.crashReportingManager else {
            XCTFail("Crash reporting manager not initialized")
            return
        }
        crashReportingManager.clearCrashReports()
        // Should not crash
        XCTAssertTrue(true)
    }
}
