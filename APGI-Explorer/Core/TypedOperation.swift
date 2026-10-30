import Foundation

/// Request marker for operations without a body.
nonisolated struct NoBody: Codable, Equatable, Sendable {}

/// Response marker for 204 operations. Accepts whatever the transport yields (normally `null`).
nonisolated struct NoContent: Codable, Equatable, Sendable {
  init() {}
  init(from decoder: Decoder) throws {}
  func encode(to encoder: Encoder) throws {}
}

/// An operation of the Explorer research catalog bound to its request and response models.
/// The bindings are generated (`ExplorerResearchTypedOperations`); this type only carries the ID.
nonisolated struct TypedOperation<Request: Encodable & Sendable, Response: Decodable & Sendable>: Sendable {
  let operationID: String

  func resolve() throws -> APIOperation {
    guard let found = ExplorerResearchOperations.byID[operationID] else { throw ResearchAdapterError.missingOperation }
    return found
  }
}

/// Conversions between typed models and the lossless JSON used by the transport.
nonisolated enum TypedCodec {
  static func json<T: Encodable>(_ value: T) throws -> APIJSONValue {
    try JSONDecoder().decode(APIJSONValue.self, from: JSONEncoder().encode(value))
  }

  /// Strict: a missing required field, a wrong type or an unknown enum value throws `DecodingError`.
  static func decode<T: Decodable>(_ type: T.Type, from value: APIJSONValue) throws -> T {
    try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
  }
}

nonisolated extension OperationSending {
  func sendTyped<Request, Response>(
    _ operation: TypedOperation<Request, Response>, pathParameters: [String: String] = [:],
    query: [String: String] = [:], body: Request? = nil, authentication: APIAuthentication = .none
  ) async throws -> Response {
    let catalogued = try operation.resolve()
    let wire = try body.map { try TypedCodec.json($0) }
    let raw = try await send(catalogued, request: APIRequest(pathParameters: pathParameters, query: query, body: wire),
                             authentication: authentication)
    return try TypedCodec.decode(Response.self, from: raw)
  }
}
