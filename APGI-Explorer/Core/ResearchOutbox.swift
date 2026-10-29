import Foundation

/// Research mode is compiled in but disabled. Nothing enqueues or uploads until a
/// reviewed contract, an approved release and this switch all exist.
nonisolated struct ResearchCapability: Sendable, Equatable {
  let isEnabled: Bool
  static let shipped = ResearchCapability(isEnabled: false)
}

nonisolated enum PendingEventState: String, Sendable, Equatable {
  /// Waiting to upload (or to retry). Payload is retained.
  case pending
  /// Handed to the transport. Reset to `pending` on relaunch.
  case uploading
  /// Server acknowledged key + digest. Payload cleared; row kept as a tombstone.
  case verified
}

nonisolated struct PendingEventRecord: Sendable, Equatable {
  let eventKey: String
  let sessionID: String
  let seqNo: Int
  var payload: Data?
  let payloadDigest: String
  var state: PendingEventState
  var attemptCount: Int
  var nextAttemptAt: Date?
  let createdAt: Date
  var verifiedAt: Date?
}

nonisolated enum OutboxError: Error, Equatable {
  case researchDisabled
  case conflictingPayload(seqNo: Int)
  case invalidSession
}

nonisolated enum EnqueueResult: Sendable, Equatable {
  case enqueued(eventKey: String)
  case alreadyQueued(eventKey: String)
  /// A verified tombstone exists: the entry was acknowledged and is never enqueued again.
  case alreadyAcknowledged(eventKey: String)
}

/// Persistence for the outbox. Core Data implements this natively; tests use memory.
nonisolated protocol PendingEventStoring: Sendable {
  func insertIfAbsent(_ record: PendingEventRecord) async throws -> EnqueueResult
  /// Unverified events of one session in sequence order, only when the first one is due.
  /// Ordering is preserved: a later event is never returned while an earlier one is not verified.
  func dueEvents(sessionID: String, now: Date, limit: Int) async throws -> [PendingEventRecord]
  func markUploading(eventKeys: [String]) async throws
  func markVerified(eventKey: String, at date: Date) async throws
  func recordFailure(eventKey: String, nextAttemptAt: Date) async throws
  /// Relaunch recovery: anything left `uploading` becomes `pending` again.
  func resetInFlight() async throws
  func sessionsWithWork() async throws -> [String]
  func record(eventKey: String) async throws -> PendingEventRecord?
  /// Withdrawal: remove every local record (including tombstones) for a session.
  func purgeSession(_ sessionID: String) async throws
  func openCount(sessionID: String) async throws -> Int
}

nonisolated enum EventKey {
  /// Deterministic UUID derived from session and sequence, so a crash between
  /// journalling and enqueueing can never produce two keys for one entry.
  static func make(sessionID: String, seqNo: Int) -> String {
    var bytes = Array(PortableSHA256.hash(Data("apgi-explorer-event:\(sessionID):\(seqNo)".utf8)).prefix(16))
    bytes[6] = (bytes[6] & 0x0f) | 0x50
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    let hex = bytes.map { String(format: "%02x", $0) }.joined()
    let chars = Array(hex)
    func part(_ range: Range<Int>) -> String { String(chars[range]) }
    return [part(0..<8), part(8..<12), part(12..<16), part(16..<20), part(20..<32)].joined(separator: "-")
  }
}

actor InMemoryPendingEventStore: PendingEventStoring {
  private var records: [String: PendingEventRecord] = [:]

  func insertIfAbsent(_ record: PendingEventRecord) async throws -> EnqueueResult {
    if let existing = records.values.first(where: { $0.sessionID == record.sessionID && $0.seqNo == record.seqNo }) {
      guard existing.payloadDigest == record.payloadDigest else {
        throw OutboxError.conflictingPayload(seqNo: record.seqNo)
      }
      return existing.state == .verified
        ? .alreadyAcknowledged(eventKey: existing.eventKey)
        : .alreadyQueued(eventKey: existing.eventKey)
    }
    records[record.eventKey] = record
    return .enqueued(eventKey: record.eventKey)
  }

  func dueEvents(sessionID: String, now: Date, limit: Int) async throws -> [PendingEventRecord] {
    let open = records.values.filter { $0.sessionID == sessionID && $0.state != .verified }
      .sorted { $0.seqNo < $1.seqNo }
    guard let first = open.first, first.state == .pending,
          first.nextAttemptAt.map({ $0 <= now }) ?? true else { return [] }
    var due: [PendingEventRecord] = []
    for record in open.prefix(limit) {
      guard record.state == .pending else { break }
      due.append(record)
    }
    return due
  }

  func markUploading(eventKeys: [String]) async throws {
    for key in eventKeys { records[key]?.state = .uploading }
  }

  func markVerified(eventKey: String, at date: Date) async throws {
    guard var record = records[eventKey] else { return }
    record.payload = nil
    record.state = .verified
    record.verifiedAt = date
    record.nextAttemptAt = nil
    records[eventKey] = record
  }

  func recordFailure(eventKey: String, nextAttemptAt: Date) async throws {
    guard var record = records[eventKey], record.state != .verified else { return }
    record.state = .pending
    record.attemptCount += 1
    record.nextAttemptAt = nextAttemptAt
    records[eventKey] = record
  }

  func resetInFlight() async throws {
    for (key, record) in records where record.state == .uploading {
      var reset = record
      reset.state = .pending
      records[key] = reset
    }
  }

  func sessionsWithWork() async throws -> [String] {
    Array(Set(records.values.filter { $0.state != .verified }.map(\.sessionID))).sorted()
  }

  func record(eventKey: String) async throws -> PendingEventRecord? { records[eventKey] }

  func openCount(sessionID: String) async throws -> Int {
    records.values.filter { $0.sessionID == sessionID && $0.state != .verified }.count
  }

  func purgeSession(_ sessionID: String) async throws {
    records = records.filter { $0.value.sessionID != sessionID }
  }
}
