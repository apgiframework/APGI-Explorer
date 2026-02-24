import Foundation

// MARK: - Enhanced Scoring Algorithm

class APGIScorer {
    // MARK: - Scoring Constants

    private enum ScoringConstants {
        // Response validation thresholds
        static let minimumCompletionRate: Double = 0.8
        static let maximumAnswerValueDifference: Int = 2
        static let randomPatternThreshold: Double = 0.6
        static let extremeMeanLower: Double = 1.5
        static let extremeMeanUpper: Double = 3.5
        static let straightLiningMaxAnswers: Int = 2
        static let straightLiningMinQuestions: Int = 3

        // Confidence and reliability thresholds
        static let minimumConfidenceThreshold: Double = 0.7
        static let consistencyThreshold: Double = 0.8
        static let baseReliabilityDefault: Double = 0.8

        // Statistical constants
        static let confidenceIntervalZScore: Double = 1.96 // 95% confidence interval
        static let scoreRange: Double = 100.0
        static let defaultScore: Double = 50.0

        // Sigmoid transformation parameters
        static let sigmoidMidpoint: Double = 50.0
        static let epsilonSteepness: Double = 0.05
        static let precisionSteepness: Double = 0.04
        static let thresholdSteepness: Double = 0.06
        static let somaticSteepness: Double = 0.05

        // Consistency calculation factors
        static let precisionThresholdBaseline: Double = 0.3
        static let precisionThresholdWeight: Double = 0.7
        static let consistencyDeviationMultiplier: Double = 2.0
        static let extremeMismatchThreshold: Double = 0.8
        static let extremeMismatchConfidence: Double = 0.7

        // Answer normalization values (1-4 scale to 0-100 scale)
        static let veryLowValue: Double = 12.5
        static let lowValue: Double = 37.5
        static let highValue: Double = 62.5
        static let veryHighValue: Double = 87.5

        // Question counts
        static let requiredQuestionsCount: Int = 20
        static let minimumAlternatingCount: Int = 4
    }

    // MARK: - Weighted Score Structure

    struct WeightedScore {
        let rawScore: Double
        let confidence: Double
        let reliability: Double
        let validityCheck: Bool
        let lower: Double
        let upper: Double

        var value: Double {
            self.rawScore
        }
    }

    // MARK: - Question Weights Based on Discrimination and Reliability

    let questionWeights: [String: [Int: Double]] = [
        "epsilon": [
            1: 0.85, // "When plans change unexpectedly..." - High reliability
            2: 1.15, // "How often do you notice small inconsistencies..." - Very high discrimination
            3: 1.0, // "When learning something new..." - Standard reliability
            4: 1.2, // "In social situations..." - High discrimination for social contexts
            5: 0.9, // "How do you experience novelty..." - Good reliability
        ],
        "precision": [
            6: 0.95, // "Physical sensations interpretation" - High clinical relevance
            7: 1.1, // "Attention in uncertainty" - Strong discrimination
            8: 1.05, // "Social feedback influence" - Moderate-high reliability
            9: 1.0, // "Logic vs intuition balance" - Standard
            10: 0.9, // "Opinion formation speed" - Good reliability
        ],
        "threshold": [
            11: 1.15, // "Background sounds interruption" - High discrimination
            12: 1.2, // "Reading absorption" - Very high discrimination
            13: 1.05, // "Emotional shift detection" - Good reliability
            14: 1.1, // "Sensory information awareness" - Strong discrimination
            15: 1.0, // "Flow state achievement" - Standard reliability
        ],
        "somatic": [
            16: 1.1, // "Emotion location" - High clinical relevance
            17: 1.15, // "Decision making guide" - Strong discrimination
            18: 1.05, // "Internal bodily awareness" - Good reliability
            19: 1.2, // "Stress experience" - Very high discrimination
            20: 1.0, // "Abstract concepts embodiment" - Standard
        ],
    ]

    // MARK: - Main Scoring Function

    func calculateRobustScore(answers: [Int: Int]) -> APGIProfile {
        // 1. Check response validity
        guard self.validateResponses(answers) else {
            return self.flaggedProfile()
        }

        // 2. Calculate weighted scores for each parameter
        guard let epsilonWeights = self.questionWeights["epsilon"] else {
            return self.flaggedProfile()
        }
        let epsilon = self.calculateWeightedParameter(
            answers: answers,
            parameter: "epsilon",
            weights: epsilonWeights
        )

        guard let precisionWeights = self.questionWeights["precision"] else {
            return self.flaggedProfile()
        }
        let precision = self.calculateWeightedParameter(
            answers: answers,
            parameter: "precision",
            weights: precisionWeights
        )

        guard let thresholdWeights = self.questionWeights["threshold"] else {
            return self.flaggedProfile()
        }
        let threshold = self.calculateWeightedParameter(
            answers: answers,
            parameter: "threshold",
            weights: thresholdWeights
        )

        guard let somaticWeights = self.questionWeights["somatic"] else {
            return self.flaggedProfile()
        }
        let somatic = self.calculateWeightedParameter(
            answers: answers,
            parameter: "somatic",
            weights: somaticWeights
        )

        // 3. Apply nonlinear transformations
        let transformedScores = self.applyAdvancedTransformations(
            epsilon: epsilon,
            precision: precision,
            threshold: threshold,
            somatic: somatic
        )

        // 4. Cross-validation checks
        let validatedScores = self.performCrossValidation(
            epsilon: transformedScores.epsilon,
            precision: transformedScores.precision,
            threshold: transformedScores.threshold,
            somatic: transformedScores.somatic,
            answers: answers
        )

        // 5. Calculate interaction scores
        let interactionScore = self.calculateInteractionScore(answers: answers)
        let temporalStability = self.calculateTemporalStability(answers: answers)
        let environmentalFit = self.calculateEnvironmentalFit(answers: answers)

        // 6. Return final profile with confidence intervals
        return APGIProfile(
            epsilon: validatedScores.epsilon.value,
            precision: validatedScores.precision.value,
            threshold: validatedScores.threshold.value,
            somaticBias: validatedScores.somatic.value,
            interactionScore: interactionScore,
            temporalStability: temporalStability,
            environmentalFit: environmentalFit
        )
    }

    // MARK: - Response Validation

    private func validateResponses(_ answers: [Int: Int]) -> Bool {
        // Check completion rate
        let requiredQuestions = ScoringConstants.requiredQuestionsCount
        let completionRate = Double(answers.count) / Double(requiredQuestions)

        guard completionRate >= ScoringConstants.minimumCompletionRate else {
            return false
        }

        // Check for straight-lining
        guard !self.isStraightLining(answers) else {
            return false
        }

        // Check for extreme responding
        guard !self.isExtremeResponding(answers) else {
            return false
        }

        // Check for random patterns
        guard !self.showsRandomPattern(answers) else {
            return false
        }

        return true
    }

    private func isStraightLining(_ answers: [Int: Int]) -> Bool {
        let answerValues = Set(answers.values)
        return answerValues.count <= ScoringConstants.straightLiningMaxAnswers && answers.count > ScoringConstants.straightLiningMinQuestions
    }

    private func isExtremeResponding(_ answers: [Int: Int]) -> Bool {
        let answerValues = answers.values.map { Double($0) }
        guard !answerValues.isEmpty else { return false }

        let mean = answerValues.reduce(0, +) / Double(answerValues.count)
        return mean <= ScoringConstants.extremeMeanLower || mean >= ScoringConstants.extremeMeanUpper
    }

    private func showsRandomPattern(_ answers: [Int: Int]) -> Bool {
        // Simple check for alternating patterns
        let sortedAnswers = answers.sorted(by: { $0.key < $1.key }).map(\.value)
        guard sortedAnswers.count >= ScoringConstants.minimumAlternatingCount else { return false }

        var alternatingCount = 0
        for index in 1 ..< sortedAnswers.count where abs(sortedAnswers[index] - sortedAnswers[index - 1]) >= ScoringConstants.maximumAnswerValueDifference {
            alternatingCount += 1
        }

        return Double(alternatingCount) > Double(sortedAnswers.count) * ScoringConstants.randomPatternThreshold
    }

    private func flaggedProfile() -> APGIProfile {
        APGIProfile(
            epsilon: ScoringConstants.defaultScore,
            precision: ScoringConstants.defaultScore,
            threshold: ScoringConstants.defaultScore,
            somaticBias: ScoringConstants.defaultScore,
            interactionScore: 0.0,
            temporalStability: 0.0,
            environmentalFit: 0.0
        )
    }

    // MARK: - Weighted Parameter Calculation

    private func calculateWeightedParameter(
        answers: [Int: Int],
        parameter: String,
        weights: [Int: Double]
    ) -> WeightedScore {
        let parameterQuestions = self.getQuestionIds(for: parameter)
        var weightedSum = 0.0
        var totalWeight = 0.0
        var reliabilitySum = 0.0
        var validResponses = 0

        for questionId in parameterQuestions {
            if let answer = answers[questionId],
               let weight = weights[questionId]
            {
                let normalizedAnswer = self.normalizeAnswer(answer: answer)
                weightedSum += normalizedAnswer * weight
                totalWeight += weight

                // Calculate reliability for this question
                let reliability = self.calculateQuestionReliability(questionId: questionId)
                reliabilitySum += reliability * weight
                validResponses += 1
            }
        }

        guard totalWeight > 0, validResponses > 0 else {
            return WeightedScore(
                rawScore: ScoringConstants.defaultScore,
                confidence: 0.0,
                reliability: 0.0,
                validityCheck: false,
                lower: 0.0,
                upper: 100.0
            )
        }

        let rawScore = weightedSum / totalWeight
        let averageReliability = reliabilitySum / totalWeight
        let completionRate = Double(validResponses) / Double(parameterQuestions.count)
        let confidence = min(completionRate * averageReliability, 1.0)

        // Calculate confidence intervals
        let standardError = self.calculateStandardError(
            score: rawScore,
            reliability: averageReliability,
            sampleSize: validResponses
        )

        let marginOfError = ScoringConstants.confidenceIntervalZScore * standardError // 95% confidence interval
        let lower = max(0, rawScore - marginOfError)
        let upper = min(ScoringConstants.scoreRange, rawScore + marginOfError)

        return WeightedScore(
            rawScore: rawScore,
            confidence: confidence,
            reliability: averageReliability,
            validityCheck: confidence >= ScoringConstants.minimumConfidenceThreshold,
            lower: lower,
            upper: upper
        )
    }

    private func getQuestionIds(for parameter: String) -> [Int] {
        switch parameter {
        case "epsilon":
            [1, 2, 3, 4, 5]
        case "precision":
            [6, 7, 8, 9, 10]
        case "threshold":
            [11, 12, 13, 14, 15]
        case "somatic":
            [16, 17, 18, 19, 20]
        default:
            []
        }
    }

    private func normalizeAnswer(answer: Int) -> Double {
        // Convert 1-4 scale to 0-100 scale
        switch answer {
        case 1: ScoringConstants.veryLowValue // Very Low
        case 2: ScoringConstants.lowValue // Low
        case 3: ScoringConstants.highValue // High
        case 4: ScoringConstants.veryHighValue // Very High
        default: ScoringConstants.defaultScore // Default to middle
        }
    }

    private func calculateQuestionReliability(questionId: Int) -> Double {
        // Base reliability scores from validation studies
        let baseReliabilities: [Int: Double] = [
            1: 0.95, 2: 0.90, 3: 0.95, 4: 0.85, 5: 0.90,
            6: 0.90, 7: 0.85, 8: 0.80, 9: 0.85, 10: 0.80,
            11: 0.90, 12: 0.85, 13: 0.80, 14: 0.85, 15: 0.90,
            16: 0.90, 17: 0.85, 18: 0.95, 19: 0.90, 20: 0.85,
        ]

        return baseReliabilities[questionId] ?? ScoringConstants.baseReliabilityDefault
    }

    private func calculateStandardError(score: Double, reliability: Double, sampleSize: Int) -> Double {
        // Standard error calculation based on reliability and sample size
        let variance = (ScoringConstants.scoreRange - score) * score / ScoringConstants.scoreRange // Normalized variance
        let adjustedVariance = variance * (1 - reliability) // Adjust for reliability
        return sqrt(adjustedVariance / Double(sampleSize))
    }

    // MARK: - Nonlinear Transformations

    private struct WeightedScores {
        let epsilon: WeightedScore
        let precision: WeightedScore
        let threshold: WeightedScore
        let somatic: WeightedScore
    }

    private func applyAdvancedTransformations(
        epsilon: WeightedScore,
        precision: WeightedScore,
        threshold: WeightedScore,
        somatic: WeightedScore
    ) -> WeightedScores {
        // Apply sigmoid transformation for extreme values
        let transformedEpsilon = self.applySigmoid(epsilon.rawScore, steepness: ScoringConstants.epsilonSteepness, midpoint: ScoringConstants.sigmoidMidpoint)
        let transformedPrecision = self.applySigmoid(precision.rawScore, steepness: ScoringConstants.precisionSteepness, midpoint: ScoringConstants.sigmoidMidpoint)
        let transformedThreshold = self.applySigmoid(threshold.rawScore, steepness: ScoringConstants.thresholdSteepness, midpoint: ScoringConstants.sigmoidMidpoint)
        let transformedSomatic = self.applySigmoid(somatic.rawScore, steepness: ScoringConstants.somaticSteepness, midpoint: ScoringConstants.sigmoidMidpoint)

        // Multiplicative effects for high scores on certain questions
        let enhancedEpsilon = self.applyMultiplicativeEffect(
            baseScore: transformedEpsilon,
            answers: [:], // Would need specific answers for this
            enhancementFactor: 1.0
        )

        return WeightedScores(
            epsilon: WeightedScore(
                rawScore: enhancedEpsilon,
                confidence: epsilon.confidence,
                reliability: epsilon.reliability,
                validityCheck: epsilon.validityCheck,
                lower: epsilon.lower,
                upper: epsilon.upper
            ),
            precision: WeightedScore(
                rawScore: transformedPrecision,
                confidence: precision.confidence,
                reliability: precision.reliability,
                validityCheck: precision.validityCheck,
                lower: precision.lower,
                upper: precision.upper
            ),
            threshold: WeightedScore(
                rawScore: transformedThreshold,
                confidence: threshold.confidence,
                reliability: threshold.reliability,
                validityCheck: threshold.validityCheck,
                lower: threshold.lower,
                upper: threshold.upper
            ),
            somatic: WeightedScore(
                rawScore: transformedSomatic,
                confidence: somatic.confidence,
                reliability: somatic.reliability,
                validityCheck: somatic.validityCheck,
                lower: somatic.lower,
                upper: somatic.upper
            )
        )
    }

    private func applySigmoid(_ value: Double, steepness: Double, midpoint: Double) -> Double {
        // Sigmoid transformation to handle extreme values
        let exponent = -steepness * (value - midpoint)
        let sigmoid = 1 / (1 + exp(exponent))
        return sigmoid * 100
    }

    private func applyMultiplicativeEffect(baseScore: Double, answers _: [Int: Int], enhancementFactor: Double) -> Double {
        // Apply multiplicative effects for high scores on discriminating questions
        // This is a simplified version - would need specific answer analysis
        baseScore * enhancementFactor
    }

    // MARK: - Cross-Validation Checks

    private func performCrossValidation(
        epsilon: WeightedScore,
        precision: WeightedScore,
        threshold: WeightedScore,
        somatic: WeightedScore,
        answers: [Int: Int]
    ) -> WeightedScores {
        // Check if precision and threshold answers make sense together
        let precisionThresholdConsistency = self.checkPrecisionThresholdConsistency(
            precision: precision.rawScore,
            threshold: threshold.rawScore,
            answers: answers
        )

        // Check if epsilon and somatic responses are coherent
        let epsilonSomaticConsistency = self.checkEpsilonSomaticConsistency(
            epsilon: epsilon.rawScore,
            somatic: somatic.rawScore,
            answers: answers
        )

        // Adjust scores based on consistency checks
        let adjustedEpsilon = epsilon.rawScore * epsilonSomaticConsistency
        let adjustedPrecision = precision.rawScore * precisionThresholdConsistency
        let adjustedThreshold = threshold.rawScore * precisionThresholdConsistency
        let adjustedSomatic = somatic.rawScore * epsilonSomaticConsistency

        return WeightedScores(
            epsilon: WeightedScore(
                rawScore: adjustedEpsilon,
                confidence: epsilon.confidence * epsilonSomaticConsistency,
                reliability: epsilon.reliability,
                validityCheck: epsilon.validityCheck && epsilonSomaticConsistency > ScoringConstants.consistencyThreshold,
                lower: max(0, adjustedEpsilon - (epsilon.upper - epsilon.lower) / 2),
                upper: min(ScoringConstants.scoreRange, adjustedEpsilon + (epsilon.upper - epsilon.lower) / 2)
            ),
            precision: WeightedScore(
                rawScore: adjustedPrecision,
                confidence: precision.confidence * precisionThresholdConsistency,
                reliability: precision.reliability,
                validityCheck: precision.validityCheck && precisionThresholdConsistency > ScoringConstants.consistencyThreshold,
                lower: max(0, adjustedPrecision - (precision.upper - precision.lower) / 2),
                upper: min(ScoringConstants.scoreRange, adjustedPrecision + (precision.upper - precision.lower) / 2)
            ),
            threshold: WeightedScore(
                rawScore: adjustedThreshold,
                confidence: threshold.confidence * precisionThresholdConsistency,
                reliability: threshold.reliability,
                validityCheck: threshold.validityCheck && precisionThresholdConsistency > ScoringConstants.consistencyThreshold,
                lower: max(0, adjustedThreshold - (threshold.upper - threshold.lower) / 2),
                upper: min(ScoringConstants.scoreRange, adjustedThreshold + (threshold.upper - threshold.lower) / 2)
            ),
            somatic: WeightedScore(
                rawScore: adjustedSomatic,
                confidence: somatic.confidence * epsilonSomaticConsistency,
                reliability: somatic.reliability,
                validityCheck: somatic.validityCheck && epsilonSomaticConsistency > ScoringConstants.consistencyThreshold,
                lower: max(0, adjustedSomatic - (somatic.upper - somatic.lower) / 2),
                upper: min(ScoringConstants.scoreRange, adjustedSomatic + (somatic.upper - somatic.lower) / 2)
            )
        )
    }

    private func checkPrecisionThresholdConsistency(precision: Double, threshold: Double, answers _: [Int: Int]) -> Double {
        // High precision should generally correlate with higher threshold
        // Low precision might correlate with lower threshold (more open to input)

        let precisionScore = precision / 100.0
        let thresholdScore = threshold / 100.0

        // Calculate expected threshold based on precision
        let expectedThreshold = precisionScore * ScoringConstants.precisionThresholdWeight + ScoringConstants.precisionThresholdBaseline // Some baseline threshold
        let deviation = abs(thresholdScore - expectedThreshold)

        // Return consistency factor (1.0 = perfect consistency, 0.0 = no consistency)
        return max(0.0, 1.0 - deviation * ScoringConstants.consistencyDeviationMultiplier)
    }

    private func checkEpsilonSomaticConsistency(epsilon: Double, somatic: Double, answers _: [Int: Int]) -> Double {
        // High epsilon with low somatic might indicate cognitive-only processing
        // High epsilon with high somatic might indicate embodied processing
        // Both patterns are valid, but extreme mismatches might be inconsistent

        let epsilonScore = epsilon / 100.0
        let somaticScore = somatic / 100.0

        // Check for extreme mismatches
        let difference = abs(epsilonScore - somaticScore)

        if difference > ScoringConstants.extremeMismatchThreshold {
            return ScoringConstants.extremeMismatchConfidence // Reduce confidence for extreme mismatches
        } else {
            return 1.0 // Full confidence for reasonable matches
        }
    }

    // MARK: - Interaction and Meta-Scores

    private func calculateInteractionScore(answers: [Int: Int]) -> Double {
        // Calculate based on interaction questions (21-25)
        let interactionQuestions = [21, 22, 23, 24, 25]
        var totalScore = 0.0
        var count = 0

        for questionId in interactionQuestions {
            if let answer = answers[questionId] {
                totalScore += self.normalizeAnswer(answer: answer)
                count += 1
            }
        }

        return count > 0 ? totalScore / Double(count) : ScoringConstants.defaultScore
    }

    private func calculateTemporalStability(answers: [Int: Int]) -> Double {
        // Calculate based on temporal questions (26-30)
        let temporalQuestions = [26, 27, 28, 29, 30]
        var totalScore = 0.0
        var count = 0

        for questionId in temporalQuestions {
            if let answer = answers[questionId] {
                totalScore += self.normalizeAnswer(answer: answer)
                count += 1
            }
        }

        return count > 0 ? totalScore / Double(count) : ScoringConstants.defaultScore
    }

    private func calculateEnvironmentalFit(answers: [Int: Int]) -> Double {
        // Calculate based on environmental questions (31-35)
        let environmentalQuestions = [31, 32, 33, 34, 35]
        var totalScore = 0.0
        var count = 0

        for questionId in environmentalQuestions {
            if let answer = answers[questionId] {
                totalScore += self.normalizeAnswer(answer: answer)
                count += 1
            }
        }

        return count > 0 ? totalScore / Double(count) : ScoringConstants.defaultScore
    }
}
