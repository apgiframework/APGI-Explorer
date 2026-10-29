import Foundation
@testable import ExplorerCore
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// In-memory stand-in for the apgi-api Explorer contract (a simulation, not the live server):
/// idempotent journal upload keyed by event id and sequence, hash re-verification, consent
/// bookkeeping and allow-listed scores. Used to exercise the client workflow end to end.
final class FakeResearchServer: OperationSending, @unchecked Sendable {
  struct Stored { let eventID: String; let seqNo: Int; let digest: String; let payload: APIJSONValue }

  private let lock = NSLock()
  var online = true
  /// Process the next upload but lose its response (the client must retry safely).
  var dropNextUploadResponse = false
  var researchEnabled = true
  var bankSHA256 = ResearchPins.bankSHA256
  private(set) var requests: [String] = []
  private(set) var stored: [Stored] = []
  private(set) var uploadCalls = 0
  private(set) var granted: Set<String> = []
  private(set) var participantsCreated = 0
  private(set) var sessionsCreated = 0
  private(set) var revoked: Set<String> = []
  private let bank: APIJSONValue
  private let texts: [APIJSONValue]
  private let allowlist: APIJSONValue

  init() throws {
    bank = try Fixture.json("item-bank")
    guard let list = try Fixture.json("consent-texts-approved-for-test").array else { throw CocoaError(.coderInvalidValue) }
    texts = list
    allowlist = try Fixture.json("score-allowlist")
  }

  var storedSeqNos: [Int] { lock.withLock { stored.map(\.seqNo).sorted() } }

  func send(_ operation: APIOperation, request: APIRequest, authentication: APIAuthentication) async throws -> APIJSONValue {
    let body = request.body?.object
    return try lock.withLock { () throws -> APIJSONValue in
      requests.append(operation.id)
      if !online { throw URLError(.notConnectedToInternet) }
      if operation.requiresAuthentication, case .none = authentication { throw APITransportError.authenticationRequired }
      switch operation.id {
      case "get_explorer_config_v1_explorer_config_get":
        return .object([
          "research_enabled": .bool(researchEnabled), "paid_products_enabled": .bool(false), "validation_results": .bool(false),
          "instrument": .object(["instrument_id": .string(ResearchPins.instrumentID), "bank_version": .string("1.0.0"),
                                 "sha256": .string(bankSHA256), "item_count": .integer(35)]),
          "consent_purposes": .array(texts.map { text in
            let t = text.object!
            return .object(["consent_type": t["consent_type"]!, "version": t["version"]!, "status": t["status"]!,
                            "required_for_research": t["required_for_research"]!])
          }),
          "study_id": .string("study-1"), "battery_id": .string("battery-1")])
      case "list_consent_texts_v1_consent_texts_get": return .array(texts)
      case "get_item_bank_v1_instruments_apgi_explorer_35_get": return bank
      case "get_score_allowlist_v1_instruments_apgi_explorer_35_score_allowlist_get": return allowlist
      case "login_v1_auth_login_post":
        return .object(["access_token": .string("access-1"), "refresh_token": .string("refresh-1"),
                        "token_type": .string("bearer"), "expires_in": .integer(3600)])
      case "refresh_token_v1_auth_refresh_post":
        return .object(["access_token": .string("access-2"), "refresh_token": .string("refresh-2"),
                        "token_type": .string("bearer"), "expires_in": .integer(3600)])
      case "create_participant_v1_participants_post":
        participantsCreated += 1
        return .object(["participant_id": .string("participant-\(participantsCreated)")])
      case "create_participant_session_v1_participant_sessions_post":
        sessionsCreated += 1
        return .object(["participant_session_id": .string("session-\(sessionsCreated)")])
      case "grant_consent_v1_participants__participant_id__consents_post":
        if let purpose = body?["consent_type"]?.string { granted.insert(purpose) }
        return .object([:])
      case "revoke_consent_route_v1_participants__participant_id__consents_revoke_post":
        if let purpose = body?["consent_type"]?.string { revoked.insert(purpose); granted.remove(purpose) }
        return .null
      case "get_consent_status_v1_participants__participant_id__consents_status_get":
        return .object(Dictionary(uniqueKeysWithValues: ["product_use", "research_participation", "data_sharing", "recontact"]
          .map { ($0, APIJSONValue.bool(granted.contains($0))) }))
      case ExplorerResearchAdapter.uploadOperationID:
        uploadCalls += 1
        guard granted.isSuperset(of: ["product_use", "research_participation"]) else { throw APITransportError.http(403) }
        var acks: [APIJSONValue] = []
        for event in body?["events"]?.array ?? [] {
          guard let e = event.object, let id = e["event_id"]?.string, let seq = e["seq_no"]?.int,
                let digest = e["payload_sha256"]?.string, let payload = e["payload"] else { throw APITransportError.http(422) }
          guard try CanonicalJSON.sha256Hex(payload) == digest else { throw APITransportError.http(422) }
          if let existing = stored.first(where: { $0.eventID == id || $0.seqNo == seq }) {
            guard existing.eventID == id, existing.seqNo == seq, existing.digest == digest else { throw APITransportError.http(409) }
            acks.append(ack(id, seq, digest, "duplicate"))
          } else {
            stored.append(Stored(eventID: id, seqNo: seq, digest: digest, payload: payload))
            acks.append(ack(id, seq, digest, "accepted"))
          }
        }
        if dropNextUploadResponse {
          dropNextUploadResponse = false
          throw URLError(.networkConnectionLost)
        }
        return .object(["acks": .array(acks)])
      case "get_explorer_result_v1_participant_sessions__participant_session_id__explorer_result_get":
        var latest: [Int: Int] = [:]
        for event in stored.sorted(by: { $0.seqNo < $1.seqNo }) {
          if let item = event.payload.object?["item_id"]?.int, let value = event.payload.object?["value"]?.int { latest[item] = value }
        }
        guard latest.count == 35 else { throw APITransportError.http(409) }
        func mean(_ ids: ClosedRange<Int>) -> Double {
          let ordinal = ids.filter { $0 != 7 && $0 != 9 }
          return ordinal.reduce(0.0) { $0 + (Double(latest[$1]!) - 0.5) * 25 } / Double(ordinal.count)
        }
        return .object(["scores": .object([
          "reported_reactivity_to_the_unexpected": .number(mean(1...5)),
          "reported_information_prioritisation": .number(mean(6...10)),
          "reported_attentional_threshold": .number(mean(11...15)),
          "reported_body_signal_attention": .number(mean(16...20))])])
      default:
        throw APITransportError.http(404)
      }
    }
  }

  private func ack(_ id: String, _ seq: Int, _ digest: String, _ status: String) -> APIJSONValue {
    .object(["event_id": .string(id), "seq_no": .integer(Int64(seq)), "payload_sha256": .string(digest),
             "status": .string(status), "server_verified": .bool(true)])
  }
}
