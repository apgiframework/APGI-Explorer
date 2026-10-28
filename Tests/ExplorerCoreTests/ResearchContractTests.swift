import XCTest
@testable import ExplorerCore

final class ResearchContractTests: XCTestCase {
  private func bankData() throws -> Data { try Fixture.data("item-bank") }

  func testBankFromServerFixtureValidates() throws {
    let bank = try ResearchBankValidator.validate(try bankData(), expectedInstrumentID: "apgi-explorer-35")
    XCTAssertEqual(bank.items.count, 35)
    XCTAssertEqual(bank.item(7)?.scoring, "nominal")
    XCTAssertEqual(bank.sha256.count, 64)
  }

  func testBankRejectsTamperingAndStructuralDamage() throws {
    var root = try XCTUnwrap(Fixture.json("item-bank").object)
    func encode(_ object: [String: APIJSONValue]) throws -> Data { try JSONEncoder().encode(APIJSONValue.object(object)) }
    // Changed text, original hash.
    var items = try XCTUnwrap(root["items"]?.array)
    var first = try XCTUnwrap(items[0].object)
    first["text"] = .string("changed")
    items[0] = .object(first)
    var tampered = root
    tampered["items"] = .array(items)
    XCTAssertThrowsError(try ResearchBankValidator.validate(try encode(tampered), expectedInstrumentID: "apgi-explorer-35")) {
      XCTAssertEqual($0 as? ResearchContractError, .hashMismatch)
    }
    XCTAssertThrowsError(try ResearchBankValidator.validate(try bankData(), expectedInstrumentID: "other")) {
      XCTAssertEqual($0 as? ResearchContractError, .wrongInstrument)
    }
    root.removeValue(forKey: "sha256")
    XCTAssertThrowsError(try ResearchBankValidator.validate(try encode(root), expectedInstrumentID: "apgi-explorer-35"))
    XCTAssertThrowsError(try ResearchBankValidator.validate(Data("[]".utf8), expectedInstrumentID: "apgi-explorer-35"))
  }

  func testStructuralRulesWithRecomputedHash() throws {
    var root = try XCTUnwrap(Fixture.json("item-bank").object)
    root.removeValue(forKey: "sha256")
    var items = try XCTUnwrap(root["items"]?.array)
    items.removeLast()
    root["items"] = .array(items)
    root["sha256"] = .string(try CanonicalJSON.sha256Hex(.object(root.filter { $0.key != "sha256" })))
    XCTAssertThrowsError(try ResearchBankValidator.validate(try JSONEncoder().encode(APIJSONValue.object(root)), expectedInstrumentID: "apgi-explorer-35")) {
      guard case .invalidItems? = $0 as? ResearchContractError else { return XCTFail("\($0)") }
    }
  }

  private let purposes: Set<String> = ["product_use", "research_participation", "data_sharing", "recontact"]

  func testConsentValidationAcceptsFourApprovedLocaleVersionedTexts() throws {
    let texts = try ResearchConsentValidator.validate(try Fixture.json("consent-texts-approved-for-test"), expectedPurposes: purposes, locale: "en")
    XCTAssertEqual(Set(texts.map(\.purpose)), purposes)
  }

  func testConsentValidationRejections() throws {
    let good = try XCTUnwrap(Fixture.json("consent-texts-approved-for-test").array)
    func mutate(_ index: Int, _ key: String, _ value: APIJSONValue) -> APIJSONValue {
      var copy = good
      var object = copy[index].object!
      object[key] = value
      copy[index] = .object(object)
      return .array(copy)
    }
    XCTAssertThrowsError(try ResearchConsentValidator.validate(mutate(0, "status", .string("draft")), expectedPurposes: purposes, locale: "en"))
    XCTAssertThrowsError(try ResearchConsentValidator.validate(mutate(0, "body", .string("edited")), expectedPurposes: purposes, locale: "en"))
    XCTAssertThrowsError(try ResearchConsentValidator.validate(mutate(0, "locale", .string("fr")), expectedPurposes: purposes, locale: "en"))
    XCTAssertThrowsError(try ResearchConsentValidator.validate(mutate(0, "version", .string("")), expectedPurposes: purposes, locale: "en"))
    XCTAssertThrowsError(try ResearchConsentValidator.validate(.array(Array(good.dropLast())), expectedPurposes: purposes, locale: "en"))
    XCTAssertThrowsError(try ResearchConsentValidator.validate(.array(good), expectedPurposes: ["a", "b", "c"], locale: "en"))
    XCTAssertThrowsError(try ResearchConsentValidator.validate(mutate(1, "consent_type", good[0].object!["consent_type"]!), expectedPurposes: purposes, locale: "en"))
  }

  private final class FakeClock: MonotonicMicrosecondClock, @unchecked Sendable {
    private let lock = NSLock()
    private var value: Int64 = 1_000
    func nowMicroseconds() -> Int64 { lock.lock(); defer { lock.unlock() }; value += 250; return value }
  }

  func testRecorderUsesOnlyBankItemsAndIsMonotonic() async throws {
    let bank = try ResearchBankValidator.validate(try bankData(), expectedInstrumentID: "apgi-explorer-35")
    let recorder = ResearchRecorder(bank: bank, clock: FakeClock())
    do { try await recorder.present(itemID: 99); XCTFail() } catch { XCTAssertEqual(error as? ResearchContractError, .unknownItem(99)) }
    do { _ = try await recorder.record(itemID: 1, value: 2); XCTFail() } catch { XCTAssertEqual(error as? ResearchContractError, .itemNotPresented(1)) }
    try await recorder.present(itemID: 1)
    do { _ = try await recorder.record(itemID: 1, value: 5); XCTFail() } catch { XCTAssertEqual(error as? ResearchContractError, .invalidValue(5)) }
    let first = try await recorder.record(itemID: 1, value: 2)
    XCTAssertEqual(first?.seqNo, 0)
    XCTAssertEqual(first?.provenance, .research(bankSHA256: bank.sha256))
    let unchanged = try await recorder.record(itemID: 1, value: 2)
    XCTAssertNil(unchanged)
    let changed = try await recorder.record(itemID: 1, value: 3)
    XCTAssertEqual(changed?.seqNo, 1)
    XCTAssertEqual(changed?.payload.object?["previous_value"], .integer(2))
    XCTAssertEqual(changed?.payload.object?["instrument_sha256"]?.string, bank.sha256)
    let latency = try XCTUnwrap(changed?.payload.object?["latency_us"]?.int)
    XCTAssertGreaterThanOrEqual(latency, 0)
    let complete = await recorder.isComplete
    XCTAssertFalse(complete)
  }

  func testScoreDecodingRejectsUnknownUnapprovedAndNonnumeric() throws {
    let allowlist = try ScoreAllowlist(response: try Fixture.json("score-allowlist"))
    XCTAssertEqual(allowlist.labelsByField.count, 4)
    let good: APIJSONValue = .object(["scores": .object([
      "reported_attentional_threshold": .number(37.5), "reported_reactivity_to_the_unexpected": .integer(50)])])
    XCTAssertEqual(try allowlist.decode(scores: good).map(\.label), [ScoreLabels.reactivity, ScoreLabels.threshold])
    func bad(_ scores: [String: APIJSONValue]) { XCTAssertThrowsError(try allowlist.decode(scores: .object(["scores": .object(scores)]))) }
    bad(["interactions": .number(1)])
    bad(["reported_attentional_threshold": .string("37")])
    bad(["reported_attentional_threshold": .null])
    bad(["reported_attentional_threshold": .number(.infinity)])
    bad([:])
    XCTAssertThrowsError(try ScoreAllowlist(response: .object(["fields": .array([.object(["field": .string("x"), "label": .string("Somatic Bias (β)")])])])))
    XCTAssertThrowsError(try ScoreAllowlist(response: .object(["fields": .array([])])))
  }

  func testProductGateNeedsBothFlagAndBuildApproval() {
    XCTAssertFalse(ExplorerBuildApproval.paidProductsApproved)
    XCTAssertFalse(ProductEligibility.current(remoteValidationResults: true).isEligible)
    XCTAssertFalse(ProductEligibility(remoteValidationResults: false, buildApproved: true).isEligible)
    XCTAssertTrue(ProductEligibility(remoteValidationResults: true, buildApproved: true).isEligible)
    XCTAssertFalse(ProductEligibility.current(remoteValidationResults: nil).isEligible)
  }
}
