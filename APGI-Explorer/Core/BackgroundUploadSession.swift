#if canImport(Darwin)
import Foundation

nonisolated enum BackgroundUploadError: Error, Equatable { case noResponse, bodyUnavailable }

/// Sends operations through a URLSession *background* configuration so uploads continue
/// and are recovered after relaunch. Background sessions only support file-backed upload
/// tasks, so the JSON body is written to a private temporary file first. Requests are built
/// by `APIRequestBuilder` (HTTPS only, explicit bearer) and redirects are refused by the delegate.
///
/// Darwin-only (background configurations do not exist in Linux Foundation), so this file is
/// NOT compiled by the portable package. It has not been built or run: it needs Xcode and a
/// signed macOS host, including to confirm relaunch delivery.
nonisolated final class BackgroundUploadSession: NSObject, OperationSending, URLSessionDataDelegate, @unchecked Sendable {
  private let builder: APIRequestBuilder
  private let lock = NSLock()
  private var session: URLSession!
  private var waiting: [Int: CheckedContinuation<(Data, URLResponse), Error>] = [:]
  private var received: [Int: Data] = [:]
  private let redirectGuard = RedirectRejectingDelegate()

  init(baseURL: URL, identifier: String) throws {
    builder = try APIRequestBuilder(baseURL: baseURL)
    super.init()
    let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
    configuration.httpCookieStorage = nil
    configuration.urlCache = nil
    configuration.isDiscretionary = false
    session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
  }

  func send(_ operation: APIOperation, request: APIRequest, authentication: APIAuthentication) async throws -> APIJSONValue {
    var urlRequest = try builder.urlRequest(for: operation, request: request, authentication: authentication)
    guard let body = urlRequest.httpBody else { throw BackgroundUploadError.bodyUnavailable }
    urlRequest.httpBody = nil
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("upload-\(UUID().uuidString).json")
    try body.write(to: file, options: .atomic)
    defer { try? FileManager.default.removeItem(at: file) }
    let (data, response) = try await withCheckedThrowingContinuation { continuation in
      let task = session.uploadTask(with: urlRequest, fromFile: file)
      lock.lock()
      waiting[task.taskIdentifier] = continuation
      lock.unlock()
      task.resume()
    }
    return try builder.interpret(operation, data: data, response: response)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    lock.lock()
    received[dataTask.taskIdentifier, default: Data()].append(data)
    lock.unlock()
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    lock.lock()
    let continuation = waiting.removeValue(forKey: task.taskIdentifier)
    let data = received.removeValue(forKey: task.taskIdentifier) ?? Data()
    lock.unlock()
    if let error {
      continuation?.resume(throwing: error)
    } else if let response = task.response {
      continuation?.resume(returning: (data, response))
    } else {
      continuation?.resume(throwing: BackgroundUploadError.noResponse)
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                  newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
    redirectGuard.urlSession(session, task: task, willPerformHTTPRedirection: response,
                             newRequest: request, completionHandler: completionHandler)
  }
}
#endif
