import XCTest
@testable import ExplorerCore

final class CredentialTests: XCTestCase {
  final class Refresher: ResearchTokenRefreshing, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var calls = 0
    var delay: UInt64 = 50_000_000
    var rotate = true
    var reject = false
    func refresh(refreshToken: String) async throws -> ResearchCredentials {
      let n: Int = lock.withLock { calls += 1; return calls }
      try await Task.sleep(nanoseconds: delay)
      if reject { throw ResearchCredentialError.refreshRejected }
      return ResearchCredentials(accessToken: "access-\(n)", refreshToken: rotate ? "refresh-\(n)" : "",
                                 accessExpiry: Date().addingTimeInterval(3_600))
    }
  }

  private func setup(expiring: TimeInterval) throws -> (ResearchCredentialManager, InMemoryCredentialStore, Refresher) {
    let store = InMemoryCredentialStore()
    try store.save(ResearchCredentials(accessToken: "old", refreshToken: "refresh-0", accessExpiry: Date().addingTimeInterval(expiring)))
    let refresher = Refresher()
    return (ResearchCredentialManager(store: store, refresher: refresher), store, refresher)
  }

  func testValidTokenIsReturnedWithoutRefresh() async throws {
    let (manager, _, refresher) = try setup(expiring: 3_600)
    let token = try await manager.validAccessToken()
    XCTAssertEqual(token, "old")
    XCTAssertEqual(refresher.calls, 0)
  }

  func testExpiredTokenRefreshesAndRotatesRefreshToken() async throws {
    let (manager, store, refresher) = try setup(expiring: -10)
    let token = try await manager.validAccessToken()
    XCTAssertEqual(token, "access-1")
    XCTAssertEqual(try store.load()?.refreshToken, "refresh-1")
    XCTAssertEqual(refresher.calls, 1)
  }

  func testRefreshWithoutNewRefreshTokenKeepsTheOldOne() async throws {
    let (manager, store, refresher) = try setup(expiring: -10)
    refresher.rotate = false
    _ = try await manager.validAccessToken()
    XCTAssertEqual(try store.load()?.refreshToken, "refresh-0")
  }

  func testConcurrentCallersShareOneRefresh() async throws {
    let (manager, _, refresher) = try setup(expiring: 5)
    let tokens = try await withThrowingTaskGroup(of: String.self) { group in
      for _ in 0..<8 { group.addTask { try await manager.validAccessToken() } }
      return try await group.reduce(into: []) { $0.append($1) }
    }
    XCTAssertEqual(Set(tokens), ["access-1"])
    XCTAssertEqual(refresher.calls, 1)
  }

  func testRejectedRefreshClearsCredentials() async throws {
    let (manager, store, refresher) = try setup(expiring: -10)
    refresher.reject = true
    do { _ = try await manager.validAccessToken(); XCTFail() } catch { XCTAssertEqual(error as? ResearchCredentialError, .refreshRejected) }
    XCTAssertNil(try store.load())
  }

  func testSignOutCancelsInFlightRefreshAndDiscardsItsResult() async throws {
    let (manager, store, refresher) = try setup(expiring: -10)
    refresher.delay = 300_000_000
    let pending = Task { try await manager.validAccessToken() }
    try await Task.sleep(nanoseconds: 50_000_000)
    try await manager.signOut()
    do { _ = try await pending.value; XCTFail("sign-out must not hand out a token") } catch {}
    XCTAssertNil(try store.load(), "a refresh finishing after sign-out must not resurrect credentials")
    do { _ = try await manager.validAccessToken(); XCTFail() } catch { XCTAssertEqual(error as? ResearchCredentialError, .signedOut) }
  }
}
