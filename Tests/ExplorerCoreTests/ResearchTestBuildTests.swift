import XCTest
@testable import ExplorerCore

final class ResearchTestBuildTests: XCTestCase {
  private let production = URL(string: "https://api.apgiframework.com")!
  private let key = ResearchTestBuild.environmentKey

  func testCompiledStateFollowsTheDebugFlagOnly() {
    #if DEBUG && APGI_RESEARCH_TEST_BUILD
      XCTAssertTrue(ResearchTestBuild.isCompiledIn)
    #else
      XCTAssertFalse(ResearchTestBuild.isCompiledIn, "ordinary builds must not contain the acceptance configuration")
    #endif
    XCTAssertFalse(ExplorerBuildApproval.researchApproved, "the test build never changes release approval")
  }

  func testShippedBuildOffersNothingWhateverTheEnvironmentSays() {
    let hostile = [key: "https://research-test.example.org"]
    XCTAssertNil(ResearchTestBuild.resolve(production: production, environment: hostile, compiledIn: false, releaseApproved: false))
    XCTAssertNil(ResearchTestBuild.resolve(production: production, environment: [:], compiledIn: false, releaseApproved: false))
  }

  func testApprovedReleaseUsesProductionAndIgnoresTheTestVariable() {
    let origin = ResearchTestBuild.resolve(production: production, environment: [key: "https://x.example.org"],
                                           compiledIn: false, releaseApproved: true)
    XCTAssertEqual(origin, ResearchTestBuild.Origin(baseURL: production, isTestServer: false))
  }

  func testTestBuildNeedsAValidNonProductionHttpsServerAndNeverFallsBackToProduction() {
    let good = ResearchTestBuild.resolve(production: production, environment: [key: "https://research-test.example.org"],
                                         compiledIn: true, releaseApproved: false)
    XCTAssertEqual(good, ResearchTestBuild.Origin(baseURL: URL(string: "https://research-test.example.org")!, isTestServer: true))
    let rejected = [nil, "", "not a url", "http://research-test.example.org", "ftp://x.example.org",
                    "https://api.apgiframework.com", "https://API.APGIFRAMEWORK.COM/v1",
                    "https://user:pw@research-test.example.org", "https://research-test.example.org?x=1",
                    "https://research-test.example.org#frag"]
    for value in rejected {
      let environment = value.map { [key: $0] } ?? [:]
      XCTAssertNil(ResearchTestBuild.resolve(production: production, environment: environment, compiledIn: true,
                                             releaseApproved: true), "\(value ?? "nil")")
    }
  }

  func testCapabilityStillNeedsTheServerSwitch() {
    XCTAssertTrue(ResearchCapability.current(serverResearchEnabled: true, buildApproved: true).isEnabled)
    XCTAssertFalse(ResearchCapability.current(serverResearchEnabled: false, buildApproved: true).isEnabled)
    XCTAssertFalse(ResearchCapability.current(serverResearchEnabled: nil, buildApproved: true).isEnabled)
    XCTAssertFalse(ResearchCapability.current(serverResearchEnabled: true, buildApproved: false).isEnabled)
    XCTAssertFalse(ResearchCapability.current(serverResearchEnabled: true).isEnabled, "shipped approval is still false")
  }
}
