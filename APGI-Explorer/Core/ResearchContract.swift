import Foundation

nonisolated enum ResearchContractError: Error, Equatable {
  case malformed(String)
  case hashMismatch
  case wrongInstrument
  case invalidItems(String)
  case consent(String)
  case unknownItem(Int)
  case invalidValue(Int)
  case itemNotPresented(Int)
  case nonResearchProvenance
  case bankMismatch
  case scoreField(String)
  case scoreMapping(String)
  case unavailable(String)
  case requiredConsentMissing(String)
  case uploadsPending(Int)
  case notEnrolled
  case incomplete
  case legacyImportBlocked
  case account(String)
}

// MARK: - Item bank

nonisolated struct ResearchItem: Equatable, Sendable {
  let id: Int
  let subscale: String
  let scoring: String
  let text: String
  let optionValues: [Int]
  let optionTexts: [Int: String]
}

nonisolated struct ResearchBank: Equatable, Sendable {
  let instrumentID: String
  let version: String
  let locale: String
  let sha256: String
  let items: [ResearchItem]

  func item(_ id: Int) -> ResearchItem? { items.first { $0.id == id } }
}

nonisolated enum ResearchBankValidator {
  /// Verifies the server-pinned bank: canonical-byte hash, instrument, 35 contiguous items,
  /// four ordered options each. Throws instead of repairing anything.
  static func validate(_ data: Data, expectedInstrumentID: String, pinnedSHA256: String,
                       expectedItemCount: Int = 35) throws -> ResearchBank {
    guard let value = try? JSONDecoder().decode(APIJSONValue.self, from: data) else {
      throw ResearchContractError.malformed("bank is not JSON")
    }
    return try validate(value, expectedInstrumentID: expectedInstrumentID, pinnedSHA256: pinnedSHA256,
                        expectedItemCount: expectedItemCount)
  }

  /// The hash must match both the bank's own canonical bytes and the hash pinned in this build.
  static func validate(_ value: APIJSONValue, expectedInstrumentID: String, pinnedSHA256: String,
                       expectedItemCount: Int = 35) throws -> ResearchBank {
    guard let root = value.object else { throw ResearchContractError.malformed("bank is not a JSON object") }
    guard let claimed = root["sha256"]?.string, claimed.count == 64 else { throw ResearchContractError.hashMismatch }
    guard claimed == pinnedSHA256 else { throw ResearchContractError.hashMismatch }
    var unsigned = root
    unsigned.removeValue(forKey: "sha256")
    let actual: String
    do { actual = try CanonicalJSON.sha256Hex(.object(unsigned)) } catch { throw ResearchContractError.hashMismatch }
    guard actual == claimed else { throw ResearchContractError.hashMismatch }
    guard let instrument = root["instrument_id"]?.string, instrument == expectedInstrumentID else {
      throw ResearchContractError.wrongInstrument
    }
    guard let version = root["bank_version"]?.string, !version.isEmpty,
          let locale = root["locale"]?.string, !locale.isEmpty,
          let rawItems = root["items"]?.array else { throw ResearchContractError.malformed("missing bank fields") }
    guard rawItems.count == expectedItemCount else { throw ResearchContractError.invalidItems("expected \(expectedItemCount) items") }

    var items: [ResearchItem] = []
    for (index, raw) in rawItems.enumerated() {
      guard let fields = raw.object, let id = fields["item_id"]?.int, id == index + 1 else {
        throw ResearchContractError.invalidItems("item ids must run 1...\(expectedItemCount) in order")
      }
      guard let text = fields["text"]?.string, !text.trimmingCharacters(in: .whitespaces).isEmpty,
            let subscale = fields["subscale"]?.string, !subscale.isEmpty,
            let scoring = fields["scoring"]?.string, ["ordinal", "nominal"].contains(scoring),
            let options = fields["options"]?.array, options.count == 4 else {
        throw ResearchContractError.invalidItems("item \(id) is incomplete")
      }
      var texts: [Int: String] = [:]
      for (optionIndex, option) in options.enumerated() {
        guard let optionFields = option.object, optionFields["value"]?.int == optionIndex + 1,
              let optionText = optionFields["text"]?.string, !optionText.isEmpty else {
          throw ResearchContractError.invalidItems("item \(id) options must be values 1...4 with text")
        }
        texts[optionIndex + 1] = optionText
      }
      items.append(ResearchItem(id: id, subscale: subscale, scoring: scoring, text: text,
                                optionValues: [1, 2, 3, 4], optionTexts: texts))
    }
    return ResearchBank(instrumentID: instrument, version: version, locale: locale, sha256: claimed, items: items)
  }
}

// MARK: - Consent

nonisolated struct ResearchConsentText: Equatable, Sendable {
  let purpose: String
  let version: String
  let locale: String
  let title: String
  let body: String
}

nonisolated enum ResearchConsentValidator {
  /// Purposes and texts come from the reviewed server contract. `expectedPurposes` is that
  /// contract's list (four purposes); nothing is hard-coded or substituted locally.
  static func validate(_ response: APIJSONValue, expectedPurposes: Set<String>,
                       locale: String) throws -> [ResearchConsentText] {
    guard expectedPurposes.count == 4 else { throw ResearchContractError.consent("contract must name four purposes") }
    guard let list = response.array else { throw ResearchContractError.consent("texts must be an array") }
    var seen: Set<String> = []
    var texts: [ResearchConsentText] = []
    for entry in list {
      guard let fields = entry.object, let purpose = fields["consent_type"]?.string,
            let version = fields["version"]?.string, !version.isEmpty,
            let entryLocale = fields["locale"]?.string, let status = fields["status"]?.string,
            let title = fields["title"]?.string, let body = fields["body"]?.string, !body.isEmpty,
            let digest = fields["sha256"]?.string else { throw ResearchContractError.consent("incomplete consent text") }
      guard entryLocale == locale else { throw ResearchContractError.consent("locale mismatch for \(purpose)") }
      guard status == "approved" else { throw ResearchContractError.consent("\(purpose) is not approved") }
      guard PortableSHA256.hexDigest(body) == digest else { throw ResearchContractError.consent("\(purpose) text hash mismatch") }
      guard seen.insert(purpose).inserted else { throw ResearchContractError.consent("duplicate purpose \(purpose)") }
      texts.append(ResearchConsentText(purpose: purpose, version: version, locale: entryLocale, title: title, body: body))
    }
    guard seen == expectedPurposes else { throw ResearchContractError.consent("purposes differ from the contract") }
    return texts
  }
}

// MARK: - Recording

nonisolated enum ResearchProvenance: Equatable, Sendable {
  case research(bankSHA256: String)
  case personal
  case legacyImport
}

nonisolated struct ResearchAnswerEvent: Equatable, Sendable {
  let seqNo: Int
  let provenance: ResearchProvenance
  let payload: APIJSONValue
}

nonisolated protocol MonotonicMicrosecondClock: Sendable {
  func nowMicroseconds() -> Int64
}

nonisolated struct ContinuousMicrosecondClock: MonotonicMicrosecondClock {
  private let origin = ContinuousClock.now
  func nowMicroseconds() -> Int64 {
    let parts = origin.duration(to: ContinuousClock.now).components
    return parts.seconds * 1_000_000 + parts.attoseconds / 1_000_000_000_000
  }
}

/// Records research answers using only items from the supplied server bank. Sequence numbers
/// increase by one, latency is monotonic, and values must be an option of that item.
actor ResearchRecorder {
  private let bank: ResearchBank
  private let clock: MonotonicMicrosecondClock
  private var nextSeq = 0
  private var answers: [Int: Int] = [:]
  private var presentedAt: [Int: Int64] = [:]

  init(bank: ResearchBank, clock: MonotonicMicrosecondClock = ContinuousMicrosecondClock(),
       resumeSeqNo: Int = 0, resumeAnswers: [Int: Int] = [:]) {
    self.bank = bank
    self.clock = clock
    self.nextSeq = resumeSeqNo
    self.answers = resumeAnswers.filter { bank.item($0.key)?.optionValues.contains($0.value) == true }
  }

  var answered: [Int: Int] { answers }
  var nextSequence: Int { nextSeq }

  func present(itemID: Int) throws {
    guard bank.item(itemID) != nil else { throw ResearchContractError.unknownItem(itemID) }
    presentedAt[itemID] = clock.nowMicroseconds()
  }

  /// Returns nil when the value is unchanged (nothing to journal).
  func record(itemID: Int, value: Int) throws -> ResearchAnswerEvent? {
    guard let item = bank.item(itemID) else { throw ResearchContractError.unknownItem(itemID) }
    guard item.optionValues.contains(value) else { throw ResearchContractError.invalidValue(value) }
    guard let shown = presentedAt[itemID] else { throw ResearchContractError.itemNotPresented(itemID) }
    let previous = answers[itemID]
    guard previous != value else { return nil }
    var payload: [String: APIJSONValue] = [
      "item_id": .integer(Int64(itemID)),
      "value": .integer(Int64(value)),
      "latency_us": .integer(max(0, clock.nowMicroseconds() - shown)),
      "instrument_sha256": .string(bank.sha256)
    ]
    if let previous { payload["previous_value"] = .integer(Int64(previous)) }
    answers[itemID] = value
    presentedAt[itemID] = clock.nowMicroseconds()
    defer { nextSeq += 1 }
    return ResearchAnswerEvent(seqNo: nextSeq, provenance: .research(bankSHA256: bank.sha256), payload: .object(payload))
  }

  var isComplete: Bool { Set(answers.keys) == Set(bank.items.map(\.id)) }
}

extension UploadCoordinator {
  /// Only events recorded against the pinned research bank may enter the outbox; personal
  /// journals and legacy imports are rejected.
  func enqueue(_ event: ResearchAnswerEvent, sessionID: String, expectedBankSHA256: String) async throws -> EnqueueResult {
    guard case .research(let sha) = event.provenance else { throw ResearchContractError.nonResearchProvenance }
    guard sha == expectedBankSHA256 else { throw ResearchContractError.bankMismatch }
    return try await enqueue(sessionID: sessionID, seqNo: event.seqNo, payload: event.payload)
  }
}

// MARK: - Scores

nonisolated struct DisplayedScore: Equatable, Sendable {
  let label: String
  let value: Double
}

/// Displays only server-returned, allow-listed numeric scores under approved labels.
nonisolated struct ScoreAllowlist: Equatable, Sendable {
  let labelsByField: [String: String]

  init(response: APIJSONValue) throws {
    guard let entries = response.object?["fields"]?.array, !entries.isEmpty else {
      throw ResearchContractError.scoreMapping("allow-list is empty")
    }
    var mapping: [String: String] = [:]
    for entry in entries {
      guard let fields = entry.object, let field = fields["field"]?.string, !field.isEmpty,
            let label = fields["label"]?.string else { throw ResearchContractError.scoreMapping("malformed entry") }
      guard ScoreLabels.approved.contains(label) else { throw ResearchContractError.scoreMapping("unapproved label \(label)") }
      guard mapping.updateValue(label, forKey: field) == nil else { throw ResearchContractError.scoreMapping("duplicate field \(field)") }
      mapping[field] = label
    }
    labelsByField = mapping
  }

  func decode(scores response: APIJSONValue) throws -> [DisplayedScore] {
    guard let scores = response.object?["scores"]?.object, !scores.isEmpty else {
      throw ResearchContractError.scoreField("no scores returned")
    }
    var displayed: [DisplayedScore] = []
    for (field, raw) in scores {
      guard let label = labelsByField[field] else { throw ResearchContractError.scoreField("unknown field \(field)") }
      let number: Double
      switch raw {
      case .number(let value): number = value
      case .integer(let value): number = Double(value)
      default: throw ResearchContractError.scoreField("\(field) is not numeric")
      }
      guard number.isFinite else { throw ResearchContractError.scoreField("\(field) is not finite") }
      displayed.append(DisplayedScore(label: label, value: number))
    }
    return displayed.sorted {
      (ScoreLabels.approved.firstIndex(of: $0.label) ?? .max) < (ScoreLabels.approved.firstIndex(of: $1.label) ?? .max)
    }
  }
}
