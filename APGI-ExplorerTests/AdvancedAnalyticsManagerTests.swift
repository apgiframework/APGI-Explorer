import XCTest

@testable import APGI_Explorer

final class AdvancedAnalyticsManagerTests: XCTestCase {
  var analyticsManager: AdvancedAnalyticsManager?
  var mockDataStore: MockDataStore?

  override func setUpWithError() throws {
    continueAfterFailure = false
    self.mockDataStore = MockDataStore()
    if let mockDataStore = self.mockDataStore {
      self.analyticsManager = AdvancedAnalyticsManager(dataStore: mockDataStore)
    }
  }

  override func tearDownWithError() throws {
    self.analyticsManager = nil
    self.mockDataStore = nil
  }

  func testAdvancedAnalyticsManagerInitialization() {
    guard let analyticsManager = self.analyticsManager else {
      XCTFail("Analytics manager not initialized")
      return
    }
    XCTAssertNotNil(analyticsManager)
    XCTAssertTrue(analyticsManager.trendData.isEmpty)
    XCTAssertTrue(analyticsManager.predictions.isEmpty)
    XCTAssertTrue(analyticsManager.insights.isEmpty)
    XCTAssertFalse(analyticsManager.isLoading)
    XCTAssertNil(analyticsManager.error)
  }

  func testAnalyzeTrendsWithEmptyProfiles() async {
    guard let analyticsManager = self.analyticsManager else {
      XCTFail("Analytics manager not initialized")
      return
    }
    await analyticsManager.analyzeTrends(for: [])

    XCTAssertTrue(analyticsManager.trendData.isEmpty)
    XCTAssertTrue(analyticsManager.predictions.isEmpty)
    XCTAssertTrue(analyticsManager.insights.isEmpty)
    XCTAssertFalse(analyticsManager.isLoading)
    XCTAssertNil(analyticsManager.error)
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
