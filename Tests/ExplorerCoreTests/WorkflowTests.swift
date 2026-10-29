import XCTest
@testable import ExplorerCore

final class WorkflowTests: XCTestCase {
  private let required: Set<String> = ["product_use", "research_participation"]
  private let all: Set<String> = ["product_use", "research_participation", "data_sharing", "recontact"]

  private struct Harness {
    let server: FakeResearchServer
    let workflow: ResearchWorkflow
    let store: InMemoryPendingEventStore
    let progress: InMemoryProgressStore
    let clock: Clock
  }

  private func make(enabled: Bool = true, server: FakeResearchServer? = nil, store: InMemoryPendingEventStore = InMemoryPendingEventStore(),
                    progress: InMemoryProgressStore = InMemoryProgressStore(), clock: Clock = Clock()) throws -> Harness {
    let server = try server ?? FakeResearchServer()
    let account = ResearchAccountClient(transport: server)
    let credentials = ResearchCredentialManager(store: InMemoryCredentialStore(), refresher: APIResearchTokenRefresher(account: account))
    let capability = ResearchCapability(isEnabled: enabled)
    let coordinator = UploadCoordinator(store: store, adapter: ExplorerResearchAdapter(transport: server), capability: capability,
                                        now: { clock.now }, authorization: { try await credentials.validAccessToken() })
    let workflow = ResearchWorkflow(client: ExplorerResearchClient(transport: server), account: account, credentials: credentials,
                                    coordinator: coordinator, progress: progress, capability: capability)
    return Harness(server: server, workflow: workflow, store: store, progress: progress, clock: clock)
  }

  private func enrolled(_ h: Harness, accepted: Set<String>? = nil) async throws {
    _ = try await h.workflow.prepare()
    try await h.workflow.signIn(username: "u", password: "p")
    try await h.workflow.enroll(accepted: accepted ?? all)
  }

  private func answerAll(_ h: Harness, items: ClosedRange<Int> = 1...35) async throws {
    for item in items {
      try await h.workflow.show(itemID: item)
      try await h.workflow.answer(itemID: item, value: 1 + item % 4)
    }
  }

  func testDisabledBuildTouchesNothing() async throws {
    let h = try make(enabled: false)
    do { _ = try await h.workflow.prepare(); XCTFail() } catch { XCTAssertEqual(error as? ResearchContractError, .unavailable("Research is not enabled in this build.")) }
    do { try await h.workflow.signIn(username: "u", password: "p"); XCTFail() } catch {}
    do { try await h.workflow.answer(itemID: 1, value: 1); XCTFail() } catch {}
    XCTAssertTrue(h.server.requests.isEmpty, "a disabled build must not contact the server")
    XCTAssertFalse(ExplorerBuildApproval.researchApproved)
    XCTAssertFalse(ResearchCapability.current(serverResearchEnabled: true).isEnabled)
  }

  func testPrepareVerifiesPinnedBankAndApprovedConsentTexts() async throws {
    let h = try make()
    let prepared = try await h.workflow.prepare()
    XCTAssertEqual(prepared.bank.sha256, ResearchPins.bankSHA256)
    XCTAssertEqual(prepared.requiredPurposes, required)
    XCTAssertEqual(prepared.consentTexts.count, 4)

    let wrong = try make()
    wrong.server.bankSHA256 = String(repeating: "0", count: 64)
    do { _ = try await wrong.workflow.prepare(); XCTFail() } catch { XCTAssertEqual(error as? ResearchContractError, .hashMismatch) }

    let closed = try make()
    closed.server.researchEnabled = false
    do { _ = try await closed.workflow.prepare(); XCTFail() } catch { guard case .unavailable? = error as? ResearchContractError else { return XCTFail() } }
  }

  func testEnrolmentNeedsRequiredConsentsAndResumes() async throws {
    let h = try make()
    _ = try await h.workflow.prepare()
    try await h.workflow.signIn(username: "u", password: "p")
    do { try await h.workflow.enroll(accepted: ["product_use"]); XCTFail() } catch {
      XCTAssertEqual(error as? ResearchContractError, .requiredConsentMissing("research_participation"))
    }
    XCTAssertEqual(h.server.participantsCreated, 0, "no participant before required consent")
    try await h.workflow.enroll(accepted: required)
    XCTAssertEqual(h.server.granted, required, "optional purposes are not granted unless chosen")
    // A relaunch resumes the same participant and session.
    let again = try make(server: h.server, store: h.store, progress: h.progress, clock: h.clock)
    _ = try await again.workflow.prepare()
    try await again.workflow.signIn(username: "u", password: "p")
    try await again.workflow.enroll(accepted: required)
    XCTAssertEqual(h.server.participantsCreated, 1)
    XCTAssertEqual(h.server.sessionsCreated, 1)
  }

  /// S3-PR6-09 (simulated): offline answering, a lost acknowledgement, reconnect, exactly one stored copy.
  func testOfflineSessionUploadsExactlyOnceWithAllowlistedScores() async throws {
    let h = try make()
    try await enrolled(h)
    h.server.online = false
    try await answerAll(h)
    var pending = try await h.workflow.pendingCount()
    XCTAssertEqual(pending, 35)
    var sync = await h.workflow.sync()
    XCTAssertTrue(sync.failed)
    XCTAssertTrue(h.server.storedSeqNos.isEmpty)
    do { _ = try await h.workflow.finish(); XCTFail("must not finish with uploads pending") } catch {
      XCTAssertEqual(error as? ResearchContractError, .uploadsPending(35))
    }

    h.server.online = true
    h.server.dropNextUploadResponse = true       // server stores the batch, the ack is lost
    h.clock.advance(10)
    sync = await h.workflow.sync()
    XCTAssertTrue(sync.failed)
    XCTAssertEqual(h.server.storedSeqNos.count, 35, "server stored the batch even though the ack was lost")
    pending = try await h.workflow.pendingCount()
    XCTAssertEqual(pending, 35, "without an ack nothing is cleared locally")

    h.clock.advance(3_600)
    sync = await h.workflow.sync()
    XCTAssertEqual(sync.verified, 35)
    XCTAssertEqual(h.server.storedSeqNos, Array(0..<35), "every event stored exactly once, in order")
    pending = try await h.workflow.pendingCount()
    XCTAssertEqual(pending, 0)

    let scores = try await h.workflow.finish()
    XCTAssertEqual(scores.map(\.label), ScoreLabels.approved)
    XCTAssertTrue(scores.allSatisfy { $0.value.isFinite && $0.value >= 12.5 && $0.value <= 87.5 })
    XCTAssertNil(try h.progress.load(), "local progress is deleted after verified upload and result")
  }

  func testRelaunchResumesAnswersAndContinuesSequence() async throws {
    let h = try make()
    try await enrolled(h)
    try await answerAll(h, items: 1...10)
    let relaunch = try make(server: h.server, store: h.store, progress: h.progress, clock: h.clock)
    _ = try await relaunch.workflow.prepare()
    try await relaunch.workflow.signIn(username: "u", password: "p")
    try await relaunch.workflow.enroll(accepted: required)
    let restored = await relaunch.workflow.answers
    XCTAssertEqual(restored.count, 10)
    try await relaunch.workflow.show(itemID: 11)
    try await relaunch.workflow.answer(itemID: 11, value: 3)
    _ = await relaunch.workflow.sync()
    XCTAssertEqual(h.server.storedSeqNos, Array(0...10))
  }

  func testChangingAnAnswerJournalsALaterEventAndServerUsesLatest() async throws {
    let h = try make()
    try await enrolled(h)
    try await h.workflow.show(itemID: 1)
    try await h.workflow.answer(itemID: 1, value: 2)
    try await h.workflow.answer(itemID: 1, value: 2)  // unchanged: no event
    try await h.workflow.answer(itemID: 1, value: 4)
    _ = await h.workflow.sync()
    XCTAssertEqual(h.server.storedSeqNos, [0, 1])
  }

  func testIncompleteSessionCannotFinish() async throws {
    let h = try make()
    try await enrolled(h)
    try await answerAll(h, items: 1...5)
    do { _ = try await h.workflow.finish(); XCTFail() } catch { XCTAssertEqual(error as? ResearchContractError, .incomplete) }
  }

  func testQuestionnaireRejectsItemsAndValuesOutsideTheBank() async throws {
    let h = try make()
    try await enrolled(h)
    do { try await h.workflow.show(itemID: 99); XCTFail() } catch { XCTAssertEqual(error as? ResearchContractError, .unknownItem(99)) }
    try await h.workflow.show(itemID: 1)
    do { try await h.workflow.answer(itemID: 1, value: 9); XCTFail() } catch { XCTAssertEqual(error as? ResearchContractError, .invalidValue(9)) }
  }

  func testWithdrawalRevokesAndDeletesLocalData() async throws {
    let h = try make()
    try await enrolled(h)
    try await answerAll(h, items: 1...3)
    try await h.workflow.withdraw(purposes: ["research_participation"])
    XCTAssertTrue(h.server.revoked.contains("research_participation"))
    XCTAssertNil(try h.progress.load())
    let work = try await h.store.sessionsWithWork()
    XCTAssertTrue(work.isEmpty)
    let enrolledAfter = await h.workflow.isEnrolled
    XCTAssertFalse(enrolledAfter)
  }

  func testLegacyAndPersonalDataCanNeverEnterResearch() async throws {
    let h = try make()
    for source in [ResearchImportSource.personalProfile, .legacyBackup] {
      XCTAssertThrowsError(try h.workflow.importLegacy(source)) { XCTAssertEqual($0 as? ResearchContractError, .legacyImportBlocked) }
      XCTAssertFalse(ResearchImportGate.admits(source))
    }
    XCTAssertNoThrow(try h.workflow.importLegacy(.serverBank))
  }

  func testScoreDecodingAcceptsOnlyAllowlistedFields() async throws {
    let allowlist = try ScoreAllowlist(response: try Fixture.json("score-allowlist"))
    let extra: APIJSONValue = .object(["scores": .object(["reported_attentional_threshold": .number(50), "interactions": .number(1)])])
    XCTAssertThrowsError(try allowlist.decode(scores: extra))
  }
}
