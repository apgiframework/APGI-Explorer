import XCTest

@testable import APGI_Explorer

@MainActor
final class FileStorageManagerTests: XCTestCase {
  var fileStorageManager: FileStorageManager?

  override func setUpWithError() throws {
    continueAfterFailure = false
    self.fileStorageManager = FileStorageManager.shared
  }

  override func tearDownWithError() throws {
    self.fileStorageManager = nil
  }

  func testFileStorageManagerInitialization() {
    XCTAssertNotNil(self.fileStorageManager)
  }

  func testListBackups() throws {
    let backups = try self.fileStorageManager.listBackups()
    XCTAssertNotNil(backups)
    // May be empty, but should not crash
  }

  func testScheduleAutomaticBackups() {
    self.fileStorageManager.scheduleAutomaticBackups()
    // Should not crash
    XCTAssertTrue(true)
  }

  func testStopAutomaticBackups() {
    self.fileStorageManager.stopAutomaticBackups()
    // Should not crash
    XCTAssertTrue(true)
  }
}
