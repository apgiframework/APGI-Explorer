import Combine
import Foundation

// MARK: - Structured Parameter Models

struct ParameterRange: Codable {
  let min: Double
  let max: Double
  let unit: Unit
  let description: String

  enum Unit: String, Codable, CaseIterable {
    case percentage = "%"
    case sigma = "σ"
    case accuracy
    case ratio
    case milliseconds = "ms"
    case seconds = "s"

    var symbol: String {
      self.rawValue
    }
  }

  var formattedRange: String {
    if self.min == self.max {
      return "\(Int(self.min))\(self.unit.symbol)"
    }
    return "\(Int(self.min))-\(Int(self.max))\(self.unit.symbol)"
  }

  /// The average value of the range
  var average: Double {
    (self.min + self.max) / 2.0
  }
}

struct PrecisionProfile: Codable {
  let task: PrecisionLevel
  let distractor: PrecisionLevel
  let description: String?

  init(task: PrecisionLevel, distractor: PrecisionLevel, description: String? = nil) {
    self.task = task
    self.distractor = distractor
    self.description = description
  }

  enum PrecisionLevel: Codable {
    case veryLow(Double)
    case low(Double)
    case moderate(Double)
    case high(Double)
    case veryHigh(Double)
    case extreme(Double)
    case baseline
    case suppressed(Double)
    case elevated(Double)

    var value: Double {
      switch self {
      case .veryLow(let val), .low(let val), .moderate(let val),
        .high(let val), .veryHigh(let val), .extreme(let val),
        .suppressed(let val), .elevated(let val):
        val
      case .baseline:
        0.0
      }
    }

    var description: String {
      switch self {
      case .veryLow: "Very Low"
      case .low: "Low"
      case .moderate: "Moderate"
      case .high: "High"
      case .veryHigh: "Very High"
      case .extreme: "Extreme"
      case .baseline: "Baseline"
      case .suppressed: "Suppressed"
      case .elevated: "Elevated"
      }
    }

    var formatted: String {
      switch self {
      case .baseline:
        "baseline"
      default:
        "\(self.description)(\(self.value)σ)"
      }
    }
  }
}

struct ThresholdRange: Codable {
  let adjustment: Double
  let variance: Double
  let unit: ParameterRange.Unit
  let stability: Stability
  let description: String

  enum Stability: String, Codable, CaseIterable {
    case stable
    case unstable
    case oscillating
    case elevated
    case suppressed
    case normal
    case chaotic

    var description: String {
      self.rawValue
    }
  }

  var formattedRange: String {
    let varianceText = self.variance > 0 ? " (±\(Int(self.variance))% variance)" : ""
    return
      "\(self.adjustment > 0 ? "+" : "")\(Int(self.adjustment))\(self.unit.symbol)\(varianceText)"
  }
}

struct BiasRange: Codable {
  let min: Double
  let max: Double
  let description: String
  let dominance: Dominance

  enum Dominance: String, Codable, CaseIterable {
    case balanced
    case somatic
    case cognitive
    case suppressed
    case amplified
    case variable

    var description: String {
      self.rawValue
    }
  }

  var formattedRange: String {
    if self.min == self.max {
      return "\(self.min) (\(self.dominance.description))"
    }
    return "\(self.min)-\(self.max) (\(self.dominance.description))"
  }

  /// The average value of the bias range
  var average: Double {
    (self.min + self.max) / 2.0
  }
}
