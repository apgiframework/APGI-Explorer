import XCTest

@testable import APGI_Explorer

@MainActor
final class AdvancedAnalyticsManagerTests: XCTestCase {
  var analyticsManager: AdvancedAnalyticsManager?
  var mockDataStore: MockDataStore?

  override func setUpWithError() throws {
    continueAfterFailure = false
    self.mockDataStore = MockDataStore()
    self.analyticsManager = AdvancedAnalyticsManager(dataStore: mockDataStore)
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
@MainActor
class MockDataStore: DataStore {
  func save(_ value: some Codable, forKey key: String) async throws {
    // Mock implementation
  }

  func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
    nil
  }

  func delete(forKey key: String) async throws {
    // Mock implementation
  }

  func clearAll() async throws {
    // Mock implementation
  }

  func getStorageInfo() async -> StorageInfo {
    StorageInfo(totalSpace: 1_000_000, availableSpace: 500000, usedSpace: 500000)
  }
}
