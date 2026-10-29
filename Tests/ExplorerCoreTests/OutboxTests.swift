import XCTest
@testable import ExplorerCore

final class OutboxTests: XCTestCase {
  private func make(_ steps: [ScriptedAdapter.Step], enabled: Bool = true, store: InMemoryPendingEventStore = InMemoryPendingEventStore(),
                    clock: Clock = Clock()) -> (UploadCoordinator, ScriptedAdapter, InMemoryPendingEventStore, Clock) {
    let adapter = ScriptedAdapter(steps)
    let coordinator = UploadCoordinator(store: store, adapter: adapter, capability: ResearchCapability(isEnabled: enabled),
                                        now: { clock.now }, authorization: { "token" })
    return (coordinator, adapter, store, clock)
  }

  func testShippedBuildIsDisabled() async throws {
    XCTAssertFalse(ResearchCapability.shipped.isEnabled)
    let (coordinator, adapter, _, _) = make([], enabled: false)
    do { _ = try await coordinator.enqueue(sessionID: "s", seqNo: 0, payload: payload(1, 1)); XCTFail() } catch {
      XCTAssertEqual(error as? OutboxError, .researchDisabled)
    }
    let drained = await coordinator.drain(sessionID: "s")
    XCTAssertEqual(drained, DrainResult())
    XCTAssertTrue(adapter.calls.isEmpty)
  }

  func testAckedEventClearsPayloadAndLeavesTombstone() async throws {
    let (coordinator, _, store, _) = make([.ack])
    guard case .enqueued(let key) = try await coordinator.enqueue(sessionID: "s", seqNo: 0, payload: payload(1, 2)) else { return XCTFail() }
    let result = await coordinator.drain(sessionID: "s")
    XCTAssertEqual(result.verified, 1)
    let record = try await store.record(eventKey: key)
    XCTAssertEqual(record?.state, .verified)
    XCTAssertNil(record?.payload)
    // The acknowledged entry can never be queued again.
    let again = try await coordinator.enqueue(sessionID: "s", seqNo: 0, payload: payload(1, 2))
    XCTAssertEqual(again, .alreadyAcknowledged(eventKey: key))
    let sessions = try await store.sessionsWithWork()
    XCTAssertTrue(sessions.isEmpty)
  }

  func testEnqueueIsIdempotentAndRejectsChangedPayload() async throws {
    let (coordinator, _, _, _) = make([])
    _ = try await coordinator.enqueue(sessionID: "s", seqNo: 3, payload: payload(1, 2))
    let second = try await coordinator.enqueue(sessionID: "s", seqNo: 3, payload: payload(1, 2))
    guard case .alreadyQueued = second else { return XCTFail() }
    do { _ = try await coordinator.enqueue(sessionID: "s", seqNo: 3, payload: payload(1, 3)); XCTFail() } catch {
      XCTAssertEqual(error as? OutboxError, .conflictingPayload(seqNo: 3))
    }
  }

  func testEveryFailureKeepsPayloadAndBacksOff() async throws {
    for step in [ScriptedAdapter.Step.fail, .ackWrongDigest, .ackUnverified, .ackMissing] {
      let (coordinator, _, store, clock) = make([step])
      guard case .enqueued(let key) = try await coordinator.enqueue(sessionID: "s", seqNo: 0, payload: payload(1, 2)) else { return XCTFail() }
      let result = await coordinator.drain(sessionID: "s")
      XCTAssertTrue(result.failed, "\(step)")
      let record = try await store.record(eventKey: key)
      XCTAssertNotNil(record?.payload, "\(step) must retain payload")
      XCTAssertEqual(record?.state, .pending)
      XCTAssertEqual(record?.attemptCount, 1)
      XCTAssertEqual(record?.nextAttemptAt, clock.now.addingTimeInterval(5))
      // Not due yet: nothing is sent until the retry deadline.
      let early = await coordinator.drain(sessionID: "s")
      XCTAssertEqual(early.verified, 0)
    }
  }

  func testRetryAfterDeadlineSendsSameKeyAndDigestThenSucceeds() async throws {
    let (coordinator, adapter, _, clock) = make([.fail, .ack])
    _ = try await coordinator.enqueue(sessionID: "s", seqNo: 0, payload: payload(1, 2))
    _ = await coordinator.drain(sessionID: "s")
    clock.advance(6)
    let result = await coordinator.drain(sessionID: "s")
    XCTAssertEqual(result.verified, 1)
    XCTAssertEqual(adapter.calls.count, 2)
    XCTAssertEqual(adapter.calls[0], adapter.calls[1], "a retry resends the identical key, sequence and digest")
  }

  func testOrderingIsPreservedWithinASession() async throws {
    let (coordinator, adapter, store, _) = make([.fail])
    for seq in 0..<3 { _ = try await coordinator.enqueue(sessionID: "s", seqNo: seq, payload: payload(seq + 1, 1)) }
    _ = await coordinator.drain(sessionID: "s")
    XCTAssertEqual(adapter.calls.first?.map(\.seqNo), [0, 1, 2])
    let due = try await store.dueEvents(sessionID: "s", now: Date(timeIntervalSince1970: 1_800_000_001), limit: 10)
    XCTAssertTrue(due.isEmpty, "event 0 is backed off, so 1 and 2 must not overtake it")
  }

  func testPartialAckStopsAtFirstUnverifiedAndKeepsLaterPayloads() async throws {
    let store = InMemoryPendingEventStore()
    let clock = Clock()
    let adapter = PartialAdapter()
    let coordinator = UploadCoordinator(store: store, adapter: adapter, capability: ResearchCapability(isEnabled: true),
                                        now: { clock.now }, authorization: { "t" })
    var keys: [String] = []
    for seq in 0..<3 {
      guard case .enqueued(let key) = try await coordinator.enqueue(sessionID: "s", seqNo: seq, payload: payload(seq + 1, 1)) else { return XCTFail() }
      keys.append(key)
    }
    let result = await coordinator.drain(sessionID: "s")
    XCTAssertEqual(result.verified, 1)
    let first = try await store.record(eventKey: keys[0])
    let second = try await store.record(eventKey: keys[1])
    let third = try await store.record(eventKey: keys[2])
    XCTAssertEqual(first?.state, .verified)
    XCTAssertNotNil(second?.payload)
    XCTAssertNotNil(third?.payload)
  }

  func testRelaunchRecoveryResetsInFlight() async throws {
    let store = InMemoryPendingEventStore()
    let (coordinator, _, _, _) = make([], store: store)
    guard case .enqueued(let key) = try await coordinator.enqueue(sessionID: "s", seqNo: 0, payload: payload(1, 1)) else { return XCTFail() }
    try await store.markUploading(eventKeys: [key])
    let sessions = try await coordinator.recover()
    XCTAssertEqual(sessions, ["s"])
    let record = try await store.record(eventKey: key)
    XCTAssertEqual(record?.state, .pending)
  }

  func testRetryPolicyIsExponentialAndCapped() {
    let policy = RetryPolicy()
    XCTAssertEqual([1, 2, 3, 4].map(policy.delay(afterFailure:)), [5, 10, 20, 40])
    XCTAssertEqual(policy.delay(afterFailure: 50), 3_600)
  }

  func testResearchEventProvenanceGuard() async throws {
    let (coordinator, _, _, _) = make([])
    let bankHash = String(repeating: "a", count: 64)
    let good = ResearchAnswerEvent(seqNo: 0, provenance: .research(bankSHA256: bankHash), payload: payload(1, 1))
    _ = try await coordinator.enqueue(good, sessionID: "s", expectedBankSHA256: bankHash)
    for provenance in [ResearchProvenance.personal, .legacyImport] {
      do {
        _ = try await coordinator.enqueue(ResearchAnswerEvent(seqNo: 1, provenance: provenance, payload: payload(1, 1)), sessionID: "s", expectedBankSHA256: bankHash)
        XCTFail()
      } catch { XCTAssertEqual(error as? ResearchContractError, .nonResearchProvenance) }
    }
    do {
      _ = try await coordinator.enqueue(ResearchAnswerEvent(seqNo: 1, provenance: .research(bankSHA256: "b"), payload: payload(1, 1)), sessionID: "s", expectedBankSHA256: bankHash)
      XCTFail()
    } catch { XCTAssertEqual(error as? ResearchContractError, .bankMismatch) }
  }
}

/// Acknowledges only the first event of every batch.
final class PartialAdapter: ResearchUploadAdapter, @unchecked Sendable {
  func upload(sessionID: String, events: [UploadEnvelope], authorization: String) async throws -> [UploadAcknowledgement] {
    events.prefix(1).map { UploadAcknowledgement(eventKey: $0.eventKey, seqNo: $0.seqNo, payloadDigest: $0.payloadDigest, serverVerified: true) }
  }
}
