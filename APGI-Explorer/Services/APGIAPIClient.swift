import Foundation

/// All network traffic uses the canonical HTTPS origin. No personal responses are sent.
enum APGIIdentifiers {
  static let api = URL(string: "https://api.apgiframework.com")!
  static let website = URL(string: "https://apgiframework.com")!
  static let support = URL(string: "https://github.com/apgiframework/APGI-Explorer/issues")!
  static let instrument = "apgi-explorer-35"
  static let analysisMode = "exploratory"
}

enum APIJSONValue: Codable, Equatable, Sendable {
  case string(String), number(Double), bool(Bool), object([String: APIJSONValue])
  case array([APIJSONValue]), null

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode(Double.self) {
      self = .number(value)
    } else if let value = try? container.decode([String: APIJSONValue].self) {
      self = .object(value)
    } else {
      self = .array(try container.decode([APIJSONValue].self))
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let value): try container.encode(value)
    case .number(let value): try container.encode(value)
    case .bool(let value): try container.encode(value)
    case .object(let value): try container.encode(value)
    case .array(let value): try container.encode(value)
    case .null: try container.encodeNil()
    }
  }

  var object: [String: APIJSONValue]? {
    guard case .object(let value) = self else { return nil }
    return value
  }

  var string: String? {
    guard case .string(let value) = self else { return nil }
    return value
  }

  var bool: Bool { self == .bool(true) }

}

enum APGIAPIError: Error, LocalizedError {
  case invalidResponse, http(Int), incompatibleMetadata
  var errorDescription: String? {
    switch self {
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
  private let session: URLSession
  init(session: URLSession? = nil) {
    if let session { self.session = session } else {
      let configuration = URLSessionConfiguration.ephemeral
      configuration.timeoutIntervalForRequest = 15
      configuration.timeoutIntervalForResource = 30
      configuration.httpCookieStorage = nil
      configuration.urlCache = nil
      self.session = URLSession(configuration: configuration)
    }
  }

  func get<T: Decodable>(_ path: String) async throws -> T {
    guard ["/v1/meta", "/v1/version"].contains(path) else { throw APGIAPIError.invalidResponse }
    var request = URLRequest(url: APGIIdentifiers.api.appendingPathComponent(String(path.dropFirst())))
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    let (data, response) = try await session.data(for: request)
    guard let response = response as? HTTPURLResponse,
          response.url?.scheme == "https", response.url?.host == APGIIdentifiers.api.host else {
      throw APGIAPIError.invalidResponse
    }
    guard (200..<300).contains(response.statusCode) else { throw APGIAPIError.http(response.statusCode) }
    return try JSONDecoder().decode(T.self, from: data)
  }
}
