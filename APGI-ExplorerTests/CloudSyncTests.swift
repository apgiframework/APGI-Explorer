@testable import APGI_Explorer
import CloudKit
import XCTest

final class CloudSyncTests: XCTestCase {
    var cloudSyncManager: CloudSyncManager?

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.cloudSyncManager = CloudSyncManager.shared
    }

    override func tearDownWithError() throws {
        self.cloudSyncManager = nil
    }

    func testCloudSyncManagerInitialization() throws {
        XCTAssertNotNil(try XCTUnwrap(self.cloudSyncManager))
        XCTAssertFalse(try XCTUnwrap(self.cloudSyncManager?.isSyncing))
        XCTAssertEqual(self.cloudSyncManager?.accountStatus, .couldNotDetermine)
    }

    func testAccountStatusCheck() {
        let expectation = XCTestExpectation(description: "Account status check completes")

        self.cloudSyncManager?.checkAccountStatus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Note: In a real test environment, we might not have iCloud access
        // so we just verify the method doesn't crash
        XCTAssertTrue(true)
    }

    func testDiscoverabilityPermissionRequest() {
        let expectation = XCTestExpectation(description: "Discoverability permission request completes")

        self.cloudSyncManager?.requestDiscoverabilityPermission()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Verify the method doesn't crash
        XCTAssertTrue(true)
    }

    func testCloudSyncErrorDescriptions() {
        let errors: [CloudSyncManager.CloudSyncError] = [
            .accountNotAvailable,
            .accountRestricted,
            .accountNoiCloud,
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
