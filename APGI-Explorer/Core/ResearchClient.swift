import Foundation

nonisolated struct ResearchPurposeInfo: Equatable, Sendable {
  let consentType: String
  let version: String
  let status: String
  let requiredForResearch: Bool
}

nonisolated struct ResearchConfig: Equatable, Sendable {
  let researchEnabled: Bool
  let paidProductsEnabled: Bool
  let validationResults: Bool
  let instrumentID: String
  let bankVersion: String
  let bankSHA256: String
  let itemCount: Int
  let purposes: [ResearchPurposeInfo]
  let studyID: String?
  let batteryID: String?
}

private nonisolated func field(_ object: [String: APIJSONValue], _ key: String) throws -> APIJSONValue {
  guard let value = object[key] else { throw ResearchContractError.malformed("missing \(key)") }
  return value
}

private nonisolated func string(_ object: [String: APIJSONValue], _ key: String) throws -> String {
  guard let value = try field(object, key).string else { throw ResearchContractError.malformed("\(key) must be a string") }
  return value
}

private nonisolated func flag(_ object: [String: APIJSONValue], _ key: String) throws -> Bool {
  guard case .bool(let value) = try field(object, key) else { throw ResearchContractError.malformed("\(key) must be a Boolean") }
  return value
}

private nonisolated func operation(_ catalog: [String: APIOperation], _ id: String) throws -> APIOperation {
  guard let found = catalog[id] else { throw ResearchAdapterError.missingOperation }
  return found
}

/// Typed access to the Explorer research operations (see `contracts/explorer-research-v1.json`).
/// Responses are validated strictly; anything unexpected throws instead of being coerced.
nonisolated struct ExplorerResearchClient: Sendable {
  let transport: any OperationSending

  func config() async throws -> ResearchConfig {
    let op = try operation(ExplorerResearchOperations.byID, "get_explorer_config_v1_explorer_config_get")
    let root = try await transport.send(op, request: APIRequest(), authentication: .none)
    guard let object = root.object, let instrument = try field(object, "instrument").object,
          let purposes = try field(object, "consent_purposes").array else {
      throw ResearchContractError.malformed("config")
    }
    return ResearchConfig(
      researchEnabled: try flag(object, "research_enabled"),
      paidProductsEnabled: try flag(object, "paid_products_enabled"),
      validationResults: try flag(object, "validation_results"),
      instrumentID: try string(instrument, "instrument_id"),
      bankVersion: try string(instrument, "bank_version"),
      bankSHA256: try string(instrument, "sha256"),
      itemCount: try field(instrument, "item_count").int ?? -1,
      purposes: try purposes.map { entry in
        guard let fields = entry.object else { throw ResearchContractError.malformed("purpose") }
        return ResearchPurposeInfo(consentType: try string(fields, "consent_type"), version: try string(fields, "version"),
                                   status: try string(fields, "status"), requiredForResearch: try flag(fields, "required_for_research"))
      },
      studyID: object["study_id"]?.string, batteryID: object["battery_id"]?.string)
  }

  func consentTexts(locale: String) async throws -> APIJSONValue {
    let op = try operation(ExplorerResearchOperations.byID, "list_consent_texts_v1_consent_texts_get")
    return try await transport.send(op, request: APIRequest(query: ["locale": locale]), authentication: .none)
  }

  func itemBank() async throws -> APIJSONValue {
    try await transport.send(try operation(ExplorerResearchOperations.byID, "get_item_bank_v1_instruments_apgi_explorer_35_get"),
                             request: APIRequest(), authentication: .none)
  }

  func scoreAllowlist() async throws -> ScoreAllowlist {
    let op = try operation(ExplorerResearchOperations.byID, "get_score_allowlist_v1_instruments_apgi_explorer_35_score_allowlist_get")
    return try ScoreAllowlist(response: try await transport.send(op, request: APIRequest(), authentication: .none))
  }

  /// Omitting the text asks the server to record its own canonical text for the configured version.
  func grantConsent(participantID: String, purpose: String, locale: String, token: String) async throws {
    let op = try operation(ExplorerResearchOperations.byID, "grant_consent_v1_participants__participant_id__consents_post")
    _ = try await transport.send(op, request: APIRequest(
      pathParameters: ["participant_id": participantID],
      body: .object(["consent_type": .string(purpose), "locale": .string(locale)])), authentication: .bearer(token))
  }

  func revokeConsent(participantID: String, purpose: String, token: String) async throws {
    let op = try operation(ExplorerResearchOperations.byID, "revoke_consent_route_v1_participants__participant_id__consents_revoke_post")
    _ = try await transport.send(op, request: APIRequest(
      pathParameters: ["participant_id": participantID], body: .object(["consent_type": .string(purpose)])),
      authentication: .bearer(token))
  }

  func consentStatus(participantID: String, token: String) async throws -> [String: Bool] {
    let op = try operation(ExplorerResearchOperations.byID, "get_consent_status_v1_participants__participant_id__consents_status_get")
    let root = try await transport.send(op, request: APIRequest(pathParameters: ["participant_id": participantID]),
                                        authentication: .bearer(token))
    guard let object = root.object else { throw ResearchContractError.malformed("consent status") }
    return try object.mapValues { value in
      guard case .bool(let flag) = value else { throw ResearchContractError.malformed("consent status value") }
      return flag
    }
  }

  func explorerResult(sessionID: String, token: String) async throws -> APIJSONValue {
    let op = try operation(ExplorerResearchOperations.byID, "get_explorer_result_v1_participant_sessions__participant_session_id__explorer_result_get")
    return try await transport.send(op, request: APIRequest(pathParameters: ["participant_session_id": sessionID]),
                                    authentication: .bearer(token))
  }
}

/// Account, participant and session operations from the deployed v1 contract.
nonisolated struct ResearchAccountClient: Sendable {
  let transport: any OperationSending
  var now: @Sendable () -> Date = { Date() }

  private func credentials(from root: APIJSONValue, fallbackRefresh: String?) throws -> ResearchCredentials {
    guard let object = root.object, let access = object["access_token"]?.string, !access.isEmpty,
          let expires = object["expires_in"]?.int else { throw ResearchContractError.account("malformed token response") }
    let refresh = object["refresh_token"]?.string ?? fallbackRefresh
    guard let refresh, !refresh.isEmpty else { throw ResearchContractError.account("no refresh token issued") }
    return ResearchCredentials(accessToken: access, refreshToken: refresh, accessExpiry: now().addingTimeInterval(TimeInterval(expires)))
  }

  func login(username: String, password: String) async throws -> ResearchCredentials {
    let op = try operation(APGIOperations.byID, "login_v1_auth_login_post")
    let root = try await transport.send(op, request: APIRequest(
      body: .object(["username": .string(username), "password": .string(password)])), authentication: .none)
    return try credentials(from: root, fallbackRefresh: nil)
  }

  func register(username: String, email: String, password: String) async throws {
    let op = try operation(APGIOperations.byID, "register_user_v1_users_register_post")
    _ = try await transport.send(op, request: APIRequest(
      body: .object(["username": .string(username), "email": .string(email), "password": .string(password)])),
      authentication: .none)
  }

  func refresh(refreshToken: String) async throws -> ResearchCredentials {
    let op = try operation(APGIOperations.byID, "refresh_token_v1_auth_refresh_post")
    do {
      let root = try await transport.send(op, request: APIRequest(
        body: .object(["refresh_token": .string(refreshToken)])), authentication: .none)
      return try credentials(from: root, fallbackRefresh: nil)
    } catch APITransportError.http(let status) where status == 401 || status == 403 {
      throw ResearchCredentialError.refreshRejected
    }
  }

  /// Pseudonymous participant: no contact details or demographics are sent.
  func createParticipant(token: String) async throws -> String {
    let op = try operation(APGIOperations.byID, "create_participant_v1_participants_post")
    let root = try await transport.send(op, request: APIRequest(body: .object([:])), authentication: .bearer(token))
    guard let id = root.object?["participant_id"]?.string else { throw ResearchContractError.account("no participant id") }
    return id
  }

  func createSession(participantID: String, studyID: String, batteryID: String, token: String) async throws -> String {
    let op = try operation(APGIOperations.byID, "create_participant_session_v1_participant_sessions_post")
    let root = try await transport.send(op, request: APIRequest(body: .object([
      "participant_id": .string(participantID), "study_id": .string(studyID), "battery_id": .string(batteryID)])),
      authentication: .bearer(token))
    guard let id = root.object?["participant_session_id"]?.string else { throw ResearchContractError.account("no session id") }
    return id
  }
}

nonisolated struct APIResearchTokenRefresher: ResearchTokenRefreshing {
  let account: ResearchAccountClient
  func refresh(refreshToken: String) async throws -> ResearchCredentials {
    try await account.refresh(refreshToken: refreshToken)
  }
}
