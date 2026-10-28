import Foundation

/// Anything that can send a catalog operation: the foreground `APITransport`, or a
/// background-session transport. Both share the same request builder, so redirect
/// and authentication rules cannot diverge.
nonisolated protocol OperationSending: Sendable {
  func send(_ operation: APIOperation, request: APIRequest, authentication: APIAuthentication) async throws -> APIJSONValue
}

extension APITransport: OperationSending {}

nonisolated enum ResearchAdapterError: Error, Equatable { case malformedAcknowledgement, missingOperation }

/// Maps outbox envelopes onto the `apgi-api` journal-upload operation described in
/// `contracts/explorer-research-v1.json`. That contract is not deployed yet; this
/// adapter is only reachable while `ResearchCapability.isEnabled` is true.
nonisolated struct ExplorerResearchAdapter: ResearchUploadAdapter {
  static let uploadOperationID = "upload_journal_events_v1_participant_sessions__participant_session_id__events_post"
  let transport: any OperationSending

  func upload(sessionID: String, events: [UploadEnvelope], authorization: String) async throws -> [UploadAcknowledgement] {
    guard let operation = ExplorerResearchOperations.byID[Self.uploadOperationID] else {
      throw ResearchAdapterError.missingOperation
    }
    let wire: [APIJSONValue] = try events.map { envelope in
      .object([
        "event_id": .string(envelope.eventKey),
        "seq_no": .integer(Int64(envelope.seqNo)),
        "payload": try JSONDecoder().decode(APIJSONValue.self, from: envelope.payload),
        "payload_sha256": .string(envelope.payloadDigest)
      ])
    }
    let response = try await transport.send(
      operation,
      request: APIRequest(pathParameters: ["participant_session_id": sessionID],
                          body: .object(["events": .array(wire)])),
      authentication: .bearer(authorization))
    guard let acks = response.object?["acks"]?.array else { throw ResearchAdapterError.malformedAcknowledgement }
    return try acks.map { item in
      guard let fields = item.object, let key = fields["event_id"]?.string,
            let seq = fields["seq_no"]?.int, let digest = fields["payload_sha256"]?.string,
            case .bool(let verified)? = fields["server_verified"] else {
        throw ResearchAdapterError.malformedAcknowledgement
      }
      return UploadAcknowledgement(eventKey: key, seqNo: seq, payloadDigest: digest, serverVerified: verified)
    }
  }
}
