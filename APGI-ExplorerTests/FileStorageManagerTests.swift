import XCTest

@testable import APGI_Explorer

@MainActor
final class FileStorageManagerTests: XCTestCase {
  // swiftlint:disable:next implicitly_unwrapped_optional
  private var fileStorageManager: FileStorageManager!

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
    let manager = try XCTUnwrap(self.fileStorageManager)
    let backups = try manager.listBackups()
    XCTAssertNotNil(backups)
    // May be empty, but should not crash
  }

  func testScheduleAutomaticBackups() throws {
    let manager = try XCTUnwrap(self.fileStorageManager)
    manager.scheduleAutomaticBackups()
    // Should not crash
    XCTAssertTrue(true)
  }

  func testStopAutomaticBackups() throws {
    let manager = try XCTUnwrap(self.fileStorageManager)
    manager.stopAutomaticBackups()
    // Should not crash
    XCTAssertTrue(true)
  }
}
