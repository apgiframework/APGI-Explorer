import Foundation

nonisolated struct ResearchPreparation: Sendable {
  let config: ResearchConfig
  let bank: ResearchBank
  let consentTexts: [ResearchConsentText]
  var requiredPurposes: Set<String> { Set(config.purposes.filter(\.requiredForResearch).map(\.consentType)) }
}

/// The opt-in research workflow: verify the server contract, obtain consent, enrol, record
/// answers into the durable outbox, upload with acknowledgement, and show allow-listed scores.
///
/// Everything is gated by `ResearchCapability`: in this build it is disabled, so every entry
/// point throws `unavailable` and nothing is fetched, stored or sent.
actor ResearchWorkflow {
  private let client: ExplorerResearchClient
  private let account: ResearchAccountClient
  private let credentials: ResearchCredentialManager
  private let coordinator: UploadCoordinator
  private let progressStore: ResearchProgressStoring
  private let capability: ResearchCapability
  private let locale: String
  private let clock: MonotonicMicrosecondClock

  private(set) var preparation: ResearchPreparation?
  private var recorder: ResearchRecorder?
  private var progress: ResearchProgress?

  init(client: ExplorerResearchClient, account: ResearchAccountClient, credentials: ResearchCredentialManager,
       coordinator: UploadCoordinator, progress: ResearchProgressStoring, capability: ResearchCapability,
       locale: String = "en", clock: MonotonicMicrosecondClock = ContinuousMicrosecondClock()) {
    self.client = client
    self.account = account
    self.credentials = credentials
    self.coordinator = coordinator
    self.progressStore = progress
    self.capability = capability
    self.locale = locale
    self.clock = clock
  }

  private func requireEnabled() throws {
    guard capability.isEnabled else { throw ResearchContractError.unavailable("Research is not enabled in this build.") }
  }

  // MARK: Contract verification

  /// Fetches and verifies everything shown before consent: config, pinned item bank, consent texts.
  func prepare() async throws -> ResearchPreparation {
    try requireEnabled()
    let config = try await client.config()
    guard config.researchEnabled else { throw ResearchContractError.unavailable("Research is not open yet.") }
    guard config.instrumentID == ResearchPins.instrumentID, config.bankSHA256 == ResearchPins.bankSHA256,
          config.itemCount == ResearchPins.itemCount else { throw ResearchContractError.hashMismatch }
    guard config.studyID != nil, config.batteryID != nil else { throw ResearchContractError.unavailable("No study is configured.") }
    let bank = try ResearchBankValidator.validate(try await client.itemBank(), expectedInstrumentID: ResearchPins.instrumentID,
                                                  pinnedSHA256: ResearchPins.bankSHA256, expectedItemCount: ResearchPins.itemCount)
    let texts = try ResearchConsentValidator.validate(try await client.consentTexts(locale: locale),
                                                      expectedPurposes: Set(config.purposes.map(\.consentType)), locale: locale)
    for text in texts where config.purposes.first(where: { $0.consentType == text.purpose })?.version != text.version {
      throw ResearchContractError.consent("\(text.purpose) version differs from the configured version")
    }
    let prepared = ResearchPreparation(config: config, bank: bank, consentTexts: texts)
    preparation = prepared
    return prepared
  }

  // MARK: Account

  func signIn(username: String, password: String) async throws {
    try requireEnabled()
    try await credentials.signIn(try await account.login(username: username, password: password))
  }

  func register(username: String, email: String, password: String) async throws {
    try requireEnabled()
    try await account.register(username: username, email: email, password: password)
    try await signIn(username: username, password: password)
  }

  func signOut() async throws { try await credentials.signOut() }

  // MARK: Enrolment

  /// Grants the accepted purposes (required ones must be included) and opens a session.
  /// Resumes an existing enrolment instead of creating a second participant or session.
  func enroll(accepted: Set<String>) async throws {
    try requireEnabled()
    guard let prepared = preparation else { throw ResearchContractError.unavailable("Prepare first.") }
    let missing = prepared.requiredPurposes.subtracting(accepted)
    guard missing.isEmpty else { throw ResearchContractError.requiredConsentMissing(missing.sorted().joined(separator: ", ")) }
    guard accepted.isSubset(of: Set(prepared.config.purposes.map(\.consentType))),
          let study = prepared.config.studyID, let battery = prepared.config.batteryID else {
      throw ResearchContractError.consent("unknown purpose")
    }
    let token = try await credentials.validAccessToken()
    if let existing = try progressStore.load(), existing.bankSHA256 == prepared.bank.sha256 {
      progress = existing
    } else {
      let participant = try await account.createParticipant(token: token)
      for purpose in accepted.sorted() {
        try await client.grantConsent(participantID: participant, purpose: purpose, locale: locale, token: token)
      }
      let status = try await client.consentStatus(participantID: participant, token: token)
      for purpose in prepared.requiredPurposes where status[purpose] != true {
        throw ResearchContractError.requiredConsentMissing(purpose)
      }
      let session = try await account.createSession(participantID: participant, studyID: study, batteryID: battery, token: token)
      progress = ResearchProgress(participantID: participant, sessionID: session, bankSHA256: prepared.bank.sha256,
                                  nextSeqNo: 0, answers: [:])
      try progressStore.save(progress!)
    }
    let current = progress!
    recorder = ResearchRecorder(bank: prepared.bank, clock: clock, resumeSeqNo: current.nextSeqNo, resumeAnswers: current.answers)
  }

  var isEnrolled: Bool { progress != nil }
  var answers: [Int: Int] { progress?.answers ?? [:] }

  // MARK: Questionnaire

  func show(itemID: Int) async throws {
    try requireEnabled()
    guard let recorder else { throw ResearchContractError.notEnrolled }
    try await recorder.present(itemID: itemID)
  }

  /// Records one answer from the verified bank into the durable outbox. Never uploads inline.
  func answer(itemID: Int, value: Int) async throws {
    try requireEnabled()
    guard let recorder, var current = progress else { throw ResearchContractError.notEnrolled }
    guard let event = try await recorder.record(itemID: itemID, value: value) else { return }
    _ = try await coordinator.enqueue(event, sessionID: current.sessionID, expectedBankSHA256: current.bankSHA256)
    current.answers[itemID] = value
    current.nextSeqNo = event.seqNo + 1
    progress = current
    try progressStore.save(current)
  }

  /// Number of answers not yet acknowledged by the server.
  func pendingCount() async throws -> Int {
    guard let current = progress else { return 0 }
    return try await coordinator.pendingCount(sessionID: current.sessionID)
  }

  /// Try to upload what is queued. Offline or failing uploads keep their data and back off.
  func sync() async -> DrainResult {
    guard capability.isEnabled, let current = progress else { return DrainResult() }
    return await coordinator.drain(sessionID: current.sessionID)
  }

  func recover() async throws -> [String] { try await coordinator.recover() }

  // MARK: Result

  /// Only after every event is server-verified: fetch allow-listed scores, then delete the local copy.
  func finish() async throws -> [DisplayedScore] {
    try requireEnabled()
    guard let recorder, let current = progress else { throw ResearchContractError.notEnrolled }
    guard await recorder.isComplete else { throw ResearchContractError.incomplete }
    _ = await coordinator.drain(sessionID: current.sessionID)
    let pending = try await coordinator.pendingCount(sessionID: current.sessionID)
    guard pending == 0 else { throw ResearchContractError.uploadsPending(pending) }
    let token = try await credentials.validAccessToken()
    let allowlist = try await client.scoreAllowlist()
    let scores = try allowlist.decode(scores: try await client.explorerResult(sessionID: current.sessionID, token: token))
    try progressStore.clear()
    progress = nil
    self.recorder = nil
    return scores
  }

  // MARK: Withdrawal and legacy data

  /// Revokes consent for the given purposes. Withdrawing research participation deletes local data.
  func withdraw(purposes: Set<String>) async throws {
    try requireEnabled()
    guard let current = progress else { throw ResearchContractError.notEnrolled }
    let token = try await credentials.validAccessToken()
    for purpose in purposes.sorted() {
      try await client.revokeConsent(participantID: current.participantID, purpose: purpose, token: token)
    }
    if purposes.contains("research_participation") || purposes.contains("product_use") {
      try await coordinator.discard(sessionID: current.sessionID)
      try progressStore.clear()
      progress = nil
      recorder = nil
    }
  }

  /// Explicit exclusion: nothing from a personal profile or pre-research backup can enter research.
  nonisolated func importLegacy(_ source: ResearchImportSource) throws {
    guard ResearchImportGate.admits(source) else { throw ResearchContractError.legacyImportBlocked }
  }
}
