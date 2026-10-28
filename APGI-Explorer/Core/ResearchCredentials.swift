import Foundation

nonisolated struct ResearchCredentials: Codable, Sendable, Equatable {
  var accessToken: String
  var refreshToken: String
  var accessExpiry: Date
}

nonisolated enum ResearchCredentialError: Error, Equatable {
  case signedOut, refreshRejected, cancelled
}

/// Device-local credential storage. Implementations must never fall back to a preference store.
nonisolated protocol ResearchCredentialStoring: Sendable {
  func load() throws -> ResearchCredentials?
  func save(_ credentials: ResearchCredentials) throws
  func clear() throws
}

/// Performs the actual token refresh. The reviewed authentication adapter is not part of
/// this repository; callers supply one. A refresh that returns a new refresh token rotates it.
nonisolated protocol ResearchTokenRefreshing: Sendable {
  func refresh(refreshToken: String) async throws -> ResearchCredentials
}

nonisolated final class InMemoryCredentialStore: ResearchCredentialStoring, @unchecked Sendable {
  private let lock = NSLock()
  private var value: ResearchCredentials?
  func load() throws -> ResearchCredentials? { lock.lock(); defer { lock.unlock() }; return value }
  func save(_ credentials: ResearchCredentials) throws { lock.lock(); value = credentials; lock.unlock() }
  func clear() throws { lock.lock(); value = nil; lock.unlock() }
}

/// Hands out a valid access token, refreshing shortly before expiry.
/// Concurrent callers share one refresh; sign-out cancels it and discards its result.
actor ResearchCredentialManager {
  private let store: ResearchCredentialStoring
  private let refresher: ResearchTokenRefreshing
  private let now: @Sendable () -> Date
  private let skew: TimeInterval
  private var inflight: Task<ResearchCredentials, Error>?
  private var epoch = 0

  init(store: ResearchCredentialStoring, refresher: ResearchTokenRefreshing,
       skew: TimeInterval = 60, now: @escaping @Sendable () -> Date = { Date() }) {
    self.store = store
    self.refresher = refresher
    self.skew = skew
    self.now = now
  }

  func signIn(_ credentials: ResearchCredentials) throws {
    epoch += 1
    inflight?.cancel()
    inflight = nil
    try store.save(credentials)
  }

  func validAccessToken() async throws -> String {
    guard let current = try store.load() else { throw ResearchCredentialError.signedOut }
    if current.accessExpiry.timeIntervalSince(now()) > skew { return current.accessToken }
    if let inflight { return try await inflight.value.accessToken }

    let startedEpoch = epoch
    let refresher = refresher
    let task = Task { try await refresher.refresh(refreshToken: current.refreshToken) }
    inflight = task
    do {
      var fresh = try await task.value
      guard startedEpoch == epoch else { throw ResearchCredentialError.cancelled }
      if fresh.refreshToken.isEmpty { fresh.refreshToken = current.refreshToken }
      try store.save(fresh)
      inflight = nil
      return fresh.accessToken
    } catch {
      if startedEpoch == epoch {
        inflight = nil
        if (error as? ResearchCredentialError) == .refreshRejected { try? store.clear() }
      }
      throw error
    }
  }

  func signOut() throws {
    epoch += 1
    inflight?.cancel()
    inflight = nil
    try store.clear()
  }
}
