import Foundation
import Combine

class QuizModel: ObservableObject {
    @Published var questions: [QuizQuestion] = [
        // MARK: - Prediction Error Sensitivity (ε)
        QuizQuestion(
            id: 1,
            text: "When plans change unexpectedly, how do you react initially?",
            options: [
                QuizOption(text: "Hardly notice—just adapt smoothly", note: "Very Low ε", value: 1),
                QuizOption(text: "Notice but adapt quickly", note: "Low ε", value: 2),
                QuizOption(text: "Feel disrupted, need to recalibrate", note: "Moderate ε", value: 3),
                QuizOption(text: "Strong reaction—feels like system failure", note: "High ε", value: 4)
            ],
            parameter: "epsilon"
        ),
        QuizQuestion(
            id: 2,
            text: "How often do you notice small inconsistencies in your environment?",
            options: [
                QuizOption(text: "Rarely—things seem consistent", note: "Low ε", value: 1),
                QuizOption(text: "Sometimes notice obvious ones", note: "Moderate-Low ε", value: 2),
                QuizOption(text: "Frequently notice subtle mismatches", note: "Moderate-High ε", value: 3),
                QuizOption(text: "Constantly—my brain flags inconsistencies", note: "Very High ε", value: 4)
            ],
            parameter: "epsilon"
        ),
        QuizQuestion(
            id: 3,
            text: "When learning something new, how do you handle being wrong?",
            options: [
                QuizOption(text: "Hardly notice errors—keep going", note: "Low ε", value: 1),
                QuizOption(text: "Notice but don't dwell on errors", note: "Moderate ε", value: 2),
                QuizOption(text: "Errors feel significant—motivate correction", note: "High ε", value: 3),
                QuizOption(text: "Errors feel painful—strong urge to fix immediately", note: "Very High ε", value: 4)
            ],
            parameter: "epsilon"
        ),
        QuizQuestion(
            id: 4,
            text: "In social situations, how quickly do you notice when someone's words don't match their tone?",
            options: [
                QuizOption(text: "Often miss these mismatches", note: "Low ε", value: 1),
                QuizOption(text: "Notice only large discrepancies", note: "Moderate-Low ε", value: 2),
                QuizOption(text: "Quickly detect subtle incongruences", note: "Moderate-High ε", value: 3),
                QuizOption(text: "Immediately sense any mismatch", note: "Very High ε", value: 4)
            ],
            parameter: "epsilon"
        ),
        QuizQuestion(
            id: 5,
            text: "How do you experience novelty and new experiences?",
            options: [
                QuizOption(text: "Mostly comforting routine preferred", note: "Low ε", value: 1),
                QuizOption(text: "Enjoy some novelty in moderation", note: "Moderate ε", value: 2),
                QuizOption(text: "Seek novelty—it's energizing", note: "High ε", value: 3),
                QuizOption(text: "Need constant novelty—routine feels stifling", note: "Very High ε", value: 4)
            ],
            parameter: "epsilon"
        ),

        // MARK: - Precision Allocation (π)
        QuizQuestion(
            id: 6,
            text: "When you feel a physical sensation (like a twinge or ache), how do you interpret it?",
            options: [
                QuizOption(text: "Probably nothing—ignore it", note: "Low body precision", value: 1),
                QuizOption(text: "Note it but wait to see if continues", note: "Moderate body precision", value: 2),
                QuizOption(text: "Pay close attention—could be important", note: "High body precision", value: 3),
                QuizOption(text: "Immediately concerned—might be serious", note: "Very high body precision", value: 4)
            ],
            parameter: "precision"
        ),
        QuizQuestion(
            id: 7,
            text: "In uncertain situations, where does your attention naturally go?",
            options: [
                QuizOption(text: "To potential opportunities", note: "High reward precision", value: 1),
                QuizOption(text: "To gathering more information", note: "Balanced precision", value: 2),
                QuizOption(text: "To potential problems or threats", note: "High threat precision", value: 3),
                QuizOption(text: "To how my body feels about it", note: "High interoceptive precision", value: 4)
            ],
            parameter: "precision"
        ),
        QuizQuestion(
            id: 8,
            text: "How much do social feedback and others' opinions influence your decisions?",
            options: [
                QuizOption(text: "Minimal—I trust my own judgment", note: "Low social precision", value: 1),
                QuizOption(text: "Consider but don't overvalue", note: "Moderate social precision", value: 2),
                QuizOption(text: "Strongly influence my choices", note: "High social precision", value: 3),
                QuizOption(text: "Often override my own judgment", note: "Very high social precision", value: 4)
            ],
            parameter: "precision"
        ),
        QuizQuestion(
            id: 9,
            text: "When making decisions, how do you weigh logical analysis vs. intuitive feelings?",
            options: [
                QuizOption(text: "Almost entirely logical analysis", note: "High analytical precision", value: 1),
                QuizOption(text: "Mostly logic with some intuition", note: "Moderate balance", value: 2),
                QuizOption(text: "Equal weight to both", note: "Balanced precision", value: 3),
                QuizOption(text: "Intuition guides, logic confirms", note: "High intuitive precision", value: 4)
            ],
            parameter: "precision"
        ),
        QuizQuestion(
            id: 10,
            text: "How quickly do you form strong opinions or judgments?",
            options: [
                QuizOption(text: "Slowly—prefer to stay uncertain", note: "Low confidence precision", value: 1),
                QuizOption(text: "Moderately—after some consideration", note: "Moderate confidence", value: 2),
                QuizOption(text: "Fairly quickly with moderate confidence", note: "High confidence", value: 3),
                QuizOption(text: "Very quickly with high certainty", note: "Very high confidence precision", value: 4)
            ],
            parameter: "precision"
        ),

        // MARK: - Ignition Threshold (θₜ)
        QuizQuestion(
            id: 11,
            text: "When working deeply, how easily do background sounds interrupt your focus?",
            options: [
                QuizOption(text: "Almost never—deeply absorbed", note: "Very High θₜ", value: 4),
                QuizOption(text: "Only loud or salient sounds", note: "High θₜ", value: 3),
                QuizOption(text: "Moderate sounds break through", note: "Moderate θₜ", value: 2),
                QuizOption(text: "Almost any sound distracts me", note: "Low θₜ", value: 1)
            ],
            parameter: "threshold"
        ),
        QuizQuestion(
            id: 12,
            text: "How many thoughts/feelings/sensations are typically in your conscious awareness at once?",
            options: [
                QuizOption(text: "Just one or two focused elements", note: "High θₜ", value: 4),
                QuizOption(text: "A few related elements", note: "Moderate-High θₜ", value: 3),
                QuizOption(text: "Several different elements", note: "Moderate-Low θₜ", value: 2),
                QuizOption(text: "Many elements simultaneously", note: "Low θₜ", value: 1)
            ],
            parameter: "threshold"
        ),
        QuizQuestion(
            id: 13,
            text: "How quickly do you notice subtle changes in your emotional state?",
            options: [
                QuizOption(text: "Often miss until emotions are strong", note: "High θₜ", value: 1),
                QuizOption(text: "Notice moderate emotional shifts", note: "Moderate-High θₜ", value: 2),
                QuizOption(text: "Notice subtle emotional fluctuations", note: "Moderate-Low θₜ", value: 3),
                QuizOption(text: "Immediately aware of slightest shifts", note: "Low θₜ", value: 4)
            ],
            parameter: "threshold"
        ),
        QuizQuestion(
            id: 14,
            text: "In a busy environment, how much sensory information reaches conscious awareness?",
            options: [
                QuizOption(text: "Very little—I focus selectively", note: "High θₜ", value: 4),
                QuizOption(text: "Some relevant information", note: "Moderate-High θₜ", value: 3),
                QuizOption(text: "Quite a lot of the environment", note: "Moderate-Low θₜ", value: 2),
                QuizOption(text: "Almost everything registers", note: "Low θₜ", value: 1)
            ],
            parameter: "threshold"
        ),
        QuizQuestion(
            id: 15,
            text: "How easily can you achieve 'flow state' where self-awareness disappears?",
            options: [
                QuizOption(text: "Very easily and frequently", note: "High θₜ", value: 4),
                QuizOption(text: "Fairly easily when conditions right", note: "Moderate-High θₜ", value: 3),
                QuizOption(text: "Occasionally with effort", note: "Moderate-Low θₜ", value: 2),
                QuizOption(text: "Rarely—always self-aware", note: "Low θₜ", value: 1)
            ],
            parameter: "threshold"
        ),

        // MARK: - Somatic Bias (β)
        QuizQuestion(
            id: 16,
            text: "When you experience an emotion, where do you primarily feel it?",
            options: [
                QuizOption(text: "Mostly as thoughts about the emotion", note: "Very Low β", value: 1),
                QuizOption(text: "Some physical sensation but mostly thoughts", note: "Low β", value: 2),
                QuizOption(text: "Equal physical sensations and thoughts", note: "Moderate β", value: 3),
                QuizOption(text: "Overwhelmingly as physical sensations", note: "High β", value: 4)
            ],
            parameter: "somatic"
        ),
        QuizQuestion(
            id: 17,
            text: "When making important decisions, what's your primary guide?",
            options: [
                QuizOption(text: "Logical analysis and pros/cons", note: "Low β", value: 1),
                QuizOption(text: "Mostly logic with some gut feeling", note: "Moderate-Low β", value: 2),
                QuizOption(text: "Equal logic and bodily intuition", note: "Moderate-High β", value: 3),
                QuizOption(text: "Bodily feeling of rightness/wrongness", note: "High β", value: 4)
            ],
            parameter: "somatic"
        ),
        QuizQuestion(
            id: 18,
            text: "How aware are you of internal bodily states (heartbeat, breathing, muscle tension) throughout the day?",
            options: [
                QuizOption(text: "Rarely notice unless pointed out", note: "Low β", value: 1),
                QuizOption(text: "Occasionally notice when resting", note: "Moderate-Low β", value: 2),
                QuizOption(text: "Frequently aware throughout day", note: "Moderate-High β", value: 3),
                QuizOption(text: "Constantly aware of multiple signals", note: "High β", value: 4)
            ],
            parameter: "somatic"
        ),
        QuizQuestion(
            id: 19,
            text: "When stressed, what dominates your experience?",
            options: [
                QuizOption(text: "Worried thoughts and mental analysis", note: "Low β", value: 1),
                QuizOption(text: "Mostly thoughts with some body tension", note: "Moderate-Low β", value: 2),
                QuizOption(text: "Equal mental and physical symptoms", note: "Moderate β", value: 3),
                QuizOption(text: "Overwhelming physical sensations", note: "High β", value: 4)
            ],
            parameter: "somatic"
        ),
        QuizQuestion(
            id: 20,
            text: "How do you experience abstract concepts like 'freedom' or 'connection'?",
            options: [
                QuizOption(text: "As purely mental constructs", note: "Low β", value: 1),
                QuizOption(text: "Mostly mental with slight bodily sense", note: "Moderate-Low β", value: 2),
                QuizOption(text: "With clear bodily correlates", note: "Moderate-High β", value: 3),
                QuizOption(text: "As distinct bodily experiences", note: "High β", value: 4)
            ],
            parameter: "somatic"
        ),

        // MARK: - Parameter Interactions
        QuizQuestion(
            id: 21,
            text: "When something surprises you (high ε event), what happens next?",
            options: [
                QuizOption(text: "Quickly moves out of awareness", note: "High θₜ dominates", value: 1),
                QuizOption(text: "Stays in awareness but doesn't spiral", note: "Balanced interaction", value: 2),
                QuizOption(text: "Triggers bodily reactions that amplify it", note: "ε + β interaction", value: 3),
                QuizOption(text: "Becomes highly significant and urgent", note: "ε + π interaction", value: 4)
            ],
            parameter: "interactions"
        ),
        QuizQuestion(
            id: 22,
            text: "When you notice a bodily sensation, what typically happens?",
            options: [
                QuizOption(text: "It often fades quickly", note: "Low π on body signals", value: 1),
                QuizOption(text: "I note it but don't amplify it", note: "Moderate body precision", value: 2),
                QuizOption(text: "It captures attention and feels important", note: "High body π", value: 3),
                QuizOption(text: "It can trigger cascade of other sensations", note: "High β + high body π", value: 4)
            ],
            parameter: "interactions"
        ),
        QuizQuestion(
            id: 23,
            text: "In high-stimulation environments, what's your experience?",
            options: [
                QuizOption(text: "Overwhelmed quickly—need to leave", note: "Low θₜ + high ε", value: 1),
                QuizOption(text: "Manageable but draining", note: "Moderate parameters", value: 2),
                QuizOption(text: "Engaging and energizing", note: "High θₜ + moderate ε", value: 3),
                QuizOption(text: "Either overwhelming or engaging depending", note: "Context-dependent", value: 4)
            ],
            parameter: "interactions"
        ),
        QuizQuestion(
            id: 24,
            text: "When you make an error, how does it affect you?",
            options: [
                QuizOption(text: "Barely registers—move on quickly", note: "Low ε + high θₜ", value: 1),
                QuizOption(text: "Notice it, correct, move on", note: "Balanced response", value: 2),
                QuizOption(text: "Feel it physically as discomfort", note: "ε + β interaction", value: 3),
                QuizOption(text: "Becomes significant—dwell on it", note: "High ε + high π on errors", value: 4)
            ],
            parameter: "interactions"
        ),
        QuizQuestion(
            id: 25,
            text: "How do stress or emotions typically progress for you?",
            options: [
                QuizOption(text: "Start cognitive, may become physical if intense", note: "Low β initially", value: 1),
                QuizOption(text: "Simultaneous cognitive and physical", note: "Balanced", value: 2),
                QuizOption(text: "Start physical, then cognitive interpretation", note: "High β", value: 3),
                QuizOption(text: "Physical sensations amplify into feedback loops", note: "High β + low θₜ", value: 4)
            ],
            parameter: "interactions"
        ),

        // MARK: - Temporal Stability
        QuizQuestion(
            id: 26,
            text: "How consistent is your mental/emotional style across different contexts?",
            options: [
                QuizOption(text: "Varies dramatically with situation", note: "Highly context-dependent", value: 1),
                QuizOption(text: "Some variation but core style consistent", note: "Moderate stability", value: 2),
                QuizOption(text: "Fairly consistent across situations", note: "High stability", value: 3),
                QuizOption(text: "Extremely consistent regardless of context", note: "Very high stability", value: 4)
            ],
            parameter: "temporal"
        ),
        QuizQuestion(
            id: 27,
            text: "How long do emotional states typically last for you?",
            options: [
                QuizOption(text: "Minutes to hours—shift quickly", note: "Transient", value: 1),
                QuizOption(text: "Hours to a day or two", note: "Moderate duration", value: 2),
                QuizOption(text: "Days to weeks—lingering states", note: "Enduring", value: 3),
                QuizOption(text: "Weeks to months—chronic patterns", note: "Entrenched", value: 4)
            ],
            parameter: "temporal"
        ),
        QuizQuestion(
            id: 28,
            text: "How easily can you intentionally shift your mental state?",
            options: [
                QuizOption(text: "Very easily with simple techniques", note: "Highly malleable", value: 1),
                QuizOption(text: "Moderately easy with effort", note: "Malleable", value: 2),
                QuizOption(text: "Difficult—requires sustained practice", note: "Stable", value: 3),
                QuizOption(text: "Very difficult—feels fixed", note: "Highly stable/entrenched", value: 4)
            ],
            parameter: "temporal"
        ),
        QuizQuestion(
            id: 29,
            text: "How would friends describe your typical mental/emotional style?",
            options: [
                QuizOption(text: "Changes dramatically day to day", note: "Low temporal stability", value: 1),
                QuizOption(text: "Somewhat variable but recognizable", note: "Moderate stability", value: 2),
                QuizOption(text: "Quite consistent—they know what to expect", note: "High stability", value: 3),
                QuizOption(text: "Extremely consistent over years", note: "Very high stability", value: 4)
            ],
            parameter: "temporal"
        ),
        QuizQuestion(
            id: 30,
            text: "When you learn a new self-regulation technique, how long does it take to see changes?",
            options: [
                QuizOption(text: "Immediate effects", note: "Highly responsive", value: 1),
                QuizOption(text: "Days to weeks of practice", note: "Moderately responsive", value: 2),
                QuizOption(text: "Months of consistent practice", note: "Slow response", value: 3),
                QuizOption(text: "Minimal change despite effort", note: "Resistant to change", value: 4)
            ],
            parameter: "temporal"
        ),

        // MARK: - Environmental Fit
        QuizQuestion(
            id: 31,
            text: "In what environments do you feel most mentally effective?",
            options: [
                QuizOption(text: "Quiet, predictable, low-stimulation", note: "Fits low ε/high θₜ", value: 1),
                QuizOption(text: "Structured but with some novelty", note: "Balanced fit", value: 2),
                QuizOption(text: "Dynamic, changing, stimulating", note: "Fits high ε", value: 3),
                QuizOption(text: "Socially rich, emotionally engaged", note: "Fits high β/social π", value: 4)
            ],
            parameter: "environment"
        ),
        QuizQuestion(
            id: 32,
            text: "What environments are most challenging for you?",
            options: [
                QuizOption(text: "Highly unpredictable, chaotic", note: "Challenges low θₜ/high ε", value: 1),
                QuizOption(text: "Emotionally intense, conflictual", note: "Challenges high β", value: 2),
                QuizOption(text: "Boring, repetitive, monotonous", note: "Challenges high ε", value: 3),
                QuizOption(text: "Socially complex, ambiguous", note: "Challenges low social π", value: 4)
            ],
            parameter: "environment"
        ),
        QuizQuestion(
            id: 33,
            text: "How does physical comfort affect your cognitive performance?",
            options: [
                QuizOption(text: "Minimal effect—can work through discomfort", note: "Low β", value: 1),
                QuizOption(text: "Some effect but can override", note: "Moderate β", value: 2),
                QuizOption(text: "Significant effect—need reasonable comfort", note: "High β", value: 3),
                QuizOption(text: "Critical—cannot function if uncomfortable", note: "Very high β", value: 4)
            ],
            parameter: "environment"
        ),
        QuizQuestion(
            id: 34,
            text: "What type of work tasks suit you best?",
            options: [
                QuizOption(text: "Deep, focused, analytical work", note: "Fits high θₜ", value: 1),
                QuizOption(text: "Creative, novel problem-solving", note: "Fits high ε", value: 2),
                QuizOption(text: "Social, collaborative, people-focused", note: "Fits high social π", value: 3),
                QuizOption(text: "Practical, embodied, hands-on", note: "Fits high β", value: 4)
            ],
            parameter: "environment"
        ),
        QuizQuestion(
            id: 35,
            text: "How do you handle crisis or emergency situations?",
            options: [
                QuizOption(text: "Calm, focused, analytical", note: "High θₜ + low β", value: 1),
                QuizOption(text: "Alert, responsive, adaptable", note: "Balanced parameters", value: 2),
                QuizOption(text: "Physically activated, intuitive", note: "High β + moderate θₜ", value: 3),
                QuizOption(text: "Either extremely effective or overwhelmed", note: "Depends on parameter interaction", value: 4)
            ],
            parameter: "environment"
        )
    ]

    @Published var answers: [Int: Int] = [:]

    func selectAnswer(for questionId: Int, answer: Int) {
        answers[questionId] = answer
    }

    func calculateScore() -> [String: Int] {
        var scores = [
            "epsilon": 0,
            "precision": 0,
            "threshold": 0,
            "somatic": 0,
            "interactions": 0,
            "temporal": 0,
            "environment": 0
        ]

        for question in questions {
            if let answer = answers[question.id] {
                scores[question.parameter]! += answer
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
    let value: Int
    
    static func == (lhs: QuizOption, rhs: QuizOption) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
