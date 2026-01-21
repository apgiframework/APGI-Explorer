import Foundation
import SwiftUI

final class StateSearchService {
    @AppStorage("cacheSearchResults") private var cacheSearchResults: Bool = true

    private var searchCache: [String: [PsychologicalState]] = [:]

    func search(query: String, in states: [PsychologicalState]) -> [PsychologicalState] {
        let lowercasedQuery = query.lowercased()

        // Check cache first if enabled
        if cacheSearchResults && !query.isEmpty {
            if let cachedResults = searchCache[query] {
                return cachedResults
            }
        }

        let results = states.filter { state in
            state.name.lowercased().contains(lowercasedQuery) ||
            state.description.lowercased().contains(lowercasedQuery)
        }

        // Cache results if enabled
        if cacheSearchResults && !query.isEmpty {
            searchCache[query] = results
        }

        return results
    }

    func clearCache() {
        searchCache.removeAll()
    }

    func searchByParameters(
        predictionError: ParameterLevel?,
        precision: ParameterLevel?,
        threshold: ParameterLevel?,
        somaticBias: ParameterLevel?,
        in states: [PsychologicalState]
    ) -> [PsychologicalState] {
        states.filter { state in
            let predictionErrorMatch = predictionError == nil ||
                matchesParameterLevel(state.parameters.predictionError.accuracy, level: predictionError!)
            let precisionMatch = precision == nil ||
                matchesPrecisionLevel(state.parameters.precision, level: precision!)
            let thresholdMatch = threshold == nil ||
                matchesThresholdLevel(state.parameters.threshold, level: threshold!)
            let somaticBiasMatch = somaticBias == nil ||
                matchesBiasLevel(state.parameters.somaticBias, level: somaticBias!)

            return predictionErrorMatch && precisionMatch && thresholdMatch && somaticBiasMatch
        }
    }

    private func matchesParameterLevel(_ range: ParameterRange, level: ParameterLevel) -> Bool {
        let avgValue = (range.min + range.max) / 2
        switch level {
        case .veryLow: return avgValue < 20
        case .low: return avgValue >= 20 && avgValue < 40
        case .moderate: return avgValue >= 40 && avgValue < 60
        case .high: return avgValue >= 60 && avgValue < 80
        case .veryHigh: return avgValue >= 80
        }
    }

    private func matchesPrecisionLevel(_ profile: PrecisionProfile, level: ParameterLevel) -> Bool {
        let avgValue = (profile.task.value + profile.distractor.value) / 2
        switch level {
        case .veryLow: return avgValue < 20
        case .low: return avgValue >= 20 && avgValue < 40
        case .moderate: return avgValue >= 40 && avgValue < 60
        case .high: return avgValue >= 60 && avgValue < 80
        case .veryHigh: return avgValue >= 80
        }
    }

    private func matchesThresholdLevel(_ range: ThresholdRange, level: ParameterLevel) -> Bool {
        switch level {
        case .veryLow: return range.adjustment < 20
        case .low: return range.adjustment >= 20 && range.adjustment < 40
        case .moderate: return range.adjustment >= 40 && range.adjustment < 60
        case .high: return range.adjustment >= 60 && range.adjustment < 80
        case .veryHigh: return range.adjustment >= 80
        }
    }

    private func matchesBiasLevel(_ bias: BiasRange, level: ParameterLevel) -> Bool {
        // Convert the 0-1 range to a 0-100 scale for consistency with other parameters
        let scaledAverage = bias.average * 100.0

        switch level {
        case .veryLow: return scaledAverage < 20
        case .low: return scaledAverage >= 20 && scaledAverage < 40
        case .moderate: return scaledAverage >= 40 && scaledAverage < 60
        case .high: return scaledAverage >= 60 && scaledAverage < 80
        case .veryHigh: return scaledAverage >= 80
        }
    }
}
