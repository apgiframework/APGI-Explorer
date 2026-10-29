import Foundation

// Moved here so the scorer and its tests run in the portable (Linux) package as well as in the app.

// MARK: - Parameter levels

nonisolated enum ParameterLevel: String, CaseIterable, Sendable {
  case veryLow = "Very Low"
  case low = "Low"
  case moderate = "Moderate"
  case high = "High"
  case veryHigh = "Very High"

  var rawValue: String {
    switch self {
    case .veryLow: "Very Low"
    case .low: "Low"
    case .moderate: "Moderate"
    case .high: "High"
    case .veryHigh: "Very High"
    }
  }
}

// MARK: - Profile

nonisolated struct APGIProfile: Codable, Equatable, Sendable {
    var epsilon: Double // 0-100 normalized
    var precision: Double
    var threshold: Double
    var somaticBias: Double
    var interactionScore: Double
    var temporalStability: Double
    var environmentalFit: Double

    var epsilonCategory: ParameterLevel {
        switch self.epsilon {
        case 0 ..< 25: .veryLow
        case 25 ..< 40: .low
        case 40 ..< 60: .moderate
        case 60 ..< 75: .high
        default: .veryHigh
        }
    }

    var precisionCategory: ParameterLevel {
        switch self.precision {
        case 0 ..< 25: .veryLow
        case 25 ..< 40: .low
        case 40 ..< 60: .moderate
        case 60 ..< 75: .high
        default: .veryHigh
        }
    }

    var thresholdCategory: ParameterLevel {
        switch self.threshold {
        case 0 ..< 25: .veryLow
        case 25 ..< 40: .low
        case 40 ..< 60: .moderate
        case 60 ..< 75: .high
        default: .veryHigh
        }
    }

    var somaticCategory: ParameterLevel {
        switch self.somaticBias {
        case 0 ..< 25: .veryLow
        case 25 ..< 40: .low
        case 40 ..< 60: .moderate
        case 60 ..< 75: .high
        default: .veryHigh
        }
    }

    var interactionCategory: ParameterLevel {
        switch self.interactionScore {
        case 0 ..< 25: .veryLow
        case 25 ..< 40: .low
        case 40 ..< 60: .moderate
        case 60 ..< 75: .high
        default: .veryHigh
        }
    }

    var temporalCategory: ParameterLevel {
        switch self.temporalStability {
        case 0 ..< 25: .veryLow
        case 25 ..< 40: .low
        case 40 ..< 60: .moderate
        case 60 ..< 75: .high
        default: .veryHigh
        }
    }

    var environmentalCategory: ParameterLevel {
        switch self.environmentalFit {
        case 0 ..< 25: .veryLow
        case 25 ..< 40: .low
        case 40 ..< 60: .moderate
        case 60 ..< 75: .high
        default: .veryHigh
        }
    }

    /// Computed properties for export compatibility
    var overall: Double {
        (self.epsilon + self.precision + self.threshold + self.somaticBias) / 4.0
    }

}
