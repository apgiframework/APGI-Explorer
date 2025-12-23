import Foundation

// MARK: - Response Quality Analysis

/// Analyzes response patterns to detect potential data quality issues
class ResponseQualityAnalyzer {
    private let minAnswerTime: TimeInterval = 3.0 // Minimum reasonable time per question (seconds)
    private let maxAnswerTime: TimeInterval = 60.0 // Maximum expected time per question (seconds)
    private let optimalMinTime: TimeInterval = 10.0 // Lower bound of optimal time range
    private let optimalMaxTime: TimeInterval = 30.0 // Upper bound of optimal time range
    private let straightLineThreshold = 0.8 // 80% of answers the same value
    
    /// Detects if responses show a straight-lining pattern (all or most answers the same)
    /// - Parameter answers: Dictionary of question IDs to answer values
    /// - Returns: Boolean indicating if straight-lining was detected
    func detectStraightLining(answers: [Int: Int]) -> Bool {
        guard !answers.isEmpty else { return false }
        
        let values = Array(answers.values)
        guard let mode = values.mostCommon() else { return false }
        
        let modeCount = values.filter { $0 == mode }.count
        let modeRatio = Double(modeCount) / Double(values.count)
        
        return modeRatio > straightLineThreshold
    }
    
    /// Identifies questions that were answered too quickly (potential random responding)
    /// - Parameter answerTimes: Dictionary of question IDs to time taken (in seconds)
    /// - Returns: Array of question IDs that were answered too quickly
    func detectSpeedingWarnings(answerTimes: [Int: TimeInterval]) -> [Int] {
        return answerTimes.filter { $0.value < minAnswerTime }.map { $0.key }.sorted()
    }
    
    /// Calculates an engagement score based on response times
    /// - Parameter answerTimes: Dictionary of question IDs to time taken (in seconds)
    /// - Returns: Score from 0 (poor engagement) to 1 (excellent engagement)
    func calculateEngagementScore(answerTimes: [Int: TimeInterval]) -> Double {
        guard !answerTimes.isEmpty else { return 0 }
        
        let times = answerTimes.values
        var score: Double = 0
        
        for time in times {
            if time < minAnswerTime {
                // Severely penalize answers that are too fast
                score += 0.1
            } else if time < optimalMinTime {
                // Linearly increase score from 0.5 to 1.0 in the sub-optimal range
                let t = (time - minAnswerTime) / (optimalMinTime - minAnswerTime)
                score += 0.5 + (0.5 * t)
            } else if time <= optimalMaxTime {
                // Full points for optimal time range
                score += 1.0
            } else if time <= maxAnswerTime {
                // Linearly decrease score from 1.0 to 0.5 in the sub-optimal range
                let t = (time - optimalMaxTime) / (maxAnswerTime - optimalMaxTime)
                score += 1.0 - (0.5 * t)
            } else {
                // Severely penalize answers that are too slow
                score += 0.1
            }
        }
        
        // Return average score across all questions
        return score / Double(times.count)
    }
    
    /// Generates a quality report for the response data
    /// - Parameters:
    ///   - answers: Dictionary of question IDs to answer values
    ///   - answerTimes: Dictionary of question IDs to time taken (in seconds)
    /// - Returns: A tuple containing the engagement score and any quality warnings
    func generateQualityReport(answers: [Int: Int], answerTimes: [Int: TimeInterval]) -> (score: Double, warnings: [String]) {
        var warnings: [String] = []
        
        // Check for straight-lining
        if detectStraightLining(answers: answers) {
            warnings.append("Response pattern suggests potential straight-lining (many identical answers).")
        }
        
        // Check for speeding
        let fastQuestions = detectSpeedingWarnings(answerTimes: answerTimes)
        if !fastQuestions.isEmpty {
            let questionList = fastQuestions.map(String.init).joined(separator: ", ")
            warnings.append("Questions answered very quickly (less than \(Int(minAnswerTime))s): \(questionList)")
        }
        
        // Calculate engagement score
        let engagementScore = calculateEngagementScore(answerTimes: answerTimes)
        
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
            QuizReliabilityTracker.calculateCorrelation(profile1: firstTest, profile2: secondTest)
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
    private let minTestRetestInterval: TimeInterval = 60 * 60 * 24 * 7  // 1 week minimum between tests
    private let maxTestRetestInterval: TimeInterval = 60 * 60 * 24 * 60 // 2 months maximum between tests
    
    // MARK: - Public Methods
    
    /// Calculates Cronbach's alpha for internal consistency reliability
    /// - Parameter answers: Dictionary of question IDs to answer values
    /// - Returns: Cronbach's alpha value (0-1 scale)
    func calculateInternalConsistency(answers: [Int: Int]) -> Double {
        // Group questions by parameter
        let parameterGroups = Dictionary(grouping: answers) { questionId, _ in
            parameterForQuestion(questionId)
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
        let k = Double(parameterGroups.count)
        let alpha = (k / (k - 1)) * (1 - (sumOfVariances / totalVariance))
        
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
        guard timeBetween >= minTestRetestInterval else {
            print("Warning: Test-retest interval too short for reliable measurement")
            return 0
        }
        
        guard timeBetween <= maxTestRetestInterval else {
            print("Warning: Test-retest interval too long for reliable measurement")
            return 0
        }
        
        let data = TestRetestData(firstTest: firstTest, secondTest: secondTest, timeBetween: timeBetween)
        testRetestData.append(data)
        
        // Return the correlation for this specific pair
        return data.correlation
    }
    
    /// Calculates the average test-retest reliability across all recorded pairs
    /// - Returns: Average correlation coefficient (0-1)
    func calculateTestRetestReliability() -> [String: Double] {
        guard !testRetestData.isEmpty else {
            return ["overall": 0]
        }
        
        // Calculate correlation for each dimension
        let dimensions = ["epsilon", "precision", "threshold", "somaticBias", "interactionScore", "temporalStability", "environmentalFit"]
        var results: [String: Double] = [:]
        
        for dimension in dimensions {
            let correlations = testRetestData.map { data -> Double in
                let value1 = data.firstTest.value(for: dimension)
                let value2 = data.secondTest.value(for: dimension)
                return Self.pearsonCorrelation(x: [value1], y: [value2])
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
        case 1...5: return "epsilon"
        case 6...10: return "precision"
        case 11...15: return "threshold"
        case 16...20: return "somaticBias"
        case 21...25: return "interactionScore"
        case 26...30: return "temporalStability"
        case 31...35: return "environmentalFit"
        default: return "unknown"
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
            profile1.environmentalFit
        ]
        
        let values2 = [
            profile2.epsilon,
            profile2.precision,
            profile2.threshold,
            profile2.somaticBias,
            profile2.interactionScore,
            profile2.temporalStability,
            profile2.environmentalFit
        ]
        
        return pearsonCorrelation(x: values1, y: values2)
    }
    
    // MARK: - Statistical Functions
    
    private static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private static func variance(of values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let meanValue = mean(values)
        let squaredDiffs = values.map { pow($0 - meanValue, 2) }
        return mean(squaredDiffs)
    }
    
    private static func pearsonCorrelation(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count, x.count > 1 else { return 0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = (n * sumXY) - (sumX * sumY)
        let denominatorX = (n * sumX2 - sumX * sumX)
        let denominatorY = (n * sumY2 - sumY * sumY)
        
        guard denominatorX > 0 && denominatorY > 0 else { return 0 }
        
        return numerator / sqrt(denominatorX * denominatorY)
    }
}

// MARK: - APGIProfile Extension

extension APGIProfile {
    /// Gets the value for a given dimension name
    func value(for dimension: String) -> Double {
        switch dimension {
        case "epsilon": return epsilon
        case "precision": return precision
        case "threshold": return threshold
        case "somaticBias": return somaticBias
        case "interactionScore": return interactionScore
        case "temporalStability": return temporalStability
        case "environmentalFit": return environmentalFit
        default: return 0
        }
    }
}

// MARK: - Array Extension

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
