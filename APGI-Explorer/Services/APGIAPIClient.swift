import Foundation

/// All network traffic uses the canonical HTTPS origin. No personal responses are sent.
enum APGIIdentifiers {
  static let api = URL(string: "https://api.apgiframework.com")!
  static let website = URL(string: "https://apgiframework.com")!
  static let support = URL(string: "https://github.com/apgiframework/APGI-Explorer/issues")!
  static let instrument = "apgi-explorer-35"
  static let analysisMode = "exploratory"
}

enum APGIAPIError: Error, LocalizedError {
  case invalidResponse, http(Int), incompatibleMetadata, transport(APITransportError)
  var errorDescription: String? {
    switch self {
    case .transport(let error): error.errorDescription
    case .invalidResponse: "The API returned an invalid response."
    case .http(let status): "The API returned HTTP \(status). Try again later."
    case .incompatibleMetadata: "The API metadata is incomplete or incompatible with Explorer."
    }
  }
}

/// The API has no pinned item-bank or verified event-upload contract yet.
/// This release cannot enable research or paid products through remote flags alone.
struct ExplorerReleasePolicy: Equatable {
  let validationResults: Bool
  let researchRequested: Bool
  let releaseState: String
  var paidProductsEnabled: Bool { false }
  var researchEnabled: Bool { false }

  init(metadata: [String: APIJSONValue]) throws {
    let required = ["researcher", "osf", "zenodo", "code", "web", "licences", "release_state"]
    guard required.allSatisfy({ metadata[$0]?.object != nil }),
          let release = metadata["release_state"]?.object,
          let state = release["current"]?.string,
          ["pre-registered", "pilot", "calibrated"].contains(state) else {
      throw APGIAPIError.incompatibleMetadata
    }
    releaseState = state
    validationResults = release["validation_results"]?.bool ?? false
    researchRequested = release["research_mode"]?.bool ?? false
  }
}

final class APGIAPIClient {
  private let transport: APITransport

  init(session: URLSession? = nil) {
    // The origin is a compile-time HTTPS constant, so construction cannot fail.
    // swiftlint:disable:next force_try
    transport = try! APITransport(baseURL: APGIIdentifiers.api, session: session)
  }

  /// Any operation of the pinned v1 catalog. Authentication is always explicit.
  func call(_ operation: APIOperation, request: APIRequest = APIRequest(),
            authentication: APIAuthentication = .none) async throws -> APIJSONValue {
    do {
      return try await transport.send(operation, request: request, authentication: authentication)
    } catch let error as APITransportError {
      if case .http(let status) = error { throw APGIAPIError.http(status) }
      throw APGIAPIError.transport(error)
    }
  }

  /// Public metadata checks only; participant credentials never reach these calls.
  func get<T: Decodable>(_ path: String) async throws -> T {
    guard ["/v1/meta", "/v1/version"].contains(path),
          let operation = APGIOperations.all.first(where: { $0.path == path && $0.method == .get }) else {
      throw APGIAPIError.invalidResponse
    }
    let value = try await call(operation)
    return try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
  }
}
