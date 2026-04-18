import Foundation

// MARK: - Parameter Value Types

struct ParameterValue {
  let value: Double
  let isValid: Bool
  let errorMessage: String?

  init(_ value: Double, range: ClosedRange<Double> = -100...100) {
    self.value = value
    self.isValid = range.contains(value)
    self.errorMessage = self.isValid ? nil : "Value \(value) is outside valid range \(range)"
  }
}

struct PredictionError {
  let value: ParameterValue

  init(_ value: Double) {
    self.value = ParameterValue(value, range: 0...100)
  }
}

struct Precision {
  let value: ParameterValue

  init(_ value: Double) {
    self.value = ParameterValue(value, range: 0...100)
  }
}

struct Threshold {
  let value: ParameterValue

  init(_ value: Double) {
    self.value = ParameterValue(value, range: -100...100)
  }
}

struct SomaticBias {
  let value: ParameterValue

  init(_ value: Double) {
    self.value = ParameterValue(value, range: 0...100)
  }
}
