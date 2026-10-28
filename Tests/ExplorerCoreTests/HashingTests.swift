import XCTest
@testable import ExplorerCore

final class HashingTests: XCTestCase {
  func testSHA256KnownVectors() {
    XCTAssertEqual(PortableSHA256.hexDigest(""), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    XCTAssertEqual(PortableSHA256.hexDigest("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    XCTAssertEqual(PortableSHA256.hexDigest(String(repeating: "a", count: 1_000)),
                   "41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3")
  }

  /// Vectors produced by the server's Python canonicaliser (`json.dumps(sort_keys, separators, ensure_ascii=False)`).
  func testCanonicalBytesAndDigestMatchServer() throws {
    let vectors = try XCTUnwrap(Fixture.json("canonical-vectors").array)
    XCTAssertEqual(vectors.count, 3)
    for vector in vectors {
      let fields = try XCTUnwrap(vector.object)
      let bytes = try CanonicalJSON.bytes(try XCTUnwrap(fields["payload"]))
      XCTAssertEqual(String(decoding: bytes, as: UTF8.self), fields["canonical"]?.string)
      XCTAssertEqual(PortableSHA256.hexDigest(bytes), fields["sha256"]?.string)
    }
  }

  func testFractionalAndNonFiniteNumbersAreRejected() {
    XCTAssertThrowsError(try CanonicalJSON.bytes(.number(1.5)))
    XCTAssertThrowsError(try CanonicalJSON.bytes(.number(.infinity)))
    XCTAssertEqual(String(decoding: try CanonicalJSON.bytes(.number(3.0)), as: UTF8.self), "3")
  }

  func testEventKeyIsStableAndUUIDShaped() {
    let key = EventKey.make(sessionID: "s1", seqNo: 4)
    XCTAssertEqual(key, EventKey.make(sessionID: "s1", seqNo: 4))
    XCTAssertNotEqual(key, EventKey.make(sessionID: "s1", seqNo: 5))
    XCTAssertEqual(key.count, 36)
    XCTAssertNotNil(UUID(uuidString: key))
  }
}
