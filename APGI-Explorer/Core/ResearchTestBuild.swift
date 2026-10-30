import Foundation

#if !DEBUG && APGI_RESEARCH_TEST_BUILD
  #error("APGI_RESEARCH_TEST_BUILD is a Debug-only acceptance flag; it must never be set for a Release build.")
#endif

/// Approved-test-build configuration for live research acceptance (enrolment, upload, withdrawal, score display).
///
/// Research ships off. `ExplorerBuildApproval.researchApproved` stays false until S3-EXP-01.12 and consent
/// approval are complete, and nothing here changes it. A developer can instead compile a Debug build with
/// the `APGI_RESEARCH_TEST_BUILD` Swift flag and point it at a test server through an environment variable:
///
///     xcodebuild build -project APGI-Explorer.xcodeproj -scheme APGI-Explorer -configuration Debug \
///       SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) APGI_RESEARCH_TEST_BUILD'
///     APGI_RESEARCH_TEST_API=https://research-test.example.org .../APGI-Explorer.app/Contents/MacOS/APGI-Explorer
///
/// Fail-closed rules: Release builds with the flag do not compile; a flagged build without a valid test
/// server has research unavailable (it never falls back to production); the test server must use HTTPS
/// and must not be the production API host. Server-side `research_enabled` is still required.
nonisolated enum ResearchTestBuild {
  static let environmentKey = "APGI_RESEARCH_TEST_API"

  #if DEBUG && APGI_RESEARCH_TEST_BUILD
    static let isCompiledIn = true
  #else
    static let isCompiledIn = false
  #endif

  /// Where research traffic goes, or nothing when research cannot be offered by this build.
  nonisolated struct Origin: Equatable, Sendable {
    let baseURL: URL
    let isTestServer: Bool
  }

  static func testServerURL(_ value: String?, production: URL) -> URL? {
    guard let value, let url = URL(string: value), url.scheme == "https", let host = url.host?.lowercased(),
          !host.isEmpty, url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
          host != production.host?.lowercased() else { return nil }
    return url
  }

  static func resolve(production: URL, environment: [String: String], compiledIn: Bool = isCompiledIn,
                      releaseApproved: Bool = ExplorerBuildApproval.researchApproved) -> Origin? {
    if compiledIn {
      guard let url = testServerURL(environment[environmentKey], production: production) else { return nil }
      return Origin(baseURL: url, isTestServer: true)
    }
    return releaseApproved ? Origin(baseURL: production, isTestServer: false) : nil
  }
}

nonisolated extension ResearchCapability {
  /// `buildApproved` comes from `ResearchTestBuild.resolve` (release approval or an approved test build).
  static func current(serverResearchEnabled: Bool?, buildApproved: Bool) -> ResearchCapability {
    ResearchCapability(isEnabled: buildApproved && serverResearchEnabled == true)
  }
}
