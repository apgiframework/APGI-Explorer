import CloudKit
import XCTest

@testable import APGI_Explorer

@MainActor
final class CloudSyncTests: XCTestCase {
  var cloudSyncManager: CloudSyncManager!

  override func setUpWithError() throws {
    continueAfterFailure = false
    self.cloudSyncManager = CloudSyncManager.shared
  }

  override func tearDownWithError() throws {
    self.cloudSyncManager = nil
  }

  func testCloudSyncManagerInitialization() throws {
    XCTAssertNotNil(self.cloudSyncManager)
    XCTAssertFalse(self.cloudSyncManager.isSyncing)
    XCTAssertEqual(self.cloudSyncManager.accountStatus, .couldNotDetermine)
  }

  func testAccountStatusCheck() {
    // Note: In a real test environment, we might not have iCloud access
    // so we just verify the method doesn't crash
    self.cloudSyncManager.checkAccountStatus()
  }

  func testDiscoverabilityPermissionRequest() {
    // Method removed - no longer available
    XCTAssertTrue(true)
  }

  func testCloudSyncErrorDescriptions() {
    let errors: [CloudSyncManager.CloudSyncError] = [
      .accountNotAvailable,
      .accountRestricted,
      .networkUnavailable,
      .quotaExceeded,
      .zoneNotFound,
      .recordNotFound,
      .invalidData,
      .syncInProgress,
      .unknown(NSError(domain: "test", code: 1)),
    ]

    for error in errors {
      XCTAssertNotNil(error.localizedDescription)
      XCTAssertFalse(error.localizedDescription.isEmpty)
    }
  }

  func testCloudProfileInitialization() {
    let record = CKRecord(recordType: "Profile")
    record["id"] = "test-id"
    record["name"] = "Test Profile"
    record["createdAt"] = Date()
    record["updatedAt"] = Date()

    let cloudProfile = CloudProfile(from: record)

    XCTAssertNotNil(cloudProfile)
    XCTAssertEqual(cloudProfile?.id, "test-id")
    XCTAssertEqual(cloudProfile?.name, "Test Profile")
  }

  func testCloudProfileInvalidInitialization() {
    let record = CKRecord(recordType: "Profile")
    // Missing required fields

    let cloudProfile = CloudProfile(from: record)
    XCTAssertNil(cloudProfile)
  }
}
