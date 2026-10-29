import XCTest
@testable import ExplorerCore
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class CatalogTests: XCTestCase {
  private func spec(_ name: String) throws -> [String: Any] {
    var url = URL(fileURLWithPath: #filePath)
    for _ in 0..<3 { url.deleteLastPathComponent() }
    let data = try Data(contentsOf: url.appendingPathComponent("contracts/\(name)"))
    return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  /// Every operation of the pinned OpenAPI appears in the generated catalog with identical metadata.
  func testCatalogCoversEveryPinnedOperation() throws {
    let paths = try XCTUnwrap(spec("openapi-v1.json")["paths"] as? [String: [String: Any]])
    var expected = 0
    for (path, item) in paths {
      for method in ["get", "post", "put", "patch", "delete"] {
        guard let operation = item[method] as? [String: Any] else { continue }
        expected += 1
        let id = try XCTUnwrap(operation["operationId"] as? String)
        let entry = try XCTUnwrap(APGIOperations.byID[id], "missing \(id)")
        XCTAssertEqual(entry.method.rawValue, method.uppercased())
        XCTAssertEqual(entry.path, path)
        XCTAssertEqual(entry.requiresAuthentication, operation["security"] != nil, id)
        let parameters = (operation["parameters"] as? [[String: Any]]) ?? []
        XCTAssertEqual(entry.parameters.count, parameters.count, id)
        let body = operation["requestBody"] as? [String: Any]
        XCTAssertEqual(entry.body, body == nil ? .none : ((body?["required"] as? Bool) == true ? .required : .optional), id)
        let ok = (operation["responses"] as? [String: Any] ?? [:]).keys.compactMap { $0.hasPrefix("2") ? Int($0) : nil }.sorted()
        XCTAssertEqual(entry.successStatuses, ok, id)
      }
    }
    XCTAssertEqual(expected, 121)
    XCTAssertEqual(APGIOperations.all.count, 121)
    XCTAssertEqual(APGIOperations.operationCount, 121)
  }

  func testResearchCatalogMatchesItsContract() throws {
    let paths = try XCTUnwrap(spec("explorer-research-v1.json")["paths"] as? [String: [String: Any]])
    let count = paths.values.reduce(0) { $0 + $1.keys.filter { ["get", "post", "put", "patch", "delete"].contains($0) }.count }
    XCTAssertEqual(ExplorerResearchOperations.all.count, count)
    XCTAssertNotNil(ExplorerResearchOperations.byID[ExplorerResearchAdapter.uploadOperationID])
  }

  private func operation(_ id: String) throws -> APIOperation { try XCTUnwrap(APGIOperations.byID[id]) }
  private let base = URL(string: "https://api.example.test")!

  func testAuthenticationIsExplicitAndOnlySentWhenRequired() throws {
    let builder = try APIRequestBuilder(baseURL: base)
    let secured = try XCTUnwrap(APGIOperations.all.first { $0.requiresAuthentication && $0.parameters.isEmpty && $0.body == .none && $0.method == .get })
    XCTAssertThrowsError(try builder.urlRequest(for: secured, request: APIRequest(), authentication: .none)) {
      XCTAssertEqual($0 as? APITransportError, .authenticationRequired)
    }
    let request = try builder.urlRequest(for: secured, request: APIRequest(), authentication: .bearer("tok"))
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tok")
    let publicOp = try XCTUnwrap(APGIOperations.all.first { !$0.requiresAuthentication && $0.parameters.isEmpty && $0.body == .none && $0.method == .get })
    let anonymous = try builder.urlRequest(for: publicOp, request: APIRequest(), authentication: .bearer("tok"))
    XCTAssertNil(anonymous.value(forHTTPHeaderField: "Authorization"), "credentials must not leak to public operations")
  }

  func testParameterAndBodyValidation() throws {
    let builder = try APIRequestBuilder(baseURL: base)
    let withPath = try XCTUnwrap(APGIOperations.all.first { $0.parameters.contains { $0.location == .path } && $0.body == .none })
    let name = try XCTUnwrap(withPath.parameters.first { $0.location == .path }).name
    XCTAssertThrowsError(try builder.urlRequest(for: withPath, request: APIRequest(), authentication: .bearer("t")))
    XCTAssertThrowsError(try builder.urlRequest(for: withPath, request: APIRequest(pathParameters: [name: "../x"]), authentication: .bearer("t")))
    XCTAssertThrowsError(try builder.urlRequest(for: withPath, request: APIRequest(pathParameters: [name: "a/b"]), authentication: .bearer("t")))
    XCTAssertThrowsError(try builder.urlRequest(for: withPath, request: APIRequest(pathParameters: [name: "ok", "extra": "1"]), authentication: .bearer("t")))
    XCTAssertThrowsError(try builder.urlRequest(for: withPath, request: APIRequest(pathParameters: [name: "ok"], body: .null), authentication: .bearer("t")))
    let url = try builder.urlRequest(for: withPath, request: APIRequest(pathParameters: [name: "abc 1"]), authentication: .bearer("t")).url
    XCTAssertEqual(url?.host, "api.example.test")
    XCTAssertTrue(url?.absoluteString.contains("abc%201") ?? false)
    let needsBody = try XCTUnwrap(APGIOperations.all.first { $0.body == .required })
    var request = APIRequest()
    for p in needsBody.parameters where p.required { if p.location == .path { request.pathParameters[p.name] = "1" } else if p.location == .query { request.query[p.name] = "1" } }
    XCTAssertThrowsError(try builder.urlRequest(for: needsBody, request: request, authentication: .bearer("t"))) {
      XCTAssertEqual($0 as? APITransportError, .bodyRequired)
    }
  }

  func testNonHTTPSOriginRejected() {
    XCTAssertThrowsError(try APIRequestBuilder(baseURL: URL(string: "http://api.example.test")!))
  }

  func testRedirectsAreRefusedAndStatusesChecked() throws {
    let builder = try APIRequestBuilder(baseURL: base)
    let op = try operation("get_meta_v1_meta_get")
    func response(_ status: Int, host: String = "api.example.test") -> HTTPURLResponse {
      HTTPURLResponse(url: URL(string: "https://\(host)/v1/meta")!, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
    XCTAssertThrowsError(try builder.interpret(op, data: Data(), response: response(307))) { XCTAssertEqual($0 as? APITransportError, .redirectRejected(307)) }
    XCTAssertThrowsError(try builder.interpret(op, data: Data(), response: response(500))) { XCTAssertEqual($0 as? APITransportError, .http(500)) }
    XCTAssertThrowsError(try builder.interpret(op, data: Data("{}".utf8), response: response(200, host: "evil.test"))) { XCTAssertEqual($0 as? APITransportError, .unexpectedHost) }
    XCTAssertEqual(try builder.interpret(op, data: Data(#"{"a":1}"#.utf8), response: response(200)), .object(["a": .integer(1)]))

    let delegate = RedirectRejectingDelegate()
    let session = URLSession(configuration: .ephemeral)
    let task = session.dataTask(with: URL(string: "https://api.example.test/x")!)
    var forwarded: URLRequest? = URLRequest(url: URL(string: "https://evil.test")!)
    delegate.urlSession(session, task: task, willPerformHTTPRedirection: response(302),
                        newRequest: URLRequest(url: URL(string: "https://evil.test")!)) { forwarded = $0 }
    XCTAssertNil(forwarded)
  }

  func testJSONValueIsLossless() throws {
    let text = #"{"big":9007199254740993,"f":1.5,"s":"x","n":null,"t":true,"a":[1,{"b":false}]}"#
    let value = try JSONDecoder().decode(APIJSONValue.self, from: Data(text.utf8))
    XCTAssertEqual(value.object?["big"], .integer(9_007_199_254_740_993))
    let again = try JSONDecoder().decode(APIJSONValue.self, from: JSONEncoder().encode(value))
    XCTAssertEqual(value, again)
  }
}
