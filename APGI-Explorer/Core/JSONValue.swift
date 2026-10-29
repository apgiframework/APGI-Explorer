import Foundation

/// Lossless JSON value used for every request and response in the generated catalog.
nonisolated enum APIJSONValue: Codable, Equatable, Sendable {
  case string(String), number(Double), bool(Bool), object([String: APIJSONValue])
  case array([APIJSONValue]), null
  /// Integers keep full 64-bit precision; `number` is used only for fractional values.
  case integer(Int64)

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Int64.self) {
      self = .integer(value)
    } else if let value = try? container.decode(Double.self) {
      self = .number(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
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
    case .integer(let value): try container.encode(value)
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

  var array: [APIJSONValue]? {
    guard case .array(let value) = self else { return nil }
    return value
  }

  var string: String? {
    guard case .string(let value) = self else { return nil }
    return value
  }

  var int: Int? {
    guard case .integer(let value) = self else { return nil }
    return Int(exactly: value)
  }

  var bool: Bool { self == .bool(true) }
}
