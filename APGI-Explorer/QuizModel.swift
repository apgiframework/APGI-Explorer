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

// MARK: - Profile Models

// Using ParameterLevel from ParameterValueTypes.swift instead of separate enums

/// Personal sessions stay on this device. Research sessions must use the server client.
class QuizModel: ObservableObject {
    nonisolated struct AnswerEvent: Codable, Equatable {
        let sequence: Int
        let itemID: Int
        let value: Int
        let previousValue: Int?
        /// Monotonic response latency in milliseconds since the item was presented.
        let latencyMS: Double
    }

    nonisolated struct Snapshot: Codable {
        let sessionID: UUID
        let instrumentID: String
        let analysisMode: String
        let excludedFromNorms: Bool
        let currentQuestionIndex: Int
        let answers: [Int: Int]
        let events: [AnswerEvent]
    }

    var questions: [QuizQuestion] { Self.allQuestions }
    @Published var answers: [Int: Int] = [:]
    @Published var currentQuestionIndex = 0
    private(set) var sessionID = UUID()
    private(set) var events: [AnswerEvent] = []
    private let clock = ContinuousClock()
    private var startedAt = ContinuousClock.now
    private var presentedAt = ContinuousClock.now

    var duration: TimeInterval { seconds(startedAt.duration(to: clock.now)) }
    var isComplete: Bool {
        Set(answers.keys) == APGIScorer.requiredItemIDs
          && answers.values.allSatisfy { (1...4).contains($0) }
    }

    private func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    func presentQuestion(at index: Int) {
        guard questions.indices.contains(index) else { return }
        currentQuestionIndex = index
        presentedAt = clock.now
    }

    func selectAnswer(for questionId: Int, answer: Int) {
        guard APGIScorer.requiredItemIDs.contains(questionId), (1...4).contains(answer) else { return }
        let previous = answers[questionId]
        guard previous != answer else { return }
        events.append(AnswerEvent(sequence: events.count, itemID: questionId, value: answer,
                                  previousValue: previous,
                                  latencyMS: max(0, seconds(presentedAt.duration(to: clock.now)) * 1000)))
        answers[questionId] = answer
        presentedAt = clock.now
    }

    func selectAnswer(_ answer: Int) {
        guard questions.indices.contains(currentQuestionIndex) else { return }
        selectAnswer(for: questions[currentQuestionIndex].id, answer: answer)
    }

    func restoreAnswers(_ restoredAnswers: [Int: Int]) {
        answers = restoredAnswers.filter {
            APGIScorer.requiredItemIDs.contains($0.key) && (1...4).contains($0.value)
        }
        presentedAt = clock.now
    }

    func snapshot(at index: Int) -> Snapshot {
        Snapshot(sessionID: sessionID, instrumentID: "apgi-explorer-35",
                 analysisMode: "exploratory", excludedFromNorms: true,
                 currentQuestionIndex: index, answers: answers, events: events)
    }

    func restore(_ snapshot: Snapshot) {
        guard snapshot.instrumentID == "apgi-explorer-35",
              snapshot.analysisMode == "exploratory", snapshot.excludedFromNorms else { return }
        sessionID = snapshot.sessionID
        events = snapshot.events
        restoreAnswers(snapshot.answers)
        presentQuestion(at: min(max(snapshot.currentQuestionIndex, 0), questions.count - 1))
    }

    func nextQuestion() { presentQuestion(at: min(currentQuestionIndex + 1, questions.count - 1)) }
    func previousQuestion() { presentQuestion(at: max(currentQuestionIndex - 1, 0)) }
    var hasAnsweredCurrentQuestion: Bool {
        questions.indices.contains(currentQuestionIndex) && answers[questions[currentQuestionIndex].id] != nil
    }

    // Compatibility for progress views: these values describe completion, not reliability.
    func questionsNeededForConfidence(target: Double = 0.9) -> Int? {
        let remaining = questions.count - answers.count
        return remaining > 0 ? remaining : nil
    }
    func confidenceLevel(for parameter: String) -> Double {
        let items = questions.filter { $0.parameter == parameter }
        guard !items.isEmpty else { return 0 }
        return Double(items.filter { answers[$0.id] != nil }.count) / Double(items.count)
    }
    func validateResponses() -> ValidationResult {
        let complete = isComplete
        let completion = Double(Set(answers.keys).intersection(APGIScorer.requiredItemIDs).count) / 35
        return ValidationResult(isValid: complete,
                                warnings: complete ? [] : ["Answer all 35 items with valid options to view a result."],
                                confidence: 0, completionRate: completion)
    }
    func calculateScore() -> (profile: APGIProfile?, validation: ValidationResult) {
        (try? APGIScorer().calculateRobustScore(answers: answers).get(), validateResponses())
    }
    func calculatePartialScore() -> APGIProfile {
        APGIScorer.descriptiveProfile(answers: answers)
    }
    static func calculateAPGIProfile(from results: [String: Int]) -> APGIProfile {
        // Stored aggregates are already scores; never reconstruct individual answers.
        APGIProfile(epsilon: Double(results["epsilon"] ?? 0),
                    precision: Double(results["precision"] ?? 0),
                    threshold: Double(results["threshold"] ?? 0),
                    somaticBias: Double(results["somatic"] ?? 0),
                    interactionScore: Double(results["interactions"] ?? 0),
                    temporalStability: Double(results["temporal"] ?? 0),
                    environmentalFit: Double(results["environment"] ?? 0))
    }
    func calculateRawScore() -> [String: Int] {
        guard let profile = calculateScore().profile else { return [:] }
        return ["epsilon": Int(profile.epsilon.rounded()), "precision": Int(profile.precision.rounded()),
                "threshold": Int(profile.threshold.rounded()), "somatic": Int(profile.somaticBias.rounded()),
                "interactions": Int(profile.interactionScore.rounded()),
                "temporal": Int(profile.temporalStability.rounded()), "environment": Int(profile.environmentalFit.rounded())]
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
