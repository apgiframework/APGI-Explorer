import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Authentication is always an explicit argument; nothing is read from ambient state.
nonisolated enum APIAuthentication: Sendable, Equatable {
  case none
  case bearer(String)
}

nonisolated struct APIRequest: Sendable {
  var pathParameters: [String: String] = [:]
  var query: [String: String] = [:]
  var headers: [String: String] = [:]
  var body: APIJSONValue?
  init(pathParameters: [String: String] = [:], query: [String: String] = [:],
       headers: [String: String] = [:], body: APIJSONValue? = nil) {
    self.pathParameters = pathParameters
    self.query = query
    self.headers = headers
    self.body = body
  }
}

nonisolated enum APITransportError: Error, Equatable, LocalizedError {
  case insecureOrigin, missingParameter(String), unexpectedParameter(String)
  case invalidPathParameter(String), bodyRequired, bodyNotAllowed, authenticationRequired
  case redirectRejected(Int), http(Int), invalidResponse, unexpectedHost

  var errorDescription: String? {
    switch self {
    case .insecureOrigin: "The API origin must use HTTPS."
    case .missingParameter(let name): "Missing required parameter \(name)."
    case .unexpectedParameter(let name): "Parameter \(name) is not part of this operation."
    case .invalidPathParameter(let name): "Path parameter \(name) is not a single safe segment."
    case .bodyRequired: "This operation requires a JSON body."
    case .bodyNotAllowed: "This operation does not accept a body."
    case .authenticationRequired: "This operation requires explicit bearer authentication."
    case .redirectRejected(let status): "The API tried to redirect (HTTP \(status)); redirects are rejected."
    case .http(let status): "The API returned HTTP \(status). Try again later."
    case .invalidResponse: "The API returned an invalid response."
    case .unexpectedHost: "The response did not come from the expected API host."
    }
  }
}

/// Refuses every redirect so a credential can never be forwarded to another URL.
nonisolated final class RedirectRejectingDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
  func urlSession(_ session: URLSession, task: URLSessionTask,
                  willPerformHTTPRedirection response: HTTPURLResponse,
                  newRequest request: URLRequest,
                  completionHandler: @escaping (URLRequest?) -> Void) {
    completionHandler(nil)
  }
}

nonisolated struct APIRequestBuilder: Sendable {
  let baseURL: URL

  init(baseURL: URL) throws {
    guard baseURL.scheme == "https", baseURL.host != nil else { throw APITransportError.insecureOrigin }
    self.baseURL = baseURL
  }

  func urlRequest(for operation: APIOperation, request: APIRequest,
                  authentication: APIAuthentication) throws -> URLRequest {
    if operation.requiresAuthentication, case .none = authentication {
      throw APITransportError.authenticationRequired
    }
    let declared = Dictionary(uniqueKeysWithValues: operation.parameters.map { ("\($0.location.rawValue):\($0.name)", $0) })
    for name in request.pathParameters.keys where declared["path:\(name)"] == nil { throw APITransportError.unexpectedParameter(name) }
    for name in request.query.keys where declared["query:\(name)"] == nil { throw APITransportError.unexpectedParameter(name) }
    for name in request.headers.keys where declared["header:\(name)"] == nil { throw APITransportError.unexpectedParameter(name) }
    for parameter in operation.parameters where parameter.required {
      let supplied: Bool
      switch parameter.location {
      case .path: supplied = request.pathParameters[parameter.name] != nil
      case .query: supplied = request.query[parameter.name] != nil
      case .header: supplied = request.headers[parameter.name] != nil
      case .cookie: supplied = false
      }
      guard supplied else { throw APITransportError.missingParameter(parameter.name) }
    }
    switch (operation.body, request.body) {
    case (.required, nil): throw APITransportError.bodyRequired
    case (.none, .some): throw APITransportError.bodyNotAllowed
    default: break
    }

    var path = operation.path
    for (name, value) in request.pathParameters {
      guard !value.isEmpty, value != ".", value != "..",
            value.rangeOfCharacter(from: CharacterSet(charactersIn: "/?#\\%")) == nil,
            let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
        throw APITransportError.invalidPathParameter(name)
      }
      path = path.replacingOccurrences(of: "{\(name)}", with: encoded)
    }
    guard !path.contains("{") else { throw APITransportError.missingParameter(path) }

    var components = URLComponents()
    components.scheme = baseURL.scheme
    components.host = baseURL.host
    components.port = baseURL.port
    components.percentEncodedPath = path
    if !request.query.isEmpty {
      components.queryItems = request.query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    guard let url = components.url else { throw APITransportError.invalidResponse }
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = operation.method.rawValue
    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    for (name, value) in request.headers { urlRequest.setValue(value, forHTTPHeaderField: name) }
    if case .bearer(let token) = authentication, operation.requiresAuthentication {
      urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    if let body = request.body {
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.httpBody = try JSONEncoder().encode(body)
    }
    return urlRequest
  }

  /// Interprets a response; any redirect or non-success status is an error and keeps no payload.
  func interpret(_ operation: APIOperation, data: Data, response: URLResponse) throws -> APIJSONValue {
    guard let http = response as? HTTPURLResponse else { throw APITransportError.invalidResponse }
    if let url = http.url, url.scheme != "https" || url.host != baseURL.host { throw APITransportError.unexpectedHost }
    if (300..<400).contains(http.statusCode) { throw APITransportError.redirectRejected(http.statusCode) }
    guard operation.successStatuses.contains(http.statusCode) else { throw APITransportError.http(http.statusCode) }
    if data.isEmpty { return .null }
    do { return try JSONDecoder().decode(APIJSONValue.self, from: data) } catch { throw APITransportError.invalidResponse }
  }
}

nonisolated final class APITransport: Sendable {
  let builder: APIRequestBuilder
  private let session: URLSession

  init(baseURL: URL, session: URLSession? = nil) throws {
    builder = try APIRequestBuilder(baseURL: baseURL)
    if let session {
      self.session = session
    } else {
      let configuration = URLSessionConfiguration.ephemeral
      configuration.timeoutIntervalForRequest = 15
      configuration.timeoutIntervalForResource = 30
      configuration.httpCookieStorage = nil
      configuration.urlCache = nil
      self.session = URLSession(configuration: configuration, delegate: RedirectRejectingDelegate(), delegateQueue: nil)
    }
  }

  func send(_ operation: APIOperation, request: APIRequest = APIRequest(),
            authentication: APIAuthentication = .none) async throws -> APIJSONValue {
    let urlRequest = try builder.urlRequest(for: operation, request: request, authentication: authentication)
    let (data, response) = try await session.data(for: urlRequest)
    return try builder.interpret(operation, data: data, response: response)
  }
}
