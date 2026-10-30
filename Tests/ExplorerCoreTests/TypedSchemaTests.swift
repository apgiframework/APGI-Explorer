import XCTest
@testable import ExplorerCore

/// Decode/encode tests for the generated research models (`ResearchSchemas+Generated.swift`).
/// Samples in `Fixtures/typed-research-samples.json` carry every field; the item bank and consent
/// texts additionally decode the full server fixtures.
final class TypedSchemaTests: XCTestCase {
  typealias Schema = ExplorerResearchSchema

  /// Replies with canned JSON and records what was sent.
  final class StubSender: OperationSending, @unchecked Sendable {
    private let lock = NSLock()
    private var log: [(id: String, request: APIRequest, authentication: APIAuthentication)] = []
    let reply: APIJSONValue
    init(reply: APIJSONValue) { self.reply = reply }
    var calls: [(id: String, request: APIRequest, authentication: APIAuthentication)] { lock.withLock { log } }
    func send(_ operation: APIOperation, request: APIRequest, authentication: APIAuthentication) async throws -> APIJSONValue {
      lock.withLock { log.append((operation.id, request, authentication)) }
      return reply
    }
  }

  private func entry(_ id: String) throws -> (request: APIJSONValue?, response: APIJSONValue) {
    let all = try XCTUnwrap(Fixture.json("typed-research-samples").object)
    let fields = try XCTUnwrap(all[id]?.object, "no sample for \(id)")
    return (fields["request"], fields["response"] ?? .null)
  }

  /// Decodes the sample request and response through the typed binding and checks that re-encoding
  /// reproduces the sample exactly (nothing dropped, renamed or coerced).
  @discardableResult
  private func roundTrip<Q: Codable & Sendable, R: Codable & Sendable>(
    _ operation: TypedOperation<Q, R>, file: StaticString = #filePath, line: UInt = #line
  ) throws -> (request: Q?, response: R) {
    let sample = try entry(operation.operationID)
    var request: Q?
    if let wire = sample.request {
      let typed = try TypedCodec.decode(Q.self, from: wire)
      XCTAssertEqual(try TypedCodec.json(typed), wire, "request \(operation.operationID)", file: file, line: line)
      request = typed
    }
    let response = try TypedCodec.decode(R.self, from: sample.response)
    if R.self != NoContent.self {
      XCTAssertEqual(try TypedCodec.json(response), sample.response, "response \(operation.operationID)", file: file, line: line)
    }
    return (request, response)
  }

  func testEveryResearchOperationIsBoundToTypes() {
    let bound = Set(ExplorerResearchTypedOperations.operationIDs)
    XCTAssertEqual(bound.count, 10)
    XCTAssertEqual(bound, Set(ExplorerResearchOperations.all.map(\.id)))
    for id in bound { XCTAssertNotNil(ExplorerResearchOperations.byID[id], id) }
  }

  func testTokenRefresh() throws {
    let (request, response) = try roundTrip(ExplorerResearchTypedOperations.refreshToken)
    XCTAssertEqual(request?.refreshToken, "r0")
    XCTAssertEqual(response.accessToken, "a1")
    XCTAssertEqual(response.refreshToken, "r1")
    XCTAssertEqual(response.expiresIn, 1800)
    XCTAssertEqual(response.refreshExpiresIn, 604_800)
    XCTAssertEqual(response.tokenType, "bearer")
  }

  func testConfig() throws {
    let (_, config) = try roundTrip(ExplorerResearchTypedOperations.getExplorerConfig)
    XCTAssertFalse(config.researchEnabled)
    XCTAssertFalse(config.paidProductsEnabled)
    XCTAssertEqual(config.instrument.itemCount, 35)
    XCTAssertEqual(config.instrument.sha256, ResearchPins.bankSHA256)
    XCTAssertEqual(config.consentPurposes.map(\.consentType), ["product_use", "recontact"])
    XCTAssertEqual(config.studyID, "study-1")
    XCTAssertEqual(config.batteryID, "battery-1")
  }

  func testConfigDefaultsAndNullsWhenOptionalFieldsAreAbsent() throws {
    let minimal: APIJSONValue = .object([
      "research_enabled": .bool(true),
      "instrument": .object(["instrument_id": .string("x"), "bank_version": .string("1"), "sha256": .string("h"), "item_count": .integer(1)]),
      "consent_purposes": .array([]), "study_id": .null])
    let config = try TypedCodec.decode(Schema.ExplorerConfigResponse.self, from: minimal)
    XCTAssertTrue(config.researchEnabled)
    XCTAssertFalse(config.paidProductsEnabled, "contract default")
    XCTAssertFalse(config.validationResults, "contract default")
    XCTAssertNil(config.studyID)
    XCTAssertNil(config.batteryID)
  }

  func testConsentTextsAndTheFullServerFixture() throws {
    try roundTrip(ExplorerResearchTypedOperations.listConsentTexts)
    let texts = try TypedCodec.decode([Schema.ConsentTextResponse].self, from: Fixture.json("consent-texts-approved-for-test"))
    XCTAssertEqual(texts.count, 4)
    XCTAssertEqual(Set(texts.map(\.consentType)), ["product_use", "research_participation", "data_sharing", "recontact"])
    XCTAssertTrue(texts.allSatisfy { $0.status == "approved" && $0.sha256.count == 64 })
  }

  func testItemBankSampleAndFullServerFixture() throws {
    try roundTrip(ExplorerResearchTypedOperations.getItemBank)
    let bank = try TypedCodec.decode(Schema.ItemBankResponse.self, from: Fixture.json("item-bank"))
    XCTAssertEqual(bank.instrumentID, ResearchPins.instrumentID)
    XCTAssertEqual(bank.sha256, ResearchPins.bankSHA256)
    XCTAssertEqual(bank.items.count, 35)
    XCTAssertEqual(bank.items.filter { $0.scoring == .nominal }.map(\.itemID), [7, 9])
    XCTAssertTrue(bank.items.allSatisfy { $0.options.map(\.value) == [1, 2, 3, 4] })
  }

  func testScoreAllowlist() throws {
    let (_, allowlist) = try roundTrip(ExplorerResearchTypedOperations.getScoreAllowlist)
    XCTAssertEqual(allowlist.instrumentID, "apgi-explorer-35")
    XCTAssertEqual(allowlist.fields.first?.label, ScoreLabels.reactivity)
  }

  func testUploadRequestAndAcknowledgements() throws {
    let (request, response) = try roundTrip(ExplorerResearchTypedOperations.uploadJournalEvents)
    XCTAssertEqual(request?.events.count, 1)
    XCTAssertEqual(request?.events.first?.payload["item_id"], APIJSONValue.integer(1))
    XCTAssertEqual(response.acks.map(\.status), [.accepted, .duplicate])
    XCTAssertTrue(response.acks.allSatisfy(\.serverVerified))
  }

  func testExplorerResultScoresAreNumbers() throws {
    let (_, result) = try roundTrip(ExplorerResearchTypedOperations.getExplorerResult)
    XCTAssertEqual(result.scores["reported_reactivity_to_the_unexpected"], 62.5)
    XCTAssertTrue(result.excludedFromNorms)
    XCTAssertEqual(result.analysisMode, "exploratory")
    XCTAssertEqual(result.instrumentSha256, ResearchPins.bankSHA256)
  }

  func testGrantConsentRequestAndResponse() throws {
    let (request, response) = try roundTrip(ExplorerResearchTypedOperations.grantConsent)
    XCTAssertEqual(request?.consentType, .researchParticipation)
    XCTAssertEqual(response.consentType, .researchParticipation)
    XCTAssertNil(response.revokedAt)
    let revoked = try TypedCodec.decode(Schema.ConsentResponse.self, from: .object([
      "consent_id": .string("c"), "consent_type": .string("recontact"), "version": .string("1"),
      "granted_at": .string("2026-10-30T01:00:00Z"), "revoked_at": .string("2026-10-30T02:00:00Z")]))
    XCTAssertEqual(revoked.revokedAt, "2026-10-30T02:00:00Z")
  }

  func testGrantRequestEncodesSnakeCaseWithServerDefaultsAndOmitsNil() throws {
    let wire = try TypedCodec.json(Schema.ConsentGrantRequest(consentType: .dataSharing))
    XCTAssertEqual(wire, .object(["consent_type": .string("data_sharing"), "locale": .string("en")]))
    XCTAssertEqual(Schema.ConsentType.allCases.map(\.rawValue),
                   ["product_use", "research_participation", "data_sharing", "recontact"])
  }

  func testRevokeAndConsentStatus() throws {
    let (request, response) = try roundTrip(ExplorerResearchTypedOperations.revokeConsentRoute)
    XCTAssertEqual(request?.consentType, .recontact)
    XCTAssertEqual(response, NoContent())
    let (_, status) = try roundTrip(ExplorerResearchTypedOperations.getConsentStatus)
    XCTAssertTrue(status.productUse)
    XCTAssertTrue(status.researchParticipation)
    XCTAssertFalse(status.dataSharing)
    XCTAssertFalse(status.recontact)
    let defaults = try TypedCodec.decode(Schema.ConsentStatusResponse.self,
                                         from: .object(["research_participation": .bool(true), "data_sharing": .bool(false)]))
    XCTAssertFalse(defaults.productUse, "contract default")
    XCTAssertFalse(defaults.recontact, "contract default")
  }

  func testStrictDecodingRejectsMissingWrongTypedAndUnknownValues() throws {
    func fails<T: Decodable>(_ type: T.Type, _ value: APIJSONValue, _ note: String) {
      XCTAssertThrowsError(try TypedCodec.decode(type, from: value), note) { XCTAssertTrue($0 is DecodingError, "\(note): \($0)") }
    }
    fails(Schema.TokenRefreshResponse.self, .object(["access_token": .string("a")]), "missing required fields")
    fails(Schema.ConsentStatusResponse.self,
          .object(["research_participation": .string("yes"), "data_sharing": .bool(false)]), "wrong type")
    fails(Schema.ConsentGrantRequest.self, .object(["consent_type": .string("marketing")]), "unknown consent purpose")
    fails(Schema.EventAck.self, .object(["event_id": .string("e"), "seq_no": .integer(0), "payload_sha256": .string("h"),
                                         "status": .string("rejected"), "server_verified": .bool(true)]), "unknown ack status")
    fails(Schema.BankItem.self, .object(["item_id": .number(1.5), "subscale": .string("s"), "scoring": .string("ordinal"),
                                         "text": .string("t"), "options": .array([])]), "fractional item id")
    fails([Schema.ConsentTextResponse].self, .object([:]), "array expected")
  }

  func testErrorEnvelopes() throws {
    let error = try TypedCodec.decode(Schema.ErrorResponse.self, from: .object(["error": .object([
      "code": .string("FORBIDDEN"), "message": .string("Missing or outdated consent"),
      "timestamp": .string("2026-10-30T01:00:00Z"), "details": .object(["purpose": .string("product_use")])])]))
    XCTAssertEqual(error.error.code, "FORBIDDEN")
    XCTAssertEqual(error.error.details?["purpose"], APIJSONValue.string("product_use"))
    let validation = try TypedCodec.decode(Schema.HTTPValidationError.self, from: .object(["detail": .array([.object([
      "loc": .array([.string("body"), .integer(0), .string("events")]), "msg": .string("Field required"),
      "type": .string("missing")])])]))
    let expectedLocation: [APIJSONValue] = [.string("body"), .integer(0), .string("events")]
    XCTAssertEqual(validation.detail?.first?.loc, expectedLocation)
    XCTAssertNil(validation.detail?.first?.input)
  }

  func testSendTypedEncodesBodyDecodesResponseAndKeepsAuthenticationExplicit() async throws {
    let sample = try entry(ExplorerResearchTypedOperations.getConsentStatus.operationID)
    let sender = StubSender(reply: sample.response)
    let status = try await sender.sendTyped(ExplorerResearchTypedOperations.getConsentStatus,
                                            pathParameters: ["participant_id": "p1"], authentication: .bearer("tok"))
    XCTAssertTrue(status.researchParticipation)
    let call = try XCTUnwrap(sender.calls.first)
    XCTAssertEqual(call.id, ExplorerResearchTypedOperations.getConsentStatus.operationID)
    XCTAssertEqual(call.request.pathParameters, ["participant_id": "p1"])
    XCTAssertNil(call.request.body, "operations without a body send none")
    XCTAssertEqual(call.authentication, .bearer("tok"))

    let revoker = StubSender(reply: .null)
    let done = try await revoker.sendTyped(ExplorerResearchTypedOperations.revokeConsentRoute,
                                           pathParameters: ["participant_id": "p1"],
                                           body: Schema.ConsentRevokeRequest(consentType: .dataSharing), authentication: .bearer("tok"))
    XCTAssertEqual(done, NoContent())
    let expectedBody: APIJSONValue = .object(["consent_type": .string("data_sharing")])
    XCTAssertEqual(revoker.calls.first?.request.body, expectedBody)
  }

  func testSendTypedSurfacesContractViolationsAsDecodingErrors() async throws {
    let sender = StubSender(reply: .object(["unexpected": .bool(true)]))
    do {
      _ = try await sender.sendTyped(ExplorerResearchTypedOperations.getExplorerConfig)
      XCTFail("a response that breaks the contract must not be accepted")
    } catch { XCTAssertTrue(error is DecodingError) }
  }
}
