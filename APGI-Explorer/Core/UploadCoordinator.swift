import Foundation

nonisolated struct UploadEnvelope: Sendable, Equatable {
  let eventKey: String
  let seqNo: Int
  let payload: Data
  let payloadDigest: String
}

nonisolated struct UploadAcknowledgement: Sendable, Equatable {
  let eventKey: String
  let seqNo: Int
  let payloadDigest: String
  let serverVerified: Bool
}

/// The explicit server-contract adapter. The coordinator knows nothing about routes.
nonisolated protocol ResearchUploadAdapter: Sendable {
  func upload(sessionID: String, events: [UploadEnvelope], authorization: String) async throws -> [UploadAcknowledgement]
}

nonisolated struct RetryPolicy: Sendable, Equatable {
  var base: TimeInterval = 5
  var cap: TimeInterval = 3_600
  var factor: Double = 2

  /// Delay after the `attempt`-th consecutive failure (1-based). Deterministic: server
  /// idempotency, not jitter, is what makes retries safe.
  func delay(afterFailure attempt: Int) -> TimeInterval {
    min(cap, base * pow(factor, Double(max(0, attempt - 1))))
  }
}

nonisolated struct DrainResult: Sendable, Equatable {
  var verified = 0
  var failed = false
  var nextAttemptAt: Date?
}

/// Uploads outbox events in sequence order, one session at a time.
///
/// Invariants: payload is cleared only by an acknowledgement matching the event key,
/// sequence number and payload digest with `serverVerified == true`; every other outcome
/// (offline, HTTP error, redirect, malformed or mismatching ack) keeps the payload and
/// schedules a retry; a later event never overtakes an earlier unverified one.
/// Retries re-send the same key, so exactly-once *effects* are the server's guarantee.
actor UploadCoordinator {
  private let store: PendingEventStoring
  private let adapter: ResearchUploadAdapter
  private let capability: ResearchCapability
  private let retry: RetryPolicy
  private let now: @Sendable () -> Date
  private let authorization: @Sendable () async throws -> String
  private let batchSize: Int
  private var draining: Set<String> = []

  init(store: PendingEventStoring, adapter: ResearchUploadAdapter,
       capability: ResearchCapability = .shipped, retry: RetryPolicy = RetryPolicy(),
       batchSize: Int = 50, now: @escaping @Sendable () -> Date = { Date() },
       authorization: @escaping @Sendable () async throws -> String) {
    self.store = store
    self.adapter = adapter
    self.capability = capability
    self.retry = retry
    self.batchSize = batchSize
    self.now = now
    self.authorization = authorization
  }

  func enqueue(sessionID: String, seqNo: Int, payload: APIJSONValue) async throws -> EnqueueResult {
    guard capability.isEnabled else { throw OutboxError.researchDisabled }
    guard !sessionID.isEmpty, seqNo >= 0 else { throw OutboxError.invalidSession }
    let bytes = try CanonicalJSON.bytes(payload)
    let record = PendingEventRecord(
      eventKey: EventKey.make(sessionID: sessionID, seqNo: seqNo), sessionID: sessionID, seqNo: seqNo,
      payload: bytes, payloadDigest: PortableSHA256.hexDigest(bytes), state: .pending, attemptCount: 0,
      nextAttemptAt: nil, createdAt: now(), verifiedAt: nil)
    return try await store.insertIfAbsent(record)
  }

  /// Call at launch: resets interrupted uploads and returns sessions that still have work.
  func recover() async throws -> [String] {
    guard capability.isEnabled else { return [] }
    try await store.resetInFlight()
    return try await store.sessionsWithWork()
  }

  func drain(sessionID: String) async -> DrainResult {
    var result = DrainResult()
    guard capability.isEnabled, draining.insert(sessionID).inserted else { return result }
    defer { draining.remove(sessionID) }
    do {
      while true {
        let due = try await store.dueEvents(sessionID: sessionID, now: now(), limit: batchSize)
        guard !due.isEmpty else { break }
        let envelopes = due.compactMap { record in
          record.payload.map { UploadEnvelope(eventKey: record.eventKey, seqNo: record.seqNo,
                                              payload: $0, payloadDigest: record.payloadDigest) }
        }
        guard envelopes.count == due.count else { throw OutboxError.invalidSession }
        try await store.markUploading(eventKeys: due.map(\.eventKey))

        let acks: [UploadAcknowledgement]
        do {
          acks = try await adapter.upload(sessionID: sessionID, events: envelopes,
                                          authorization: try await authorization())
        } catch {
          try await fail(from: due[0], batch: due, result: &result)
          return result
        }
        for (index, record) in due.enumerated() {
          let valid = acks.first {
            $0.eventKey == record.eventKey && $0.seqNo == record.seqNo
              && $0.payloadDigest == record.payloadDigest && $0.serverVerified
          } != nil
          guard valid else {
            try await fail(from: record, batch: Array(due[index...]), result: &result)
            return result
          }
          try await store.markVerified(eventKey: record.eventKey, at: now())
          result.verified += 1
        }
      }
    } catch {
      result.failed = true
    }
    return result
  }

  private func fail(from record: PendingEventRecord, batch: [PendingEventRecord],
                    result: inout DrainResult) async throws {
    let delay = retry.delay(afterFailure: record.attemptCount + 1)
    let next = now().addingTimeInterval(delay)
    // Only the first unverified event is backed off; the rest return to pending untouched.
    try await store.recordFailure(eventKey: record.eventKey, nextAttemptAt: next)
    for other in batch.dropFirst() { try await store.recordFailure(eventKey: other.eventKey, nextAttemptAt: next) }
    result.failed = true
    result.nextAttemptAt = next
  }
}
