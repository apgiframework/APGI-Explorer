import Foundation

/// The canonical byte form hashed by both Explorer and the server:
/// keys sorted by Unicode scalar, no insignificant whitespace, UTF-8 without
/// `\u` escaping of non-ASCII, slashes unescaped, integers only.
/// Mirrors `json.dumps(sort_keys=True, separators=(",", ":"), ensure_ascii=False)`.
nonisolated enum CanonicalJSON {
  enum Failure: Error, Equatable { case fractionalNumber, nonFiniteNumber }

  static func bytes(_ value: APIJSONValue) throws -> Data {
    var out = String()
    try write(value, into: &out)
    return Data(out.utf8)
  }

  static func sha256Hex(_ value: APIJSONValue) throws -> String {
    PortableSHA256.hexDigest(try bytes(value))
  }

  private static func write(_ value: APIJSONValue, into out: inout String) throws {
    switch value {
    case .null: out += "null"
    case .bool(let flag): out += flag ? "true" : "false"
    case .integer(let number): out += String(number)
    case .number(let number):
      guard number.isFinite else { throw Failure.nonFiniteNumber }
      guard number == number.rounded(), abs(number) < 9.0e15 else { throw Failure.fractionalNumber }
      out += String(Int64(number))
    case .string(let text): writeString(text, into: &out)
    case .array(let items):
      out += "["
      for (index, item) in items.enumerated() {
        if index > 0 { out += "," }
        try write(item, into: &out)
      }
      out += "]"
    case .object(let members):
      out += "{"
      let keys = members.keys.sorted { Array($0.unicodeScalars.map(\.value)).lexicographicallyPrecedes(Array($1.unicodeScalars.map(\.value))) }
      for (index, key) in keys.enumerated() {
        if index > 0 { out += "," }
        writeString(key, into: &out)
        out += ":"
        try write(members[key]!, into: &out)
      }
      out += "}"
    }
  }

  private static func writeString(_ text: String, into out: inout String) {
    out += "\""
    for scalar in text.unicodeScalars {
      switch scalar {
      case "\"": out += "\\\""
      case "\\": out += "\\\\"
      case "\n": out += "\\n"
      case "\r": out += "\\r"
      case "\t": out += "\\t"
      case "\u{08}": out += "\\b"
      case "\u{0C}": out += "\\f"
      default:
        if scalar.value < 0x20 {
          out += String(format: "\\u%04x", scalar.value)
        } else {
          out.unicodeScalars.append(scalar)
        }
      }
    }
    out += "\""
  }
}
