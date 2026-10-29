import Foundation

/// Minimal resumable state for an enrolled research session. Holds a pseudonymous participant ID,
/// the session ID and the answers not yet confirmed uploaded. It is deleted once every event is
/// server-verified (S3-EXP-01.6) or the participant withdraws.
nonisolated struct ResearchProgress: Codable, Equatable, Sendable {
  var participantID: String
  var sessionID: String
  var bankSHA256: String
  var nextSeqNo: Int
  var answers: [Int: Int]
}

nonisolated protocol ResearchProgressStoring: Sendable {
  func load() throws -> ResearchProgress?
  func save(_ progress: ResearchProgress) throws
  func clear() throws
}

nonisolated final class InMemoryProgressStore: ResearchProgressStoring, @unchecked Sendable {
  private let lock = NSLock()
  private var value: ResearchProgress?
  func load() throws -> ResearchProgress? { lock.withLock { value } }
  func save(_ progress: ResearchProgress) throws { lock.withLock { value = progress } }
  func clear() throws { lock.withLock { value = nil } }
}
