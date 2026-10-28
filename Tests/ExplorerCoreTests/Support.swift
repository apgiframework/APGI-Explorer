import Foundation
@testable import ExplorerCore
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

enum Fixture {
  static func data(_ name: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
      throw CocoaError(.fileNoSuchFile)
    }
    return try Data(contentsOf: url)
  }
  static func json(_ name: String) throws -> APIJSONValue {
    try JSONDecoder().decode(APIJSONValue.self, from: data(name))
  }
}

/// Scripted adapter: each call pops the next behaviour.
final class ScriptedAdapter: ResearchUploadAdapter, @unchecked Sendable {
  enum Step { case ack, ackWrongDigest, ackUnverified, ackMissing, fail }
  private let lock = NSLock()
  private var steps: [Step]
  private(set) var calls: [[UploadEnvelope]] = []
  init(_ steps: [Step]) { self.steps = steps }

  func upload(sessionID: String, events: [UploadEnvelope], authorization: String) async throws -> [UploadAcknowledgement] {
    let step: Step = lock.withLock {
      calls.append(events)
      return steps.isEmpty ? Step.ack : steps.removeFirst()
    }
    switch step {
    case .fail: throw URLError(.notConnectedToInternet)
    case .ackMissing: return []
    case .ack: return events.map { UploadAcknowledgement(eventKey: $0.eventKey, seqNo: $0.seqNo, payloadDigest: $0.payloadDigest, serverVerified: true) }
    case .ackWrongDigest: return events.map { UploadAcknowledgement(eventKey: $0.eventKey, seqNo: $0.seqNo, payloadDigest: String(repeating: "0", count: 64), serverVerified: true) }
    case .ackUnverified: return events.map { UploadAcknowledgement(eventKey: $0.eventKey, seqNo: $0.seqNo, payloadDigest: $0.payloadDigest, serverVerified: false) }
    }
  }
}

final class Clock: @unchecked Sendable {
  private let lock = NSLock()
  private var current = Date(timeIntervalSince1970: 1_800_000_000)
  var now: Date { lock.lock(); defer { lock.unlock() }; return current }
  func advance(_ seconds: TimeInterval) { lock.lock(); current = current.addingTimeInterval(seconds); lock.unlock() }
}

func payload(_ item: Int, _ value: Int) -> APIJSONValue {
  .object(["item_id": .integer(Int64(item)), "value": .integer(Int64(value)), "latency_us": .integer(10)])
}
