import Foundation
import os.log

// MARK: - Response Quality Analysis

class ResponseQualityAnalyzer {
    private let minAnswerTime: TimeInterval = 3.0 // Minimum reasonable time per question (seconds)
    private let maxAnswerTime: TimeInterval = 60.0 // Maximum expected time per question (seconds)
    private let optimalMinTime: TimeInterval = 10.0 // Lower bound of optimal time range
    private let optimalMaxTime: TimeInterval = 30.0 // Upper bound of optimal time range
    private let straightLineThreshold = 0.8 // 80% of answers the same value

    func detectStraightLining(answers: [Int: Int]) -> Bool {
        guard !answers.isEmpty else { return false }

        let values = Array(answers.values)
        guard let mode = values.mostCommon() else { return false }

        let modeCount = values.filter { $0 == mode }.count
        let modeRatio = Double(modeCount) / Double(values.count)

        return modeRatio > self.straightLineThreshold
    }

    func detectSpeedingWarnings(answerTimes: [Int: TimeInterval]) -> [Int] {
        answerTimes.filter { $0.value < self.minAnswerTime }.map(\.key).sorted()
    }

    func calculateEngagementScore(answerTimes: [Int: TimeInterval]) -> Double {
        guard !answerTimes.isEmpty else { return 0 }

        let times = answerTimes.values
        var score: Double = 0

        for time in times {
            if time < self.minAnswerTime {
                // Severely penalize answers that are too fast
                score += 0.1
            } else if time < self.optimalMinTime {
                // Linearly increase score from 0.5 to 1.0 in the sub-optimal range
                let timeRatio = (time - self.minAnswerTime) / (self.optimalMinTime - self.minAnswerTime)
                score += 0.5 + (0.5 * timeRatio)
            } else if time <= self.optimalMaxTime {
                // Full points for optimal time range
                score += 1.0
            } else if time <= self.maxAnswerTime {
                // Linearly decrease score from 1.0 to 0.5 in the sub-optimal range
                let timeRatio = (time - self.optimalMaxTime) / (self.maxAnswerTime - self.optimalMaxTime)
                score += 1.0 - (0.5 * timeRatio)
            } else {
                // Severely penalize answers that are too slow
                score += 0.1
            }
        }

        // Return average score across all questions
        return score / Double(times.count)
    }

    func generateQualityReport(answers: [Int: Int], answerTimes: [Int: TimeInterval]) -> (score: Double, warnings: [String]) {
        var warnings: [String] = []

        // Check for straight-lining
        if self.detectStraightLining(answers: answers) {
            warnings.append("Response pattern suggests potential straight-lining (many identical answers).")
        }

        // Check for speeding
        let fastQuestions = self.detectSpeedingWarnings(answerTimes: answerTimes)
        if !fastQuestions.isEmpty {
            let questionList = fastQuestions.map(String.init).joined(separator: ", ")
            warnings.append("Questions answered very quickly (less than \(Int(self.minAnswerTime))s): \(questionList)")
        }

        // Calculate engagement score
        let engagementScore = self.calculateEngagementScore(answerTimes: answerTimes)

        return (engagementScore, warnings)
    }
}

// MARK: - Array Extension for Mode Calculation

extension Array where Element: Hashable {
    /// Returns the most common element in the array
    func mostCommon() -> Element? {
        let counts = reduce(into: [:]) { $0[$1, default: 0] += 1 }
        return counts.max { $0.value < $1.value }?.key
    }
}

// MARK: - Reliability Tracking

/// Tracks and calculates various reliability metrics for the APGI quiz
class QuizReliabilityTracker {
    // MARK: - Data Structures

    /// Represents test-retest data for reliability analysis
    struct TestRetestData: Codable, Identifiable {
        let id: UUID
        let firstTest: APGIProfile
        let secondTest: APGIProfile
        let timeBetween: TimeInterval // in seconds
        let timestamp: Date

        var correlation: Double {
            QuizReliabilityTracker.calculateCorrelation(profile1: self.firstTest, profile2: self.secondTest)
        }

        init(firstTest: APGIProfile, secondTest: APGIProfile, timeBetween: TimeInterval) {
            self.id = UUID()
            self.firstTest = firstTest
            self.secondTest = secondTest
            self.timeBetween = timeBetween
            self.timestamp = Date()
        }
    }

    // MARK: - Properties

    private var testRetestData: [TestRetestData] = []
    private let minTestRetestInterval: TimeInterval = 60 * 60 * 24 * 7 // 1 week minimum between tests
    private let maxTestRetestInterval: TimeInterval = 60 * 60 * 24 * 60 // 2 months maximum between tests

    // MARK: - Public Methods

    /// Calculates Cronbach's alpha for internal consistency reliability
    /// - Parameter answers: Dictionary of question IDs to answer values
    /// - Returns: Cronbach's alpha value (0-1 scale)
    func calculateInternalConsistency(answers: [Int: Int]) -> Double {
        // Group questions by parameter
        let parameterGroups = Dictionary(grouping: answers) { questionId, _ in
            self.parameterForQuestion(questionId)
        }

        // Calculate variance for each parameter group
        let variances = parameterGroups.mapValues { answers in
            let values = answers.map { Double($0.value) }
            return Self.variance(of: values)
        }

        // Calculate total variance
        let allScores = answers.values.map { Double($0) }
        let totalVariance = Self.variance(of: allScores)

        // Calculate sum of variances for each parameter
        let sumOfVariances = variances.values.reduce(0, +)

        // Avoid division by zero
        guard totalVariance > 0 else { return 0 }

        // Calculate Cronbach's alpha
        let parameterCount = Double(parameterGroups.count)
        let alpha = (parameterCount / (parameterCount - 1)) * (1 - (sumOfVariances / totalVariance))

        // Ensure alpha is between 0 and 1
        return max(0, min(1, alpha))
    }

    /// Records a test-retest pair and returns the correlation
    /// - Parameters:
    ///   - firstTest: Results from the first test
    ///   - secondTest: Results from the second test
    ///   - timeBetween: Time interval between tests in seconds
    /// - Returns: Correlation between test scores (0-1)
    func recordTestRetest(firstTest: APGIProfile, secondTest: APGIProfile, timeBetween: TimeInterval) -> Double {
        // Validate time interval
        guard timeBetween >= self.minTestRetestInterval else {
            os_log("Test-retest interval too short for reliable measurement", type: .error)
            return 0
        }

        guard timeBetween <= self.maxTestRetestInterval else {
            os_log("Test-retest interval too long for reliable measurement", type: .error)
            return 0
        }

        let data = TestRetestData(firstTest: firstTest, secondTest: secondTest, timeBetween: timeBetween)
        self.testRetestData.append(data)

        // Return the correlation for this specific pair
        return data.correlation
    }

    /// Calculates the average test-retest reliability across all recorded pairs
    /// - Returns: Average correlation coefficient (0-1)
    func calculateTestRetestReliability() -> [String: Double] {
        guard !self.testRetestData.isEmpty else {
            return ["overall": 0]
        }

        // Calculate correlation for each dimension
        let dimensions = ["epsilon", "precision", "threshold", "somaticBias", "interactionScore", "temporalStability", "environmentalFit"]
        var results: [String: Double] = [:]

        for dimension in dimensions {
            let correlations = self.testRetestData.map { data -> Double in
                let value1 = data.firstTest.value(for: dimension)
                let value2 = data.secondTest.value(for: dimension)
                return Self.pearsonCorrelation(firstValues: [value1], secondValues: [value2])
            }
            results[dimension] = correlations.average()
        }

        // Calculate overall reliability as average of all dimensions
        let overall = results.values.reduce(0, +) / Double(results.count)
        results["overall"] = overall

        return results
    }

    // MARK: - Helper Methods

    private func parameterForQuestion(_ questionId: Int) -> String {
        // Map question IDs to parameters (epsilon, precision, threshold, etc.)
        // This is a simplified mapping - adjust based on your actual question structure
        switch questionId {
        case 1 ... 5: "epsilon"
        case 6 ... 10: "precision"
        case 11 ... 15: "threshold"
        case 16 ... 20: "somaticBias"
        case 21 ... 25: "interactionScore"
        case 26 ... 30: "temporalStability"
        case 31 ... 35: "environmentalFit"
        default: "unknown"
        }
    }

    private static func calculateCorrelation(profile1: APGIProfile, profile2: APGIProfile) -> Double {
        // Convert profiles to arrays of values for correlation calculation
        let values1 = [
            profile1.epsilon,
            profile1.precision,
            profile1.threshold,
            profile1.somaticBias,
            profile1.interactionScore,
            profile1.temporalStability,
            profile1.environmentalFit,
        ]

        let values2 = [
            profile2.epsilon,
            profile2.precision,
            profile2.threshold,
            profile2.somaticBias,
            profile2.interactionScore,
            profile2.temporalStability,
            profile2.environmentalFit,
        ]

        return self.pearsonCorrelation(firstValues: values1, secondValues: values2)
    }

    // MARK: - Statistical Functions

    private static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func variance(of values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let meanValue = self.mean(values)
        let squaredDiffs = values.map { pow($0 - meanValue, 2) }
        return self.mean(squaredDiffs)
    }

    private static func pearsonCorrelation(firstValues: [Double], secondValues: [Double]) -> Double {
        guard firstValues.count == secondValues.count, firstValues.count > 1 else { return 0 }

        let count = Double(firstValues.count)
        let sumFirst = firstValues.reduce(0, +)
        let sumSecond = secondValues.reduce(0, +)
        let sumProducts = zip(firstValues, secondValues).map(*).reduce(0, +)
        let sumFirstSquared = firstValues.map { $0 * $0 }.reduce(0, +)
        let sumSecondSquared = secondValues.map { $0 * $0 }.reduce(0, +)

        let numerator = (count * sumProducts) - (sumFirst * sumSecond)
        let denominatorFirst = (count * sumFirstSquared - sumFirst * sumFirst)
        let denominatorSecond = (count * sumSecondSquared - sumSecond * sumSecond)

        guard denominatorFirst > 0, denominatorSecond > 0 else { return 0 }

        return numerator / sqrt(denominatorFirst * denominatorSecond)
    }
}

// MARK: - APGIProfile Extension

extension APGIProfile {
    /// Gets the value for a given dimension name
    func value(for dimension: String) -> Double {
        switch dimension {
        case "epsilon": epsilon
        case "precision": precision
        case "threshold": threshold
        case "somaticBias": somaticBias
        case "interactionScore": interactionScore
        case "temporalStability": temporalStability
        case "environmentalFit": environmentalFit
        default: 0
        }
    }
}

// MARK: - Array Extension

extension [Double] {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
