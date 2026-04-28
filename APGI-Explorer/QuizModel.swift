import Combine
import Foundation

// MARK: - Validation Models

struct ValidationResult {
    let isValid: Bool
    let warnings: [String]
    let confidence: Double
    let completionRate: Double

    var formattedConfidence: String {
        "\(Int(self.confidence * 100))%"
    }

    var formattedCompletionRate: String {
        "\(Int(self.completionRate * 100))%"
    }
}

// MARK: - Scoring System

enum ScoringWeights {
    static let parameterWeights: [String: Double] = [
        "epsilon": 1.0,
        "precision": 1.0,
        "threshold": 1.0,
        "somatic": 1.0,
        "interactions": 0.5, // Meta-questions have different weight
        "temporal": 0.3,
        "environment": 0.3
    ]

    /// Question-specific weights based on reliability
    static let questionReliability: [Int: Double] = [
        // Epsilon questions (1-4) - Core direct questions
        1: 0.95,
        2: 0.90,
        3: 0.95,
        4: 0.85,
        5: 0.90,

        // Precision questions (6-10) - Direct questions
        6: 0.90,
        7: 0.85,
        8: 0.80,
        9: 0.85,
        10: 0.80,

        // Threshold questions (11-15) - Direct questions
        11: 0.90,
        12: 0.85,
        13: 0.80,
        14: 0.85,
        15: 0.90,

        // Somatic questions (16-20) - Direct questions
        16: 0.90,
        17: 0.85,
        18: 0.95,
        19: 0.90,
        20: 0.85,

        // Interaction questions (21-25) - Less direct
        21: 0.70,
        22: 0.70,
        23: 0.65,
        24: 0.70,
        25: 0.65,

        // Temporal questions (26-30) - Moderate reliability
        26: 0.75,
        27: 0.80,
        28: 0.75,
        29: 0.70,
        30: 0.75,

        // Environmental questions (31-35) - Context-dependent
        31: 0.60,
        32: 0.60,
        33: 0.65,
        34: 0.60,
        35: 0.55
    ]
}

// MARK: - Profile Models

// Using ParameterLevel from ParameterValueTypes.swift instead of separate enums

struct APGIProfile: Codable, Equatable {
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

    var autonomy: Double {
        self.precision
    }

    var purposefulness: Double {
        self.threshold
    }

    var selfAcceptance: Double {
        self.somaticBias
    }

    var personalGrowth: Double {
        self.environmentalFit
    }
}

class QuizModel: ObservableObject {
    var questions: [QuizQuestion] { Self.allQuestions }
    @Published var answers: [Int: Int] = [:] {
        didSet {
            // Update validation state when answers change
            self._validationResult = nil
        }
    }

    @Published var currentQuestionIndex: Int = 0

    // Track quiz timing for analytics
    private let startTime: Date

    /// Duration of the quiz in seconds
    var duration: TimeInterval {
        Date().timeIntervalSince(self.startTime)
    }

    // Cache for validation results
    private var _validationResult: ValidationResult?
    private let validationThreshold: Double = 0.7 // Minimum confidence threshold for valid responses

    var isComplete: Bool {
        self.answers.count == self.questions.count
    }

    init() {
        self.startTime = Date()
    }

    func selectAnswer(for questionId: Int, answer: Int) {
        self.answers[questionId] = answer
        // Invalidate cached validation result
        self._validationResult = nil
    }

    func selectAnswer(_ answer: Int) {
        guard self.currentQuestionIndex < self.questions.count else { return }
        let questionId = self.questions[self.currentQuestionIndex].id
        self.selectAnswer(for: questionId, answer: answer)
    }

    func restoreAnswers(_ restoredAnswers: [Int: Int]) {
        self.answers = restoredAnswers
        // Invalidate cached validation result
        self._validationResult = nil
    }

    func nextQuestion() {
        if self.currentQuestionIndex < self.questions.count - 1 {
            self.currentQuestionIndex += 1
        }
    }

    func previousQuestion() {
        if self.currentQuestionIndex > 0 {
            self.currentQuestionIndex -= 1
        }
    }

    var hasAnsweredCurrentQuestion: Bool {
        guard self.currentQuestionIndex < self.questions.count else { return false }
        return self.answers[self.questions[self.currentQuestionIndex].id] != nil
    }

    func questionsNeededForConfidence(target: Double = 0.9) -> Int? {
        let currentConfidence = self.calculateResponseConfidence()
        guard currentConfidence < target, self.answers.count < self.questions.count else {
            return nil
        }

        let remaining = self.questions.count - self.answers.count
        guard remaining > 0 else { return nil }

        let shortfall = target - currentConfidence
        let capacity = 1 - currentConfidence
        let estimatedQuestions = Int(ceil(Double(remaining) * max(0, shortfall / max(capacity, 0.01))))
        return min(remaining, max(1, estimatedQuestions))
    }

    func confidenceLevel(for parameter: String) -> Double {
        let parameterQuestions = self.questions.filter { $0.parameter == parameter }
        guard !parameterQuestions.isEmpty else { return 0.0 }
        let answered = parameterQuestions.filter { self.answers[$0.id] != nil }.count
        let completionRatio = Double(answered) / Double(parameterQuestions.count)
        let globalConfidence = self.calculateResponseConfidence()
        return min(1, completionRatio * 0.7 + globalConfidence * 0.3)
    }

    // MARK: - Validation & Response Analysis

    /// Validates response consistency and patterns
    func validateResponses() -> ValidationResult {
        if let cachedResult = _validationResult {
            return cachedResult
        }

        var warnings: [String] = []
        var confidence = self.calculateResponseConfidence()

        // CRIT-002 Fix: Check completion rate first - require minimum 80%
        let completionRate = Double(answers.count) / Double(self.questions.count)
        if completionRate < 0.8 {
            warnings.append(
                "Quiz completion below 80% threshold. Please answer at least 28 of 35 questions for valid results."
            )
            confidence *= 0.5 // Significant confidence reduction for low completion
        }

        // Check for straight-lining (all same answers)
        if self.isStraightLining() {
            warnings.append(
                "Your responses show a pattern of straight-lining, which may indicate inattentive responding."
            )
            confidence *= 0.8 // Reduce confidence for potential straight-lining
        }

        // Check for inconsistent responses to similar questions
        if self.hasInconsistentResponses() {
            warnings.append("Some of your responses to similar questions appear inconsistent.")
            confidence *= 0.85
        }

        // Check for response patterns that might indicate random responding
        if self.showsRandomResponsePattern() {
            warnings.append("Your response pattern suggests potential random or inattentive responding.")
            confidence *= 0.7
        }

        if completionRate < 0.9 {
            warnings.append(
                "You've completed \(Int(completionRate * 100))% of the questions. Completing all questions provides more accurate results."
            )
            confidence *= 0.9
        }

        // Check for extreme responding (all high or all low)
        if self.isExtremeResponding() {
            warnings.append("Your responses show a pattern of extreme responding (all high or all low).")
            confidence *= 0.85
        }

        let result = ValidationResult(
            isValid: confidence >= self.validationThreshold && completionRate >= 0.8,
            warnings: warnings,
            confidence: min(max(confidence, 0), 1), // Ensure confidence is between 0 and 1
            completionRate: completionRate
        )

        self._validationResult = result
        return result
    }

    /// Calculates the confidence score based on response patterns
    private func calculateResponseConfidence() -> Double {
        guard !self.answers.isEmpty else { return 0.0 }

        var confidence = 0.0
        let completionRate = Double(answers.count) / Double(self.questions.count)

        // Base confidence on completion rate (50% weight)
        confidence += completionRate * 0.5

        // Check response time consistency (if available)
        // This is a placeholder - in a real app, you'd track response times
        let timeConsistencyScore = 0.9 // Assume good time consistency by default
        confidence += timeConsistencyScore * 0.3

        // Check for response variability (20% weight)
        let responseVariability = self.calculateResponseVariability()
        confidence += responseVariability * 0.2

        return min(max(confidence, 0), 1) // Ensure between 0 and 1
    }

    private func calculateResponseVariability() -> Double {
        let answerValues = Array(answers.values)
        guard !answerValues.isEmpty else { return 0.0 }

        let mean = Double(answerValues.reduce(0, +)) / Double(answerValues.count)
        let variance =
            answerValues.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(answerValues.count)

        // Normalize variance to 0-1 range (assuming 1-4 scale)
        // A variance of around 1.33 is considered good (not too consistent, not too random)
        return min(variance / 1.33, 1.0)
    }

    private func isStraightLining() -> Bool {
        // If all answers are the same (except for unanswered questions)
        let answerValues = Set(answers.values)
        return answerValues.count <= 2 && self.answers.count > 3
    }

    private func hasInconsistentResponses() -> Bool {
        // Check for similar questions with opposite answers
        // This is a simplified version - in a real app, you'd map related questions

        // Example: Check if questions about similar concepts have opposite answers
        let epsilonQuestions = self.questions.filter { $0.parameter == "epsilon" }
        var inconsistencyCount = 0

        for firstIndex in 0 ..< (epsilonQuestions.count - 1) {
            for secondIndex in (firstIndex + 1) ..< epsilonQuestions.count {
                if let answer1 = answers[epsilonQuestions[firstIndex].id],
                   let answer2 = answers[epsilonQuestions[secondIndex].id],
                   abs(answer1 - answer2) >= 3 { // Big difference in answers
                    inconsistencyCount += 1
                }
            }
        }

        return inconsistencyCount > epsilonQuestions.count / 2
    }

    private func showsRandomResponsePattern() -> Bool {
        // Check for patterns that might indicate random responding
        // This is a simplified check - in practice, you'd use more sophisticated methods

        let answerValues = Array(answers.values)
        guard answerValues.count > 5 else { return false }

        // Check for alternating patterns (e.g., 1, 4, 1, 4, 1, 4)
        var alternatingPattern = true
        for index in 2 ..< answerValues.count where answerValues[index] != answerValues[index - 2] {
            alternatingPattern = false
            break
        }

        return alternatingPattern
    }

    private func isExtremeResponding() -> Bool {
        // Check if most answers are at the extremes (1 or 4)
        let extremeCount = self.answers.values.filter { $0 == 1 || $0 == 4 }.count
        return Double(extremeCount) / Double(self.answers.count) > 0.8 // More than 80% extreme responses
    }

    // MARK: - Scoring

    func calculateScore() -> (profile: APGIProfile, validation: ValidationResult) {
        let (rawScores, maxPossible) = self.accumulateScores()
        let normalizedScores = self.normalizedPercentiles(
            rawScores: rawScores, maxPossible: maxPossible
        )

        let validation = self.validateResponses()

        var adjustedScores = normalizedScores
        if !validation.isValid {
            for (param, score) in adjustedScores {
                adjustedScores[param] = score * validation.confidence
            }
        }

        let profile = APGIProfile(
            epsilon: adjustedScores["epsilon"] ?? 0,
            precision: adjustedScores["precision"] ?? 0,
            threshold: adjustedScores["threshold"] ?? 0,
            somaticBias: adjustedScores["somatic"] ?? 0,
            interactionScore: calculateInteractionScore(from: rawScores),
            temporalStability: normalizedScores["temporal"] ?? 0,
            environmentalFit: normalizedScores["environment"] ?? 0
        )

        return (profile, validation)
    }

    func calculatePartialScore() -> APGIProfile {
        let (rawScores, maxPossible) = self.accumulateScores()
        let normalizedScores = self.normalizedPercentiles(
            rawScores: rawScores, maxPossible: maxPossible
        )

        return APGIProfile(
            epsilon: normalizedScores["epsilon"] ?? 0,
            precision: normalizedScores["precision"] ?? 0,
            threshold: normalizedScores["threshold"] ?? 0,
            somaticBias: normalizedScores["somatic"] ?? 0,
            interactionScore: normalizedScores["interactions"] ?? 0,
            temporalStability: normalizedScores["temporal"] ?? 0,
            environmentalFit: normalizedScores["environment"] ?? 0
        )
    }

    static func calculateAPGIProfile(from results: [String: Int]) -> APGIProfile {
        // Check if the results are already aggregated scores rather than raw answers
        let hasAggregatedKeys = results.keys.contains(where: {
            ["epsilon", "precision", "threshold", "somatic"].contains($0)
        })

        if hasAggregatedKeys {
            return APGIProfile(
                epsilon: Double(results["epsilon"] ?? 0),
                precision: Double(results["precision"] ?? 0),
                threshold: Double(results["threshold"] ?? 0),
                somaticBias: Double(results["somatic"] ?? 0),
                interactionScore: Double(results["interactions"] ?? 0),
                temporalStability: Double(results["temporal"] ?? 0),
                environmentalFit: Double(results["environment"] ?? 0)
            )
        }

        // Fallback for legacy data (raw question answers with stringified integer keys)
        let intKeyResults = Dictionary(
            uniqueKeysWithValues: results.compactMap { key, value in
                Int(key).map { ($0, value) }
            }
        )

        return self.calculateScore(from: intKeyResults)
    }

    private static func calculateScore(from answers: [Int: Int]) -> APGIProfile {
        var rawScores = [String: Double]()
        var maxPossible = [String: Double]()

        // Use the static copy of questions
        let questions = Self.allQuestions

        for question in questions {
            guard let answer = answers[question.id] else { continue }

            let weight = ScoringWeights.questionReliability[question.id] ?? 0.8
            let paramWeight = ScoringWeights.parameterWeights[question.parameter] ?? 1.0

            let weightedValue = Double(answer) * weight * paramWeight
            rawScores[question.parameter, default: 0] += weightedValue
            maxPossible[question.parameter, default: 0] += 4.0 * weight * paramWeight
        }

        var normalizedScores = [String: Double]()
        for (param, raw) in rawScores {
            guard let max = maxPossible[param], max > 0 else { continue }
            normalizedScores[param] = (raw / max) * 100
        }

        return APGIProfile(
            epsilon: normalizedScores["epsilon"] ?? 0,
            precision: normalizedScores["precision"] ?? 0,
            threshold: normalizedScores["threshold"] ?? 0,
            somaticBias: normalizedScores["somatic"] ?? 0,
            interactionScore: calculateStaticInteractionScore(from: rawScores),
            temporalStability: normalizedScores["temporal"] ?? 0,
            environmentalFit: normalizedScores["environment"] ?? 0
        )
    }

    private static func calculateStaticInteractionScore(from rawScores: [String: Double]) -> Double {
        let epsilon = rawScores["epsilon"] ?? 0
        let precision = rawScores["precision"] ?? 0
        let threshold = rawScores["threshold"] ?? 0
        let somatic = rawScores["somatic"] ?? 0
        let interactions = rawScores["interactions"] ?? 0

        let interactionWeight = 0.6
        let derivedWeight = 0.4

        let rawInteractionScore =
            (interactions * interactionWeight)
                + ((epsilon * precision * 0.3 + epsilon * somatic * 0.3 + threshold * (1 - epsilon / 100)
                        * 0.4) * derivedWeight)

        let maxInteractionScore = 20.0
        return min(100, (rawInteractionScore / maxInteractionScore) * 100)
    }

    private func calculateInteractionScore(from rawScores: [String: Double]) -> Double {
        // Complex interaction scoring based on parameter relationships
        let epsilon = rawScores["epsilon"] ?? 0
        let precision = rawScores["precision"] ?? 0
        let threshold = rawScores["threshold"] ?? 0
        let somatic = rawScores["somatic"] ?? 0
        let interactions = rawScores["interactions"] ?? 0

        // Weighted interaction score
        let interactionWeight = 0.6
        let derivedWeight = 0.4

        let rawInteractionScore =
            (interactions * interactionWeight)
                + ((epsilon * precision * 0.3 + epsilon * somatic * 0.3 + threshold * (1 - epsilon / 100)
                        * 0.4) * derivedWeight)

        // Normalize (assuming max possible interaction score)
        let maxInteractionScore = 20.0 // Approximate max based on question weights
        return min(100, (rawInteractionScore / maxInteractionScore) * 100)
    }

    private func accumulateScores() -> ([String: Double], [String: Double]) {
        var rawScores = [String: Double]()
        var maxPossible = [String: Double]()

        for question in self.questions {
            guard let answer = answers[question.id] else { continue }

            let weight = ScoringWeights.questionReliability[question.id] ?? 0.8
            let paramWeight = ScoringWeights.parameterWeights[question.parameter] ?? 1.0

            let weightedValue = Double(answer) * weight * paramWeight
            rawScores[question.parameter, default: 0] += weightedValue
            maxPossible[question.parameter, default: 0] += 4.0 * weight * paramWeight
        }

        return (rawScores, maxPossible)
    }

    private func normalizedPercentiles(rawScores: [String: Double], maxPossible: [String: Double]) -> [String: Double] {
        var normalizedScores = [String: Double]()

        for (param, raw) in rawScores {
            guard let max = maxPossible[param], max > 0 else { continue }
            normalizedScores[param] = (raw / max) * 100
        }

        return normalizedScores
    }

    /// Returns raw scores as [String: Int] for backward compatibility with ProfileManager
    /// Used by ResultsView.swift for profile creation where ProfileManager expects integer scores
    /// New scoring methods return APGIProfile with Double values, but this method maintains compatibility
    func calculateRawScore() -> [String: Int] {
        var scores = [
            "epsilon": 0,
            "precision": 0,
            "threshold": 0,
            "somatic": 0,
            "interactions": 0,
            "temporal": 0,
            "environment": 0
        ]

        for question in self.questions {
            if let answer = answers[question.id] {
                scores[question.parameter, default: 0] += answer
            }
        }

        return scores
    }
}

struct QuizQuestion: Identifiable {
    let id: Int
    let text: String
    let options: [QuizOption]
    let parameter: String
}

struct QuizOption: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let note: String
    let scientificBasis: String?
    let example: String?
    let relatedStates: [Int]?
    let value: Int

    init(
        text: String,
        note: String,
        scientificBasis: String? = nil,
        example: String? = nil,
        relatedStates: [Int]? = nil,
        value: Int
    ) {
        self.text = text
        self.note = note
        self.scientificBasis = scientificBasis
        self.example = example
        self.relatedStates = relatedStates
        self.value = value
    }

    init(text: String, note: String, value: Int) {
        self.init(
            text: text, note: note, scientificBasis: nil, example: nil, relatedStates: nil, value: value
        )
    }

    var tooltip: String {
        let basis = self.scientificBasis ?? "Additional scientific context is being compiled."
        let exampleText = self.example.map { "Example: \($0)\n" } ?? ""
        let related = self.relatedStates?
            .map { getStateName($0) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        let relatedText = related ?? "No specific states linked yet."

        return """
        This response suggests: \(self.note)

        Scientific basis: \(basis)

        \(exampleText)People who select this often experience: \(relatedText)
        """
    }

    static func == (lhs: QuizOption, rhs: QuizOption) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

private func getStateName(_ id: Int) -> String {
    PsychologicalState.exampleStates.first { $0.id == id }?.name ?? "State \(id)"
}
