//
//  ParameterValueTypes.swift
//  APGI Explorer
//
//  Defines parameter value types and validation for psychological state parameters.
//  This module provides type-safe handling of prediction error, precision, threshold, and somatic bias values.
//

import Foundation

// MARK: - Parameter Value Types

/// Represents a validated parameter value with bounds checking
struct ParameterValue {
    let value: Double
    let isValid: Bool
    let errorMessage: String?

    init(_ value: Double, range: ClosedRange<Double> = -100...100) {
        self.value = value
        self.isValid = range.contains(value)
        self.errorMessage = isValid ? nil : "Value \(value) is outside valid range \(range)"
    }
}

/// Type-safe prediction error parameter (ε)
struct PredictionError {
    let value: ParameterValue

    init(_ value: Double) {
        self.value = ParameterValue(value, range: 0...100)
    }
}

/// Type-safe precision parameter (π)
struct Precision {
    let value: ParameterValue

    init(_ value: Double) {
        self.value = ParameterValue(value, range: 0...100)
    }
}

/// Type-safe threshold parameter (θ)
struct Threshold {
    let value: ParameterValue

    init(_ value: Double) {
        self.value = ParameterValue(value, range: -100...100)
    }
}

/// Type-safe somatic bias parameter (β)
struct SomaticBias {
    let value: ParameterValue

    init(_ value: Double) {
        self.value = ParameterValue(value, range: 0...100)
    }
}
