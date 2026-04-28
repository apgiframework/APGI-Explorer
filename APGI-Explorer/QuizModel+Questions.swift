import Foundation

// MARK: - Quiz Questions Extension

extension QuizModel {
    static let allQuestions: [QuizQuestion] = [
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
                QuizOption(
                    text: "Constantly—my brain flags inconsistencies", note: "Very High ε", value: 4
                )
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
                QuizOption(
                    text: "Errors feel painful—strong urge to fix immediately", note: "Very High ε", value: 4
                )
            ],
            parameter: "epsilon"
        ),
        QuizQuestion(
            id: 4,
            text:
            "In social situations, how quickly do you notice when someone's words don't match their tone?",
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
                QuizOption(
                    text: "Need constant novelty—routine feels stifling", note: "Very High ε", value: 4
                )
            ],
            parameter: "epsilon"
        ),

        // MARK: - Precision Allocation (π)

        QuizQuestion(
            id: 6,
            text: "When you feel a physical sensation (like a twinge or ache), how do you interpret it?",
            options: [
                QuizOption(text: "Probably nothing—ignore it", note: "Low body precision", value: 1),
                QuizOption(
                    text: "Note it but wait to see if continues", note: "Moderate body precision", value: 2
                ),
                QuizOption(
                    text: "Pay close attention—could be important", note: "High body precision", value: 3
                ),
                QuizOption(
                    text: "Immediately concerned—might be serious", note: "Very high body precision", value: 4
                )
            ],
            parameter: "precision"
        ),
        QuizQuestion(
            id: 7,
            text: "In uncertain situations, where does your attention naturally go?",
            options: [
                QuizOption(text: "To potential opportunities", note: "High reward precision", value: 1),
                QuizOption(text: "To gathering more information", note: "Balanced precision", value: 2),
                QuizOption(
                    text: "To potential problems or threats", note: "High threat precision", value: 3
                ),
                QuizOption(
                    text: "To how my body feels about it", note: "High interoceptive precision", value: 4
                )
            ],
            parameter: "precision"
        ),
        QuizQuestion(
            id: 8,
            text: "How much do social feedback and others' opinions influence your decisions?",
            options: [
                QuizOption(text: "Minimal—I trust my own judgment", note: "Low social precision", value: 1),
                QuizOption(
                    text: "Consider but don't overvalue", note: "Moderate social precision", value: 2
                ),
                QuizOption(text: "Strongly influence my choices", note: "High social precision", value: 3),
                QuizOption(
                    text: "Often override my own judgment", note: "Very high social precision", value: 4
                )
            ],
            parameter: "precision"
        ),
        QuizQuestion(
            id: 9,
            text: "When making decisions, how do you weigh logical analysis vs. intuitive feelings?",
            options: [
                QuizOption(
                    text: "Almost entirely logical analysis", note: "High analytical precision", value: 1
                ),
                QuizOption(text: "Mostly logic with some intuition", note: "Moderate balance", value: 2),
                QuizOption(text: "Equal weight to both", note: "Balanced precision", value: 3),
                QuizOption(
                    text: "Intuition guides, logic confirms", note: "High intuitive precision", value: 4
                )
            ],
            parameter: "precision"
        ),
        QuizQuestion(
            id: 10,
            text: "How quickly do you form strong opinions or judgments?",
            options: [
                QuizOption(
                    text: "Slowly—prefer to stay uncertain", note: "Low confidence precision", value: 1
                ),
                QuizOption(
                    text: "Moderately—after some consideration", note: "Moderate confidence", value: 2
                ),
                QuizOption(
                    text: "Fairly quickly with moderate confidence", note: "High confidence", value: 3
                ),
                QuizOption(
                    text: "Very quickly with high certainty", note: "Very high confidence precision", value: 4
                )
            ],
            parameter: "precision"
        ),

        // MARK: - Action Threshold (τ)

        QuizQuestion(
            id: 11,
            text: "When facing a challenging task, what typically happens?",
            options: [
                QuizOption(text: "Act immediately without much thought", note: "Very low threshold", value: 1),
                QuizOption(
                    text: "Act after brief consideration", note: "Low threshold", value: 2
                ),
                QuizOption(
                    text: "Need significant preparation before acting", note: "High threshold", value: 3
                ),
                QuizOption(
                    text: "Often avoid or delay action due to high bar", note: "Very high threshold", value: 4
                )
            ],
            parameter: "threshold"
        ),
        QuizQuestion(
            id: 12,
            text: "How do you handle tasks with no clear 'right' way to do them?",
            options: [
                QuizOption(
                    text: "Just start and figure it out", note: "Very low threshold", value: 1
                ),
                QuizOption(
                    text: "Prefer some guidance but can improvise", note: "Low threshold", value: 2
                ),
                QuizOption(
                    text: "Need clear parameters before starting", note: "High threshold", value: 3
                ),
                QuizOption(
                    text: "Avoid until I have complete clarity", note: "Very high threshold", value: 4
                )
            ],
            parameter: "threshold"
        ),
        QuizQuestion(
            id: 13,
            text: "How easily do you switch between different types of activities?",
            options: [
                QuizOption(text: "Seamlessly—no transition needed", note: "Very low threshold", value: 1),
                QuizOption(
                    text: "With brief adjustment period", note: "Low threshold", value: 2
                ),
                QuizOption(
                    text: "Need time to shift mental gears", note: "High threshold", value: 3
                ),
                QuizOption(
                    text: "Difficult—each switch feels like starting over", note: "Very high threshold", value: 4
                )
            ],
            parameter: "threshold"
        ),
        QuizQuestion(
            id: 14,
            text: "When starting something new, how much 'activation energy' do you need?",
            options: [
                QuizOption(text: "Very little—ideas become action quickly", note: "Very low threshold", value: 1),
                QuizOption(
                    text: "Some motivation required", note: "Low threshold", value: 2
                ),
                QuizOption(
                    text: "Significant momentum needed", note: "High threshold", value: 3
                ),
                QuizOption(
                    text: "Often stay in planning/ideation phase", note: "Very high threshold", value: 4
                )
            ],
            parameter: "threshold"
        ),
        QuizQuestion(
            id: 15,
            text: "How do you approach decisions with incomplete information?",
            options: [
                QuizOption(
                    text: "Comfortable deciding with minimal data", note: "Very low threshold", value: 1
                ),
                QuizOption(text: "Decide with basic facts", note: "Low threshold", value: 2),
                QuizOption(
                    text: "Need substantial information", note: "High threshold", value: 3
                ),
                QuizOption(
                    text: "Paralyzed until I have near-complete information", note: "Very high threshold", value: 4
                )
            ],
            parameter: "threshold"
        ),

        // MARK: - Somatic Bias (β)

        QuizQuestion(
            id: 16,
            text: "When you're stressed, where do you feel it most?",
            options: [
                QuizOption(text: "Mentally—thoughts racing", note: "Low somatic bias", value: 1),
                QuizOption(
                    text: "Both mentally and physically", note: "Moderate somatic bias", value: 2
                ),
                QuizOption(
                    text: "Primarily in my body (tension, sensations)", note: "High somatic bias", value: 3
                ),
                QuizOption(
                    text: "Overwhelmingly physical—hard to think clearly", note: "Very high somatic bias", value: 4
                )
            ],
            parameter: "somatic"
        ),
        QuizQuestion(
            id: 17,
            text: "How much do physical sensations influence your mood?",
            options: [
                QuizOption(
                    text: "Minimal—mind determines mood", note: "Low somatic bias", value: 1
                ),
                QuizOption(text: "Some connection", note: "Moderate somatic bias", value: 2),
                QuizOption(
                    text: "Strong influence—body state = mood", note: "High somatic bias", value: 3
                ),
                QuizOption(
                    text: "Dominant—physical state primarily determines mood", note: "Very high somatic bias", value: 4
                )
            ],
            parameter: "somatic"
        ),
        QuizQuestion(
            id: 18,
            text: "How aware are you of your internal body state right now?",
            options: [
                QuizOption(text: "Not particularly aware", note: "Low interoception", value: 1),
                QuizOption(
                    text: "Somewhat aware", note: "Moderate interoception", value: 2
                ),
                QuizOption(
                    text: "Quite aware", note: "High interoception", value: 3
                ),
                QuizOption(
                    text: "Very tuned in to internal sensations", note: "Very high interoception", value: 4
                )
            ],
            parameter: "somatic"
        ),
        QuizQuestion(
            id: 19,
            text: "When you have a gut feeling about something, how do you treat it?",
            options: [
                QuizOption(
                    text: "Usually ignore—prefer logic", note: "Low somatic bias", value: 1
                ),
                QuizOption(text: "Consider but don't rely on it", note: "Moderate somatic bias", value: 2),
                QuizOption(
                    text: "Strong input into decisions", note: "High somatic bias", value: 3
                ),
                QuizOption(
                    text: "Often primary guide for decisions", note: "Very high somatic bias", value: 4
                )
            ],
            parameter: "somatic"
        ),
        QuizQuestion(
            id: 20,
            text: "How connected do you feel to your physical self?",
            options: [
                QuizOption(
                    text: "Mind and body feel somewhat separate", note: "Low somatic bias", value: 1
                ),
                QuizOption(
                    text: "Moderately connected", note: "Moderate somatic bias", value: 2
                ),
                QuizOption(
                    text: "Strongly connected—integrated experience", note: "High somatic bias", value: 3
                ),
                QuizOption(
                    text: "Body is central to my sense of self", note: "Very high somatic bias", value: 4
                )
            ],
            parameter: "somatic"
        ),

        // MARK: - Parameter Interactions

        QuizQuestion(
            id: 21,
            text: "How do you react when expectations aren't met?",
            options: [
                QuizOption(
                    text: "Recalibrate quickly and continue", note: "Low ε, low threshold", value: 1
                ),
                QuizOption(
                    text: "Pause to reassess, then adapt", note: "Moderate response", value: 2
                ),
                QuizOption(
                    text: "Strongly affected, slow to recover", note: "High ε, high threshold", value: 3
                ),
                QuizOption(
                    text: "Deep disruption, need extensive processing", note: "Very high ε + threshold", value: 4
                )
            ],
            parameter: "interactions"
        ),
        QuizQuestion(
            id: 22,
            text: "How do you balance external demands with internal needs?",
            options: [
                QuizOption(text: "Easily prioritize internal needs", note: "Low social precision", value: 1),
                QuizOption(
                    text: "Consider both, slight internal bias", note: "Balanced with internal lean", value: 2
                ),
                QuizOption(
                    text: "Often prioritize external demands", note: "High social precision", value: 3
                ),
                QuizOption(
                    text: "Frequently override internal needs for others", note: "Very high social precision", value: 4
                )
            ],
            parameter: "interactions"
        ),
        QuizQuestion(
            id: 23,
            text: "When plans fail, how do you recover?",
            options: [
                QuizOption(
                    text: "Immediately generate alternatives", note: "Low ε, low threshold", value: 1
                ),
                QuizOption(
                    text: "Brief pause, then replan", note: "Moderate recovery", value: 2
                ),
                QuizOption(
                    text: "Need significant time to regroup", note: "High ε + threshold", value: 3
                ),
                QuizOption(
                    text: "Often get stuck in disappointment", note: "Very high ε, high threshold", value: 4
                )
            ],
            parameter: "interactions"
        ),
        QuizQuestion(
            id: 24,
            text: "How do novelty-seeking and routine-comfort interact for you?",
            options: [
                QuizOption(text: "Clear preference for routine", note: "Low ε, high threshold", value: 1),
                QuizOption(
                    text: "Mostly routine, occasional novelty", note: "Moderate-low ε", value: 2
                ),
                QuizOption(
                    text: "Balance of both—context dependent", note: "Moderate ε + threshold", value: 3
                ),
                QuizOption(
                    text: "Strong drive for novelty, hard to sustain routine", note: "High ε, low threshold", value: 4
                )
            ],
            parameter: "interactions"
        ),
        QuizQuestion(
            id: 25,
            text: "When stressed, how do body awareness and action tendency interact?",
            options: [
                QuizOption(
                    text: "Act despite body signals", note: "Low somatic, low threshold", value: 1
                ),
                QuizOption(
                    text: "Notice body but push through", note: "Moderate somatic, low threshold", value: 2
                ),
                QuizOption(
                    text: "Body signals slow action significantly", note: "High somatic, high threshold", value: 3
                ),
                QuizOption(
                    text: "Body state dominates—action halted", note: "Very high somatic + threshold", value: 4
                )
            ],
            parameter: "interactions"
        ),

        // MARK: - Temporal Dynamics

        QuizQuestion(
            id: 26,
            text: "How consistent are your reactions across different days?",
            options: [
                QuizOption(text: "Very consistent—similar situations = similar reactions", note: "High stability", value: 1),
                QuizOption(
                    text: "Generally consistent with minor variations", note: "Moderate-high stability", value: 2
                ),
                QuizOption(
                    text: "Noticeably variable—depends on day/state", note: "Moderate variability", value: 3
                ),
                QuizOption(
                    text: "Highly variable—same situations trigger very different responses", note: "High variability", value: 4
                )
            ],
            parameter: "temporal"
        ),
        QuizQuestion(
            id: 27,
            text: "How much does your current energy level affect your parameter expression?",
            options: [
                QuizOption(
                    text: "Minimal effect—parameters stable", note: "Low temporal variance", value: 1
                ),
                QuizOption(
                    text: "Some effect on specific parameters", note: "Moderate temporal variance", value: 2
                ),
                QuizOption(
                    text: "Significant effect across several parameters", note: "High temporal variance", value: 3
                ),
                QuizOption(
                    text: "Profound effect—almost different 'mode' when tired/energized", note: "Very high temporal variance", value: 4
                )
            ],
            parameter: "temporal"
        ),
        QuizQuestion(
            id: 28,
            text: "Over the past year, how much have your typical patterns changed?",
            options: [
                QuizOption(text: "Very stable—same patterns throughout", note: "High stability", value: 1),
                QuizOption(
                    text: "Minor gradual shifts", note: "Moderate stability", value: 2
                ),
                QuizOption(
                    text: "Noticeable evolution in some areas", note: "Moderate change", value: 3
                ),
                QuizOption(
                    text: "Significant transformation in multiple areas", note: "High change", value: 4
                )
            ],
            parameter: "temporal"
        ),
        QuizQuestion(
            id: 29,
            text: "How quickly do you adapt to new environments or contexts?",
            options: [
                QuizOption(
                    text: "Very quickly—seamless transition", note: "Fast adaptation", value: 1
                ),
                QuizOption(
                    text: "Within hours or days", note: "Moderate adaptation speed", value: 2
                ),
                QuizOption(
                    text: "Takes weeks to feel fully adjusted", note: "Slow adaptation", value: 3
                ),
                QuizOption(
                    text: "Long adaptation period or never fully adjust", note: "Very slow adaptation", value: 4
                )
            ],
            parameter: "temporal"
        ),
        QuizQuestion(
            id: 30,
            text: "How do your stress responses change over time?",
            options: [
                QuizOption(
                    text: "Immediate spike, quick recovery", note: "Fast temporal dynamics", value: 1
                ),
                QuizOption(
                    text: "Moderate peak, gradual return to baseline", note: "Moderate temporal dynamics", value: 2
                ),
                QuizOption(
                    text: "Sustained elevation, slow recovery", note: "Slow temporal dynamics", value: 3
                ),
                QuizOption(
                    text: "Extended impact—stress lingers for long periods", note: "Very slow temporal dynamics", value: 4
                )
            ],
            parameter: "temporal"
        ),

        // MARK: - Environmental Context

        QuizQuestion(
            id: 31,
            text: "How much does your social environment affect your APGI expression?",
            options: [
                QuizOption(
                    text: "Minimal—similar across contexts", note: "Low environmental sensitivity", value: 1
                ),
                QuizOption(
                    text: "Some parameters shift with social context", note: "Moderate sensitivity", value: 2
                ),
                QuizOption(
                    text: "Significant variation between social contexts", note: "High sensitivity", value: 3
                ),
                QuizOption(
                    text: "Profoundly different across social environments", note: "Very high sensitivity", value: 4
                )
            ],
            parameter: "environment"
        ),
        QuizQuestion(
            id: 32,
            text: "How do structured vs. unstructured environments affect you?",
            options: [
                QuizOption(
                    text: "Thrive equally in both", note: "Low environmental preference", value: 1
                ),
                QuizOption(
                    text: "Slight preference but adaptable", note: "Moderate preference", value: 2
                ),
                QuizOption(
                    text: "Strong preference for one over other", note: "High preference", value: 3
                ),
                QuizOption(
                    text: "Only function well in preferred environment", note: "Very strong preference", value: 4
                )
            ],
            parameter: "environment"
        ),
        QuizQuestion(
            id: 33,
            text: "How does task load affect your parameter expression?",
            options: [
                QuizOption(
                    text: "Consistent regardless of workload", note: "Low load sensitivity", value: 1
                ),
                QuizOption(
                    text: "Some parameters shift under high load", note: "Moderate load sensitivity", value: 2
                ),
                QuizOption(
                    text: "Significant expression changes with load", note: "High load sensitivity", value: 3
                ),
                QuizOption(
                    text: "Extreme variation—different 'person' under high load", note: "Very high load sensitivity", value: 4
                )
            ],
            parameter: "environment"
        ),
        QuizQuestion(
            id: 34,
            text: "How sensitive are you to physical environment (lighting, noise, space)?",
            options: [
                QuizOption(text: "Minimal sensitivity—adapt easily", note: "Low environmental sensitivity", value: 1),
                QuizOption(
                    text: "Notice but not strongly affected", note: "Moderate sensitivity", value: 2
                ),
                QuizOption(
                    text: "Significantly affected by suboptimal conditions", note: "High sensitivity", value: 3
                ),
                QuizOption(
                    text: "Deeply impacted—environment strongly shapes experience", note: "Very high sensitivity", value: 4
                )
            ],
            parameter: "environment"
        ),
        QuizQuestion(
            id: 35,
            text: "How does your effectiveness vary across different contexts?",
            options: [
                QuizOption(
                    text: "Consistently effective across contexts", note: "Low context variance", value: 1
                ),
                QuizOption(
                    text: "Some variation but generally capable", note: "Moderate variance", value: 2
                ),
                QuizOption(
                    text: "Significant variation—strengths context-dependent", note: "High variance", value: 3
                ),
                QuizOption(
                    text: "Either extremely effective or overwhelmed", note: "Depends on parameter interaction", value: 4
                )
            ],
            parameter: "environment"
        )
    ]
}
