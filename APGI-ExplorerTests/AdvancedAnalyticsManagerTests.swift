@testable import APGI_Explorer
import XCTest

final class AdvancedAnalyticsManagerTests: XCTestCase {
    var analyticsManager: AdvancedAnalyticsManager!
    var mockDataStore: MockDataStore!

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.mockDataStore = MockDataStore()
        self.analyticsManager = AdvancedAnalyticsManager(dataStore: self.mockDataStore)
    }

    override func tearDownWithError() throws {
        self.analyticsManager = nil
        self.mockDataStore = nil
    }

    func testAdvancedAnalyticsManagerInitialization() {
        XCTAssertNotNil(self.analyticsManager)
        XCTAssertTrue(self.analyticsManager.trendData.isEmpty)
        XCTAssertTrue(self.analyticsManager.predictions.isEmpty)
        XCTAssertTrue(self.analyticsManager.insights.isEmpty)
        XCTAssertFalse(self.analyticsManager.isLoading)
        XCTAssertNil(self.analyticsManager.error)
    }

    func testAnalyzeTrendsWithEmptyProfiles() async {
        await self.analyticsManager.analyzeTrends(for: [])

        XCTAssertTrue(self.analyticsManager.trendData.isEmpty)
        XCTAssertTrue(self.analyticsManager.predictions.isEmpty)
        XCTAssertTrue(self.analyticsManager.insights.isEmpty)
        XCTAssertFalse(self.analyticsManager.isLoading)
        XCTAssertNil(self.analyticsManager.error)
    }

    func testTrendDirectionDisplayNames() {
        XCTAssertEqual(TrendDirection.increasing.displayName, "Increasing")
        XCTAssertEqual(TrendDirection.decreasing.displayName, "Decreasing")
        XCTAssertEqual(TrendDirection.stable.displayName, "Stable")
    }

    func testInsightTypeDisplayNames() {
        XCTAssertEqual(InsightType.significantChange.displayName, "Significant Change")
        XCTAssertEqual(InsightType.moderateChange.displayName, "Moderate Change")
        XCTAssertEqual(InsightType.minimalChange.displayName, "Minimal Change")
    }

    func testInsightSeverityPriorities() {
        XCTAssertEqual(InsightSeverity.high.priority, 3)
        XCTAssertEqual(InsightSeverity.medium.priority, 2)
        XCTAssertEqual(InsightSeverity.low.priority, 1)
    }
}

/// Mock DataStore for testing
class MockDataStore: DataStore {
    func saveProfile(_: QuizProfile) async throws {
        // Mock implementation
    }

    func fetchProfiles(sortBy _: ProfileSortOption, ascending _: Bool) async throws -> [QuizProfile] {
        []
    }

    func fetchProfile(id _: UUID) async throws -> QuizProfile? {
        nil
    }

    func searchProfiles(query _: String) async throws -> [QuizProfile] {
        []
    }

    func deleteProfile(_: QuizProfile) async throws {
        // Mock implementation
    }

    func deleteAllProfiles() async throws {
        // Mock implementation
    }
}
