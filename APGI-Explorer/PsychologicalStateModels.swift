import Combine
import Foundation

// MARK: - Structured Parameter Models

struct ParameterRange: Codable {
    let min: Double
    let max: Double
    let unit: Unit
    let description: String

    enum Unit: String, Codable, CaseIterable {
        case percentage = "%"
        case sigma = "σ"
        case accuracy
        case ratio
        case milliseconds = "ms"
        case seconds = "s"

        var symbol: String {
            self.rawValue
        }
    }

    var formattedRange: String {
        if self.min == self.max {
            return "\(Int(self.min))\(self.unit.symbol)"
        }
        return "\(Int(self.min))-\(Int(self.max))\(self.unit.symbol)"
    }

    /// The average value of the range
    var average: Double {
        (self.min + self.max) / 2.0
    }
}

struct PrecisionProfile: Codable {
    let task: PrecisionLevel
    let distractor: PrecisionLevel
    let description: String?

    init(task: PrecisionLevel, distractor: PrecisionLevel, description: String? = nil) {
        self.task = task
        self.distractor = distractor
        self.description = description
    }

    enum PrecisionLevel: Codable {
        case veryLow(Double)
        case low(Double)
        case moderate(Double)
        case high(Double)
        case veryHigh(Double)
        case extreme(Double)
        case baseline
        case suppressed(Double)
        case elevated(Double)

        var value: Double {
            switch self {
            case let .veryLow(val), let .low(val), let .moderate(val),
                 let .high(val), let .veryHigh(val), let .extreme(val),
                 let .suppressed(val), let .elevated(val):
                val
            case .baseline:
                0.0
            }
        }

        var description: String {
            switch self {
            case .veryLow: "Very Low"
            case .low: "Low"
            case .moderate: "Moderate"
            case .high: "High"
            case .veryHigh: "Very High"
            case .extreme: "Extreme"
            case .baseline: "Baseline"
            case .suppressed: "Suppressed"
            case .elevated: "Elevated"
            }
        }

        var formatted: String {
            switch self {
            case .baseline:
                "baseline"
            default:
                "\(self.description)(\(self.value)σ)"
            }
        }
    }
}

struct ThresholdRange: Codable {
    let adjustment: Double
    let variance: Double
    let unit: ParameterRange.Unit
    let stability: Stability
    let description: String

    enum Stability: String, Codable, CaseIterable {
        case stable
        case unstable
        case oscillating
        case elevated
        case suppressed
        case normal
        case chaotic

        var description: String {
            self.rawValue
        }
    }

    var formattedRange: String {
        let varianceText = self.variance > 0 ? " (±\(Int(self.variance))% variance)" : ""
        return "\(self.adjustment > 0 ? "+" : "")\(Int(self.adjustment))\(self.unit.symbol)\(varianceText)"
    }
}

struct BiasRange: Codable {
    let min: Double
    let max: Double
    let description: String
    let dominance: Dominance

    enum Dominance: String, Codable, CaseIterable {
        case balanced
        case somatic
        case cognitive
        case suppressed
        case amplified
        case variable

        var description: String {
            self.rawValue
        }
    }

    var formattedRange: String {
        if self.min == self.max {
            return "\(self.min) (\(self.dominance.description))"
        }
        return "\(self.min)-\(self.max) (\(self.dominance.description))"
    }

    /// The average value of the bias range
    var average: Double {
        (self.min + self.max) / 2.0
    }
}

// MARK: - Enhanced Psychological State

/// Represents a psychological state with APGI (Active Precision and Goal Inference) parameters
///
/// This struct models various psychological states using the APGI framework, which includes
/// parameters for prediction error, precision, threshold, and somatic bias. Each state is
/// uniquely identified and contains metadata for additional context.
///
/// - Important: This is a public API used throughout the application for psychological state modeling
public struct PsychologicalState: Identifiable, Codable {
    public let id: Int
    let name: String
    let description: String
    let parameters: APGIParameters
    let metadata: StateMetadata

    struct APGIParameters: Codable {
        let predictionError: PredictionErrorSpec
        let precision: PrecisionProfile
        let threshold: ThresholdRange
        let somaticBias: BiasRange
    }

    struct PredictionErrorSpec: Codable {
        let accuracy: ParameterRange
        let context: ErrorContext
        let description: String

        enum ErrorContext: String, Codable, CaseIterable {
            case taskAligned = "task-aligned"
            case social
            case threat
            case novelty
            case homeostatic
            case benignViolation = "benign violation"
            case counterfactual
            case temporal
            case `internal`
            case external

            var description: String {
                self.rawValue
            }
        }

        var formattedAccuracy: String {
            "\(self.accuracy.formattedRange) \(self.context.description)"
        }
    }

    struct StateMetadata: Codable {
        let duration: DurationRange
        let metabolicCost: MetabolicCost
        let neurologicalBasis: [String]
        let adaptiveValue: AdaptiveValue

        enum DurationRange: String, Codable, CaseIterable {
            case momentary = "momentary (<1s)"
            case brief = "brief (1-10s)"
            case short = "short (10s-1min)"
            case medium = "medium (1-10min)"
            case extended = "extended (10min-1hr)"
            case sustained = "sustained (>1hr)"
            case tonic = "tonic (ongoing)"

            var description: String {
                self.rawValue
            }
        }

        enum MetabolicCost: String, Codable, CaseIterable {
            case minimal
            case low
            case moderate
            case high
            case extreme
            case protective

            var description: String {
                self.rawValue
            }
        }

        enum AdaptiveValue: String, Codable, CaseIterable {
            case highlyAdaptive = "highly adaptive"
            case adaptive
            case contextDependent = "context-dependent"
            case maladaptive
            case protective
            case neutral
            case homeostatic

            var description: String {
                self.rawValue
            }
        }
    }
}

// MARK: - State Transition Model

class StateTransitionModel: ObservableObject {
    @Published var transitions: [Transition] = []
    @Published var currentState: PsychologicalState?

    struct Transition: Identifiable, Codable {
        let id: UUID
        let from: Int // state ID
        let toState: Int // state ID
        let probability: Double
        let triggers: [Trigger]
        let duration: TimeInterval // typical transition time
        let conditions: [Condition]

        init(
            id: UUID = UUID(),
            from: Int,
            toState: Int,
            probability: Double,
            triggers: [Trigger],
            duration: TimeInterval,
            conditions: [Condition]
        ) {
            self.id = id
            self.from = from
            self.toState = toState
            self.probability = probability
            self.triggers = triggers
            self.duration = duration
            self.conditions = conditions
        }

        enum Trigger: Codable {
            case parameterShift(parameter: Parameter, direction: Direction, magnitude: Double)
            case externalEvent(type: EventType)
            case temporalFactor(duration: TimeInterval)
            case metabolicConstraint(level: MetabolicLevel)
            case socialContext(context: SocialContext)

            enum Parameter: String, Codable, CaseIterable {
                case predictionError
                case precision
                case threshold
                case somaticBias
            }

            enum Direction: String, Codable, CaseIterable {
                case increase
                case decrease
                case fluctuate
            }

            enum EventType: String, Codable, CaseIterable {
                case success
                case failure
                case socialConnection = "social connection"
                case threat
                case novelty
                case loss
                case achievement
                case rejection
            }

            enum MetabolicLevel: String, Codable, CaseIterable {
                case depleted
                case low
                case moderate
                case high
            }

            enum SocialContext: String, Codable, CaseIterable {
                case alone
                case intimate
                case group
                case `public`
                case competitive
                case cooperative
            }
        }

        enum Condition: Codable {
            case thresholdMet(parameter: Trigger.Parameter, value: Double)
            case timeInState(duration: TimeInterval)
            case contextAvailable(context: String)
            case energyAvailable(level: Double)
        }
    }

    /// Common transitions
    static let commonTransitions: [Transition] = [
        Transition(
            from: 13, // Engagement
            toState: 1, // Flow
            probability: 0.3,
            triggers: [
                .parameterShift(parameter: .threshold, direction: .decrease, magnitude: 0.05),
                .temporalFactor(duration: 600), // 10 min of sustained engagement
            ],
            duration: 300,
            conditions: [
                .timeInState(duration: 600),
                .thresholdMet(parameter: .precision, value: 4.0),
            ]
        ),
        Transition(
            from: 1, // Flow
            toState: 35, // Overwhelm
            probability: 0.15,
            triggers: [
                .parameterShift(parameter: .precision, direction: .increase, magnitude: 2.0),
                .externalEvent(type: .threat),
            ],
            duration: 60,
            conditions: [
                .thresholdMet(parameter: .predictionError, value: 4.0),
            ]
        ),
        Transition(
            from: 15, // Neutrality
            toState: 12, // Curiosity
            probability: 0.4,
            triggers: [
                .externalEvent(type: .novelty),
                .parameterShift(parameter: .threshold, direction: .decrease, magnitude: 0.1),
            ],
            duration: 120,
            conditions: [
                .contextAvailable(context: "novel stimuli"),
            ]
        ),
        Transition(
            from: 20, // Anxiety
            toState: 8, // Serenity
            probability: 0.25,
            triggers: [
                .externalEvent(type: .socialConnection),
                .parameterShift(parameter: .threshold, direction: .increase, magnitude: 0.2),
            ],
            duration: 600,
            conditions: [
                .timeInState(duration: 1800),
                .energyAvailable(level: 0.7),
            ]
        ),
    ]

    init() {
        self.transitions = Self.commonTransitions
    }

    func possibleTransitions(from stateId: Int) -> [Transition] {
        self.transitions.filter { $0.from == stateId }
    }

    func transitionProbability(from: Int, toState: Int) -> Double {
        self.transitions.first { $0.from == from && $0.toState == toState }?.probability ?? 0.0
    }

    func addTransition(_ transition: Transition) {
        self.transitions.append(transition)
    }

    func removeTransition(id: UUID) {
        self.transitions.removeAll { $0.id == id }
    }
}

// MARK: - Example Psychological States with Structured Data

extension PsychologicalState {
    static let exampleStates: [PsychologicalState] = [
        // Existing states
        PsychologicalState(
            id: 1,
            name: "Flow state",
            description: "Temporal entrainment, metacognitive suppression",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 95, max: 100,
                        unit: .accuracy,
                        description: "Task-aligned predictions"
                    ),
                    context: .taskAligned,
                    description: "Highly accurate predictions with minimal error"
                ),
                precision: PrecisionProfile(
                    task: .veryHigh(4.0),
                    distractor: .veryLow(0.5),
                    description: "Strong task focus, minimal distraction"
                ),
                threshold: ThresholdRange(
                    adjustment: -12.5,
                    variance: 3.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold with stable maintenance"
                ),
                somaticBias: BiasRange(
                    min: 0.9, max: 1.1,
                    description: "Balanced mind-body integration",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .extended,
                metabolicCost: .moderate,
                neurologicalBasis: ["DMN suppression, FPN activation, dopamine release"],
                adaptiveValue: .highlyAdaptive
            )
        ),
        PsychologicalState(
            id: 6,
            name: "Awe",
            description: "DMN suppression, model inadequacy signal",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 4, max: 5,
                        unit: .sigma,
                        description: "Massive prediction error from vastness"
                    ),
                    context: .novelty,
                    description: "Encountering something beyond current models"
                ),
                precision: PrecisionProfile(
                    task: .extreme(4.0),
                    distractor: .suppressed(0.1),
                    description: "Global precision elevation, brief suppression"
                ),
                threshold: ThresholdRange(
                    adjustment: -25.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .unstable,
                    description: "Brief threshold suppression"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.0,
                    description: "Reduced self-focus, expanded awareness",
                    dominance: .cognitive
                )
            ),
            metadata: StateMetadata(
                duration: .brief,
                metabolicCost: .high,
                neurologicalBasis: ["DMN suppression, ACC activation, noradrenaline"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 20,
            name: "Anxiety",
            description: "False alarm generator, self-reinforcing cycle",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 6,
                        unit: .sigma,
                        description: "Threat-biased expectations"
                    ),
                    context: .threat,
                    description: "Anticipating negative outcomes"
                ),
                precision: PrecisionProfile(
                    task: .extreme(4.5),
                    distractor: .moderate(2.0),
                    description: "Threat precision elevated, general hypervigilance"
                ),
                threshold: ThresholdRange(
                    adjustment: -32.5,
                    variance: 7.5,
                    unit: .percentage,
                    stability: .unstable,
                    description: "Lowered threat threshold"
                ),
                somaticBias: BiasRange(
                    min: 1.5, max: 2.5,
                    description: "Interoceptive hypervigilance, somatic amplification",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .sustained,
                metabolicCost: .high,
                neurologicalBasis: ["Amygdala hyperactivity, insula activation, cortisol"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 35,
            name: "Overwhelm",
            description: "Reservoir saturation, computational collapse",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 10, max: 15,
                        unit: .ratio,
                        description: "Excessive concurrent demands"
                    ),
                    context: .external,
                    description: "Too many competing predictions"
                ),
                precision: PrecisionProfile(
                    task: .extreme(5.0),
                    distractor: .extreme(5.0),
                    description: "Multiple high-precision streams compete"
                ),
                threshold: ThresholdRange(
                    adjustment: 0.0,
                    variance: 50.0,
                    unit: .percentage,
                    stability: .chaotic,
                    description: "Chaotically exceeded, fragmented"
                ),
                somaticBias: BiasRange(
                    min: 1.5, max: 2.0,
                    description: "Sympathetic feedback loop",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .short,
                metabolicCost: .extreme,
                neurologicalBasis: ["Prefrontal collapse, amygdala takeover"],
                adaptiveValue: .protective
            )
        ),

        // New states
        PsychologicalState(
            id: 2,
            name: "Joy/Happiness",
            description: "Dopamine-mediated elevation of expected value signals",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 20, max: 25,
                        unit: .percentage,
                        description: "Exceeds prior expectations"
                    ),
                    context: .social,
                    description: "Actual outcomes exceed predicted value"
                ),
                precision: PrecisionProfile(
                    task: .elevated(2.5),
                    distractor: .low(0.8),
                    description: "Amplified precision on reward-related content"
                ),
                threshold: ThresholdRange(
                    adjustment: -18.0,
                    variance: 2.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for positively-valenced inputs"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with positive somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Ventral striatal-vmPFC circuits, dopamine elevation"],
                adaptiveValue: .highlyAdaptive
            )
        ),
        PsychologicalState(
            id: 3,
            name: "Gratitude",
            description: "Resolution of social prediction errors in a favorable direction",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 3,
                        unit: .sigma,
                        description: "Positive social prediction error"
                    ),
                    context: .social,
                    description: "Unexpected prosocial behavior"
                ),
                precision: PrecisionProfile(
                    task: .high(3.0),
                    distractor: .suppressed(0.2),
                    description: "Elevated social and interoceptive precision"
                ),
                threshold: ThresholdRange(
                    adjustment: -12.0,
                    variance: 3.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for social-affiliative content"
                ),
                somaticBias: BiasRange(
                    min: 0.9, max: 1.3,
                    description: "Somatic markers of safety and connection",
                    dominance: .cognitive
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .low,
                neurologicalBasis: ["Oxytocin release, ACC-insula connectivity"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 4,
            name: "Hope",
            description: "Computationally sophisticated state balancing uncertainty and expected value",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 60, max: 75,
                        unit: .accuracy,
                        description: "Moderate prediction confidence"
                    ),
                    context: .temporal,
                    description: "High expected value despite uncertainty"
                ),
                precision: PrecisionProfile(
                    task: .high(3.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on future-oriented cues"
                ),
                threshold: ThresholdRange(
                    adjustment: -15.0,
                    variance: 3.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Sustained threshold lowering by dopaminergic tone"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with positive somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .extended,
                metabolicCost: .moderate,
                neurologicalBasis: ["Mesolimbic dopamine, anterior cingulate, ventromedial prefrontal cortex"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 5,
            name: "Optimism",
            description: "Generalized positive prior distribution",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 70, max: 80,
                        unit: .accuracy,
                        description: "High prior probability on positive outcomes"
                    ),
                    context: .temporal,
                    description: "Systematically underweights negative prediction errors"
                ),
                precision: PrecisionProfile(
                    task: .moderate(2.0),
                    distractor: .low(0.8),
                    description: "Constitutively elevated precision on positive content"
                ),
                threshold: ThresholdRange(
                    adjustment: -10.0,
                    variance: 2.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Reduced threshold for confirmatory evidence"
                ),
                somaticBias: BiasRange(
                    min: 0.7, max: 1.1,
                    description: "Balanced, with positive somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .tonic,
                metabolicCost: .low,
                neurologicalBasis: ["Trait-level serotonergic tone, prefrontal-amygdala connectivity"],
                adaptiveValue: .contextDependent
            )
        ),
        PsychologicalState(
            id: 7,
            name: "Inspiration",
            description: "Detection of latent pattern similarities",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 4,
                        unit: .sigma,
                        description: "Precision on abstract/analogical matches"
                    ),
                    context: .internal,
                    description: "Serendipitous matching between current input and distant memory traces"
                ),
                precision: PrecisionProfile(
                    task: .high(3.0),
                    distractor: .low(0.5),
                    description: "Elevated precision on weak-but-coherent pattern matches"
                ),
                threshold: ThresholdRange(
                    adjustment: -12.0,
                    variance: 3.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for associations beyond immediate task constraints"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with positive somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .brief,
                metabolicCost: .moderate,
                neurologicalBasis: [
                    "Anterior temporal lobe, posterior cingulate, default mode-frontoparietal coupling",
                ],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 8,
            name: "Serenity",
            description: "Low-surprise environment, reduced threat-related precision",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 90, max: 95,
                        unit: .accuracy,
                        description: "High prediction accuracy"
                    ),
                    context: .homeostatic,
                    description: "Consistently accurate predictions in low-surprise environment"
                ),
                precision: PrecisionProfile(
                    task: .moderate(1.5),
                    distractor: .veryLow(0.3),
                    description: "Minimized threat-related precision"
                ),
                threshold: ThresholdRange(
                    adjustment: 15.0,
                    variance: 2.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold for perturbations, lowered for calm visceral states"
                ),
                somaticBias: BiasRange(
                    min: 0.7, max: 1.0,
                    description: "Interoceptive safety and calm",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .sustained,
                metabolicCost: .low,
                neurologicalBasis: ["Parasympathetic dominance, GABA tone in amygdala, endogenous opioid release"],
                adaptiveValue: .highlyAdaptive
            )
        ),
        PsychologicalState(
            id: 9,
            name: "Pride",
            description: "Self-model prediction confirmed or exceeded",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 2,
                        unit: .sigma,
                        description: "Positive self-model prediction error"
                    ),
                    context: .internal,
                    description: "Performance exceeds self-model predictions"
                ),
                precision: PrecisionProfile(
                    task: .veryHigh(4.0),
                    distractor: .low(0.8),
                    description: "Elevated precision on achievement-related content"
                ),
                threshold: ThresholdRange(
                    adjustment: -15.0,
                    variance: 3.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for self-referential content"
                ),
                somaticBias: BiasRange(
                    min: 1.2, max: 1.8,
                    description: "Interoceptive markers of status/competence",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Medial prefrontal cortex, posterior cingulate, chest expansion, upright posture"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 10,
            name: "Amusement",
            description: "Benign violation theory within APGI",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 2,
                        unit: .sigma,
                        description: "Mild prediction violation in safe context"
                    ),
                    context: .benignViolation,
                    description: "Incongruity detection with safety signal"
                ),
                precision: PrecisionProfile(
                    task: .moderate(2.0),
                    distractor: .low(0.8),
                    description: "Elevated precision on social incongruity"
                ),
                threshold: ThresholdRange(
                    adjustment: -18.0,
                    variance: 2.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for playful ignition"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with positive somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .brief,
                metabolicCost: .low,
                neurologicalBasis: ["Anterior medial prefrontal cortex, mesolimbic reward system"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 11,
            name: "Love",
            description: "Extreme precision-threshold reconfiguration for attachment",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 4, max: 6,
                        unit: .sigma,
                        description: "Precision on partner-specific cues"
                    ),
                    context: .social,
                    description: "Attachment/reciprocity signals"
                ),
                precision: PrecisionProfile(
                    task: .extreme(5.0),
                    distractor: .suppressed(0.1),
                    description: "Global precision elevation for partner cues"
                ),
                threshold: ThresholdRange(
                    adjustment: -25.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .unstable,
                    description: "Lowered threshold for attachment-relevant content"
                ),
                somaticBias: BiasRange(
                    min: 1.8, max: 2.5,
                    description: "Interoceptive markers of safety and connection",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .tonic,
                metabolicCost: .high,
                neurologicalBasis: ["Oxytocin/vasopressin release, anterior cingulate-insula connectivity"],
                adaptiveValue: .contextDependent
            )
        ),
        PsychologicalState(
            id: 12,
            name: "Curiosity",
            description: "Inverts typical prediction error response",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 4,
                        unit: .sigma,
                        description: "Precision on information-gap signals"
                    ),
                    context: .novelty,
                    description: "Expected value high despite uncertainty"
                ),
                precision: PrecisionProfile(
                    task: .high(3.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on uncertainty signals"
                ),
                threshold: ThresholdRange(
                    adjustment: -15.0,
                    variance: 3.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for exploratory content"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with positive somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Anterior cingulate, dorsolateral prefrontal cortex, dopamine release"],
                adaptiveValue: .highlyAdaptive
            )
        ),
        PsychologicalState(
            id: 13,
            name: "Engagement",
            description: "Partial flow: high task-relevant precision without temporal entrainment",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 85, max: 90,
                        unit: .accuracy,
                        description: "High task-relevant prediction accuracy"
                    ),
                    context: .taskAligned,
                    description: "Sustained attention without full absorption"
                ),
                precision: PrecisionProfile(
                    task: .veryHigh(4.0),
                    distractor: .low(0.8),
                    description: "High task precision, intermittent self-monitoring"
                ),
                threshold: ThresholdRange(
                    adjustment: -12.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .oscillating,
                    description: "Lowered threshold with 10-20% fluctuation"
                ),
                somaticBias: BiasRange(
                    min: 0.9, max: 1.1,
                    description: "Balanced mind-body integration",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .extended,
                metabolicCost: .moderate,
                neurologicalBasis: ["Dorsolateral prefrontal cortex, posterior parietal cortex"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 14,
            name: "Mindfulness",
            description: "Equalized precision across internal/external domains",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 70, max: 80,
                        unit: .accuracy,
                        description: "Moderate prediction accuracy"
                    ),
                    context: .homeostatic,
                    description: "Acceptance of prediction errors as information"
                ),
                precision: PrecisionProfile(
                    task: .moderate(1.5),
                    distractor: .moderate(1.5),
                    description: "Equalized precision across domains"
                ),
                threshold: ThresholdRange(
                    adjustment: 20.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold for habitual predictions, lowered for present-moment signals"
                ),
                somaticBias: BiasRange(
                    min: 1.0, max: 1.4,
                    description: "Increased interoceptive awareness",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .tonic,
                metabolicCost: .low,
                neurologicalBasis: ["Reduced default mode connectivity, increased insula-prefrontal coherence"],
                adaptiveValue: .highlyAdaptive
            )
        ),
        PsychologicalState(
            id: 15,
            name: "Neutrality",
            description: "Homeostatic equilibrium in the APGI system",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 85, max: 90,
                        unit: .accuracy,
                        description: "Low prediction error magnitude"
                    ),
                    context: .homeostatic,
                    description: "No dominant prediction error"
                ),
                precision: PrecisionProfile(
                    task: .baseline,
                    distractor: .baseline,
                    description: "All precision weights at baseline"
                ),
                threshold: ThresholdRange(
                    adjustment: 0.0,
                    variance: 2.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Threshold at resting set-point"
                ),
                somaticBias: BiasRange(
                    min: 0.9, max: 1.1,
                    description: "Balanced mind-body integration",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .tonic,
                metabolicCost: .minimal,
                neurologicalBasis: ["Default mode dominance, minimal metabolic demand"],
                adaptiveValue: .neutral
            )
        ),
        PsychologicalState(
            id: 16,
            name: "Boredom",
            description: "Resource-conservation policy for redundant content",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 0, max: 0.5,
                        unit: .sigma,
                        description: "Near-zero prediction error"
                    ),
                    context: .homeostatic,
                    description: "Stimulus over-learned or impoverished"
                ),
                precision: PrecisionProfile(
                    task: .suppressed(0.3),
                    distractor: .suppressed(0.3),
                    description: "Globally suppressed precision"
                ),
                threshold: ThresholdRange(
                    adjustment: 25.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold blocking ignition"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.0,
                    description: "Balanced, with mild somatic discomfort",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .sustained,
                metabolicCost: .minimal,
                neurologicalBasis: ["Reduced anterior insula activation, low ventral striatum response"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 17,
            name: "Daydreaming",
            description: "Endogenously-generated predictions dominate",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 2,
                        unit: .sigma,
                        description: "Moderate prediction error"
                    ),
                    context: .internal,
                    description: "Memory/imagination content"
                ),
                precision: PrecisionProfile(
                    task: .low(0.8),
                    distractor: .high(3.0),
                    description: "Elevated internal precision, suppressed external"
                ),
                threshold: ThresholdRange(
                    adjustment: -20.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for internally-generated content"
                ),
                somaticBias: BiasRange(
                    min: 0.7, max: 1.0,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .short,
                metabolicCost: .low,
                neurologicalBasis: ["Default mode network hyperactivity, reduced thalamic gating"],
                adaptiveValue: .contextDependent
            )
        ),
        PsychologicalState(
            id: 18,
            name: "Distraction",
            description: "Multiple high-precision inputs compete for ignition",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 4,
                        unit: .sigma,
                        description: "Multiple competing prediction errors"
                    ),
                    context: .external,
                    description: "Task-irrelevant signals maintain high precision"
                ),
                precision: PrecisionProfile(
                    task: .moderate(1.5),
                    distractor: .high(3.0),
                    description: "Multiple high-precision inputs compete"
                ),
                threshold: ThresholdRange(
                    adjustment: 0.0,
                    variance: 20.0,
                    unit: .percentage,
                    stability: .chaotic,
                    description: "Threshold crossed chaotically by different inputs"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .short,
                metabolicCost: .high,
                neurologicalBasis: [
                    "Anterior cingulate conflict monitoring, frontoparietal control network instability",
                ],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 19,
            name: "Fatigue (cognitive/mental)",
            description: "Metabolic constraint elevates ignition threshold",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 2,
                        unit: .sigma,
                        description: "Prediction error accumulation slowed"
                    ),
                    context: .homeostatic,
                    description: "Glucose depletion, adenosine accumulation"
                ),
                precision: PrecisionProfile(
                    task: .suppressed(0.5),
                    distractor: .suppressed(0.5),
                    description: "Globally reduced precision"
                ),
                threshold: ThresholdRange(
                    adjustment: 30.0,
                    variance: 10.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold, reduced temporal integration"
                ),
                somaticBias: BiasRange(
                    min: 0.6, max: 0.9,
                    description: "Reduced somatic awareness",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .extended,
                metabolicCost: .minimal,
                neurologicalBasis: ["Prefrontal cortex and thalamus adenosine accumulation"],
                adaptiveValue: .protective
            )
        ),
        PsychologicalState(
            id: 21,
            name: "Stress",
            description: "Non-selective precision elevation with threshold instability",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 4,
                        unit: .sigma,
                        description: "Undifferentiated arousal"
                    ),
                    context: .threat,
                    description: "All inputs gain precision, not just threats"
                ),
                precision: PrecisionProfile(
                    task: .high(3.0),
                    distractor: .high(3.0),
                    description: "Non-selective precision elevation"
                ),
                threshold: ThresholdRange(
                    adjustment: 0.0,
                    variance: 20.0,
                    unit: .percentage,
                    stability: .unstable,
                    description: "Threshold becomes unstable"
                ),
                somaticBias: BiasRange(
                    min: 1.2, max: 1.8,
                    description: "Interoceptive hypervigilance",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .extreme,
                neurologicalBasis: ["Sympathetic activation, HPA axis activation, cortisol release"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 22,
            name: "Depression",
            description: "Computational trap with low expected reward",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "Suppressed expected value on reward"
                    ),
                    context: .internal,
                    description: "Negative self-referential content dominates"
                ),
                precision: PrecisionProfile(
                    task: .suppressed(0.5),
                    distractor: .high(3.0),
                    description: "Reduced reward precision, elevated negative precision"
                ),
                threshold: ThresholdRange(
                    adjustment: 40.0,
                    variance: 10.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold for positive content, lowered for negative"
                ),
                somaticBias: BiasRange(
                    min: 1.5, max: 2.5,
                    description: "Interoceptive hypervigilance, somatic amplification",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .tonic,
                metabolicCost: .high,
                neurologicalBasis: ["Reduced ventral striatal activity, elevated subgenual anterior cingulate"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 23,
            name: "Anger",
            description: "High precision on obstruction/norm-violation prediction errors",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "Precision on injustice-related errors"
                    ),
                    context: .social,
                    description: "Goal-directed predictions repeatedly violated"
                ),
                precision: PrecisionProfile(
                    task: .veryHigh(4.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on injustice, amplified somatic gain"
                ),
                threshold: ThresholdRange(
                    adjustment: -25.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for action-preparation content"
                ),
                somaticBias: BiasRange(
                    min: 1.5, max: 2.5,
                    description: "Interoceptive hypervigilance, somatic amplification",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .high,
                neurologicalBasis: ["Noradrenergic surge, amygdala hyperactivity, orbitofrontal cortex"],
                adaptiveValue: .contextDependent
            )
        ),
        PsychologicalState(
            id: 24,
            name: "Fear",
            description: "Extreme interoceptive precision with collapsed temporal integration",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 4, max: 7,
                        unit: .sigma,
                        description: "Threat-related prediction errors amplified"
                    ),
                    context: .threat,
                    description: "Extreme interoceptive precision dominates"
                ),
                precision: PrecisionProfile(
                    task: .extreme(5.0),
                    distractor: .suppressed(0.1),
                    description: "Global precision elevation for threat"
                ),
                threshold: ThresholdRange(
                    adjustment: -50.0,
                    variance: 10.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Threshold reduced 40-60%, triggering rapid ignition"
                ),
                somaticBias: BiasRange(
                    min: 2.5, max: 4.0,
                    description: "Extreme somatic dominance",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .brief,
                metabolicCost: .extreme,
                neurologicalBasis: ["Amygdala activation, locus coeruleus, sympathetic nervous system"],
                adaptiveValue: .protective
            )
        ),
        PsychologicalState(
            id: 25,
            name: "Guilt",
            description: "High precision on self-monitoring/norm-violation detection",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "Self-model prediction error"
                    ),
                    context: .internal,
                    description: "Behavior violates internalized moral predictions"
                ),
                precision: PrecisionProfile(
                    task: .veryHigh(4.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on self-evaluative content"
                ),
                threshold: ThresholdRange(
                    adjustment: -25.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for transgression-related content"
                ),
                somaticBias: BiasRange(
                    min: 1.2, max: 1.8,
                    description: "Interoceptive markers of moral wrongness",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Anterior cingulate, medial prefrontal cortex, anterior insula"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 26,
            name: "Shame",
            description: "Social prediction error with triadic representation",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "Social prediction error"
                    ),
                    context: .social,
                    description: "Self-in-group model violated"
                ),
                precision: PrecisionProfile(
                    task: .extreme(5.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on imagined observer signals"
                ),
                threshold: ThresholdRange(
                    adjustment: -30.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for self-devaluation"
                ),
                somaticBias: BiasRange(
                    min: 1.5, max: 2.5,
                    description: "Interoceptive markers of withdrawal",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .high,
                neurologicalBasis: ["Medial prefrontal cortex, temporoparietal junction, anterior insula"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 27,
            name: "Loneliness",
            description: "Chronic prediction error in social predictions",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 4,
                        unit: .sigma,
                        description: "Precision on absence/lack of expected social input"
                    ),
                    context: .social,
                    description: "Social predictions persistently unfulfilled"
                ),
                precision: PrecisionProfile(
                    task: .high(3.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on social threat"
                ),
                threshold: ThresholdRange(
                    adjustment: -20.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Heightened sensitivity to rejection/exclusion cues"
                ),
                somaticBias: BiasRange(
                    min: 1.0, max: 1.5,
                    description: "Interoceptive markers of isolation",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .tonic,
                metabolicCost: .moderate,
                neurologicalBasis: ["Elevated amygdala response, reduced ventral striatum response"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 28,
            name: "Frustration",
            description: "Repeated prediction failures with maintained effort",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 4,
                        unit: .sigma,
                        description: "Repeated prediction failures"
                    ),
                    context: .taskAligned,
                    description: "Goal-blocking, effort continues despite non-reward"
                ),
                precision: PrecisionProfile(
                    task: .high(3.0),
                    distractor: .moderate(1.5),
                    description: "Precision maintained on unmet expectations"
                ),
                threshold: ThresholdRange(
                    adjustment: 0.0,
                    variance: 25.0,
                    unit: .percentage,
                    stability: .unstable,
                    description: "Unstable threshold creating intermittent ignition"
                ),
                somaticBias: BiasRange(
                    min: 1.0, max: 1.5,
                    description: "Interoceptive markers of arousal",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .high,
                neurologicalBasis: ["Anterior cingulate, dorsolateral prefrontal cortex"],
                adaptiveValue: .contextDependent
            )
        ),
        PsychologicalState(
            id: 29,
            name: "Confusion",
            description: "Failure of model selection with ambiguous evidence",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 2,
                        unit: .sigma,
                        description: "Multiple competing, unresolved models"
                    ),
                    context: .novelty,
                    description: "No single prediction error dominates"
                ),
                precision: PrecisionProfile(
                    task: .moderate(1.5),
                    distractor: .moderate(1.5),
                    description: "Diffused precision across alternatives"
                ),
                threshold: ThresholdRange(
                    adjustment: 0.0,
                    variance: 10.0,
                    unit: .percentage,
                    stability: .unstable,
                    description: "No content achieves sufficient precision-weighted error"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .short,
                metabolicCost: .moderate,
                neurologicalBasis: ["Elevated anterior cingulate, unstable frontoparietal activation"],
                adaptiveValue: .neutral
            )
        ),
        PsychologicalState(
            id: 30,
            name: "Disgust",
            description: "Ancient pathogen-avoidance system",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "Precision on contamination/pathogen prediction errors"
                    ),
                    context: .threat,
                    description: "Visceral interoceptive signals dominate"
                ),
                precision: PrecisionProfile(
                    task: .veryHigh(4.0),
                    distractor: .suppressed(0.1),
                    description: "Elevated precision on contamination cues"
                ),
                threshold: ThresholdRange(
                    adjustment: -25.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for rejection/avoidance content"
                ),
                somaticBias: BiasRange(
                    min: 2.0, max: 3.0,
                    description: "Extreme somatic dominance",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .brief,
                metabolicCost: .moderate,
                neurologicalBasis: ["Anterior insula, basal ganglia, amygdala"],
                adaptiveValue: .protective
            )
        ),
        PsychologicalState(
            id: 31,
            name: "Envy",
            description: "High precision on status/resource mismatch signals",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 4,
                        unit: .sigma,
                        description: "Social comparison prediction error"
                    ),
                    context: .social,
                    description: "Self-model threatened by other's advantage"
                ),
                precision: PrecisionProfile(
                    task: .high(3.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on status cues"
                ),
                threshold: ThresholdRange(
                    adjustment: -20.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for status-relevant inputs"
                ),
                somaticBias: BiasRange(
                    min: 1.0, max: 1.5,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Dorsomedial prefrontal cortex, ventral striatum"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 32,
            name: "Jealousy",
            description: "Prediction error in attachment security",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "Precision on rival-related cues"
                    ),
                    context: .social,
                    description: "Threat to exclusive bond"
                ),
                precision: PrecisionProfile(
                    task: .extreme(5.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on rival-related cues"
                ),
                threshold: ThresholdRange(
                    adjustment: -30.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for defensive cognition"
                ),
                somaticBias: BiasRange(
                    min: 1.5, max: 2.5,
                    description: "Interoceptive markers of threat",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .high,
                neurologicalBasis: ["Amygdala, anterior cingulate, posterior cingulate"],
                adaptiveValue: .contextDependent
            )
        ),
        PsychologicalState(
            id: 33,
            name: "Regret",
            description: "Counterfactual prediction error",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "Self-directed negative prediction error"
                    ),
                    context: .temporal,
                    description: "Actual outcomes vs. counterfactual outcomes"
                ),
                precision: PrecisionProfile(
                    task: .veryHigh(4.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on self-blame"
                ),
                threshold: ThresholdRange(
                    adjustment: -20.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for autobiographical memory"
                ),
                somaticBias: BiasRange(
                    min: 1.0, max: 1.5,
                    description: "Interoceptive markers of discomfort",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Orbitofrontal cortex, medial prefrontal cortex"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 34,
            name: "Pessimism",
            description: "Systematic negative bias in prior distributions",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 60, max: 70,
                        unit: .accuracy,
                        description: "High prior probability on negative outcomes"
                    ),
                    context: .temporal,
                    description: "Expected outcomes skewed toward worse scenarios"
                ),
                precision: PrecisionProfile(
                    task: .suppressed(0.5),
                    distractor: .moderate(1.5),
                    description: "Suppressed precision on positive content"
                ),
                threshold: ThresholdRange(
                    adjustment: 25.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold for positive content"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .tonic,
                metabolicCost: .low,
                neurologicalBasis: ["Reduced ventral striatum, elevated right dorsolateral prefrontal"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 36,
            name: "Dissociation",
            description: "Interoceptive precision dramatically suppressed",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 0, max: 0.5,
                        unit: .sigma,
                        description: "Interoceptive precision suppressed"
                    ),
                    context: .internal,
                    description: "Soma-bias parameter reduced"
                ),
                precision: PrecisionProfile(
                    task: .suppressed(0.1),
                    distractor: .suppressed(0.1),
                    description: "Precision on interoceptive signals suppressed"
                ),
                threshold: ThresholdRange(
                    adjustment: 50.0,
                    variance: 10.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold for body-relevant content"
                ),
                somaticBias: BiasRange(
                    min: 0.1, max: 0.3,
                    description: "Body signals weighted <1/3 normal",
                    dominance: .cognitive
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Ventromedial prefrontal suppression of anterior insula"],
                adaptiveValue: .protective
            )
        ),
        PsychologicalState(
            id: 37,
            name: "Trance",
            description: "Top-down predictions dominate over sensory input",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 2,
                        unit: .sigma,
                        description: "Prior strength >3×posterior updating"
                    ),
                    context: .internal,
                    description: "External precision minimized"
                ),
                precision: PrecisionProfile(
                    task: .extreme(5.0),
                    distractor: .suppressed(0.1),
                    description: "Elevated precision on internally-generated rhythmic patterns"
                ),
                threshold: ThresholdRange(
                    adjustment: -25.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for endogenous content"
                ),
                somaticBias: BiasRange(
                    min: 0.5, max: 0.8,
                    description: "Reduced sensory gating",
                    dominance: .cognitive
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Frontal-theta synchrony, reduced sensory gating"],
                adaptiveValue: .neutral
            )
        ),
        PsychologicalState(
            id: 38,
            name: "Hallucination",
            description: "Strong internal predictions misattributed as sensory input",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 6,
                        unit: .sigma,
                        description: "Precision erroneously assigned to endogenous errors"
                    ),
                    context: .internal,
                    description: "Reality monitoring failure"
                ),
                precision: PrecisionProfile(
                    task: .extreme(5.0),
                    distractor: .suppressed(0.1),
                    description: "Elevated precision on internal signals"
                ),
                threshold: ThresholdRange(
                    adjustment: -30.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Threshold crossed by purely endogenous signals"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .brief,
                metabolicCost: .high,
                neurologicalBasis: ["Medial prefrontal cortex, anterior cingulate, sensory cortex"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 39,
            name: "Déjà Vu",
            description: "Temporal misalignment in reservoir state dynamics",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 2,
                        unit: .sigma,
                        description: "Current sensory input matches decaying memory trace"
                    ),
                    context: .temporal,
                    description: "Familiarity signal without episodic details"
                ),
                precision: PrecisionProfile(
                    task: .moderate(1.5),
                    distractor: .low(0.8),
                    description: "Momentary false match triggers premature threshold crossing"
                ),
                threshold: ThresholdRange(
                    adjustment: -10.0,
                    variance: 2.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Briefly lowered threshold for 'pastness' content"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .momentary,
                metabolicCost: .minimal,
                neurologicalBasis: ["Hippocampal reactivation, temporal lobe"],
                adaptiveValue: .neutral
            )
        ),
        PsychologicalState(
            id: 40,
            name: "Hypnagogia",
            description: "Temporal integration window extended beyond normal waking bounds",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 3,
                        unit: .sigma,
                        description: "Precision decoupled from external input"
                    ),
                    context: .internal,
                    description: "Threshold lowered for dream-like content"
                ),
                precision: PrecisionProfile(
                    task: .suppressed(0.3),
                    distractor: .moderate(1.5),
                    description: "External precision declining, internal maintained"
                ),
                threshold: ThresholdRange(
                    adjustment: -30.0,
                    variance: 10.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for non-sensory content"
                ),
                somaticBias: BiasRange(
                    min: 0.7, max: 1.0,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .brief,
                metabolicCost: .low,
                neurologicalBasis: ["Alpha waves declining, theta increasing, thalamic gating decreasing"],
                adaptiveValue: .neutral
            )
        ),
        PsychologicalState(
            id: 41,
            name: "Empathy",
            description: "High precision on observed emotional prediction errors",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "Precision on other's emotional prediction errors"
                    ),
                    context: .social,
                    description: "Interoceptive simulation actively engaged"
                ),
                precision: PrecisionProfile(
                    task: .veryHigh(4.0),
                    distractor: .low(0.8),
                    description: "Elevated precision on other's emotional state"
                ),
                threshold: ThresholdRange(
                    adjustment: -25.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for affective resonance"
                ),
                somaticBias: BiasRange(
                    min: 1.5, max: 2.0,
                    description: "Interoceptive simulation of other's state",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Anterior insula, inferior frontal gyrus, inferior parietal lobule"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 42,
            name: "Sympathy",
            description: "Moderate precision on other's suffering",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 3,
                        unit: .sigma,
                        description: "Precision on other's distress"
                    ),
                    context: .social,
                    description: "Concern and compassionate regard generated"
                ),
                precision: PrecisionProfile(
                    task: .moderate(1.5),
                    distractor: .low(0.8),
                    description: "Somatic mirroring lower than empathy"
                ),
                threshold: ThresholdRange(
                    adjustment: 20.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold for personal distress"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .low,
                neurologicalBasis: ["Medial prefrontal cortex, temporoparietal junction"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 43,
            name: "Belonging",
            description: "Social inclusion predictions confirmed",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 2,
                        unit: .sigma,
                        description: "Precision on positive social signals"
                    ),
                    context: .social,
                    description: "Group membership secure"
                ),
                precision: PrecisionProfile(
                    task: .high(3.0),
                    distractor: .low(0.8),
                    description: "Elevated precision on inclusion cues"
                ),
                threshold: ThresholdRange(
                    adjustment: -20.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for group-relevant content"
                ),
                somaticBias: BiasRange(
                    min: 1.0, max: 1.5,
                    description: "Interoceptive safety signals amplified",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .tonic,
                metabolicCost: .low,
                neurologicalBasis: ["Medial prefrontal cortex, ventral striatum, oxytocin"],
                adaptiveValue: .highlyAdaptive
            )
        ),
        PsychologicalState(
            id: 44,
            name: "Rejection",
            description: "Large social prediction error—exclusion violates expected inclusion",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "Precision on negative social cues"
                    ),
                    context: .social,
                    description: "Exclusion violates expected inclusion"
                ),
                precision: PrecisionProfile(
                    task: .veryHigh(4.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on rejection cues"
                ),
                threshold: ThresholdRange(
                    adjustment: -30.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for self-protective states"
                ),
                somaticBias: BiasRange(
                    min: 1.2, max: 1.8,
                    description: "Interoceptive markers of social pain",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .high,
                neurologicalBasis: ["Dorsal anterior cingulate cortex, anterior insula"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 45,
            name: "Trust",
            description: "Stable, positive social priors",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 2,
                        unit: .sigma,
                        description: "High expected value of cooperation"
                    ),
                    context: .social,
                    description: "Precision on betrayal lowered"
                ),
                precision: PrecisionProfile(
                    task: .moderate(1.5),
                    distractor: .suppressed(0.3),
                    description: "Reduced vigilance on betrayal-related errors"
                ),
                threshold: ThresholdRange(
                    adjustment: 25.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold for threat/suspicion content"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .tonic,
                metabolicCost: .low,
                neurologicalBasis: ["Ventromedial prefrontal cortex, amygdala suppression"],
                adaptiveValue: .adaptive
            )
        ),
        PsychologicalState(
            id: 46,
            name: "Focus/Concentration",
            description: "High precision on task-relevant prediction errors",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "High precision on task-relevant errors"
                    ),
                    context: .taskAligned,
                    description: "Low precision on irrelevant inputs"
                ),
                precision: PrecisionProfile(
                    task: .extreme(5.0),
                    distractor: .suppressed(0.1),
                    description: "Selective suppression of distractors"
                ),
                threshold: ThresholdRange(
                    adjustment: -12.0,
                    variance: 3.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Optimized threshold for target content"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .high,
                neurologicalBasis: ["Dorsolateral prefrontal cortex, superior parietal cortex"],
                adaptiveValue: .highlyAdaptive
            )
        ),
        PsychologicalState(
            id: 47,
            name: "Creativity",
            description: "High precision on weak, remote associations",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 4,
                        unit: .sigma,
                        description: "Precision on remote associations"
                    ),
                    context: .internal,
                    description: "Reservoir maintained near-critical state"
                ),
                precision: PrecisionProfile(
                    task: .high(3.0),
                    distractor: .moderate(1.5),
                    description: "Elevated precision on weak-but-coherent pattern matches"
                ),
                threshold: ThresholdRange(
                    adjustment: -15.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Lowered threshold for novel combinations"
                ),
                somaticBias: BiasRange(
                    min: 0.8, max: 1.2,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Default mode-executive network coupling, right hemisphere"],
                adaptiveValue: .highlyAdaptive
            )
        ),
        PsychologicalState(
            id: 48,
            name: "Decision Fatigue",
            description: "Precision dysregulation with competing options",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 1, max: 2,
                        unit: .sigma,
                        description: "Competing options maintain equal precision"
                    ),
                    context: .internal,
                    description: "Expected value computations become noisy"
                ),
                precision: PrecisionProfile(
                    task: .moderate(1.5),
                    distractor: .moderate(1.5),
                    description: "No dominant precision"
                ),
                threshold: ThresholdRange(
                    adjustment: 35.0,
                    variance: 10.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold to conserve resources"
                ),
                somaticBias: BiasRange(
                    min: 0.7, max: 1.0,
                    description: "Balanced, with mild somatic markers",
                    dominance: .balanced
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .minimal,
                neurologicalBasis: ["Orbitofrontal cortex depletion, dorsolateral prefrontal cortex"],
                adaptiveValue: .maladaptive
            )
        ),
        PsychologicalState(
            id: 49,
            name: "Cognitive Dissonance",
            description: "High-precision models conflict",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 3, max: 5,
                        unit: .sigma,
                        description: "Two or more high-precision models conflict"
                    ),
                    context: .internal,
                    description: "Reservoir pulled toward competing attractors"
                ),
                precision: PrecisionProfile(
                    task: .veryHigh(4.0),
                    distractor: .veryHigh(4.0),
                    description: "Both models maintain high precision"
                ),
                threshold: ThresholdRange(
                    adjustment: 0.0,
                    variance: 25.0,
                    unit: .percentage,
                    stability: .unstable,
                    description: "Threshold becomes unstable"
                ),
                somaticBias: BiasRange(
                    min: 1.0, max: 1.5,
                    description: "Interoceptive markers of discomfort",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .short,
                metabolicCost: .high,
                neurologicalBasis: ["Anterior cingulate, dorsal anterior cingulate"],
                adaptiveValue: .neutral
            )
        ),
        PsychologicalState(
            id: 50,
            name: "Hyperfocus",
            description: "Extreme task-relevant precision",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 5, max: 8,
                        unit: .sigma,
                        description: "Extreme task-relevant precision"
                    ),
                    context: .taskAligned,
                    description: "All non-task precision suppressed"
                ),
                precision: PrecisionProfile(
                    task: .extreme(6.0),
                    distractor: .suppressed(0.0),
                    description: "Nearly all precision allocated to target"
                ),
                threshold: ThresholdRange(
                    adjustment: -40.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Dramatically lowered threshold for target domain"
                ),
                somaticBias: BiasRange(
                    min: 0.6, max: 0.9,
                    description: "Reduced somatic awareness",
                    dominance: .cognitive
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .extreme,
                neurologicalBasis: ["Dorsolateral prefrontal cortex, posterior parietal cortex"],
                adaptiveValue: .contextDependent
            )
        ),
        PsychologicalState(
            id: 51,
            name: "Hunger",
            description: "Interoceptive precision elevated for metabolic/gastric signals",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 4,
                        unit: .sigma,
                        description: "Homeostatic prediction error"
                    ),
                    context: .homeostatic,
                    description: "Caloric deficit creates persistent high-precision signal"
                ),
                precision: PrecisionProfile(
                    task: .suppressed(0.3),
                    distractor: .high(3.0),
                    description: "Elevated interoceptive precision"
                ),
                threshold: ThresholdRange(
                    adjustment: 20.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold for non-essential cognition"
                ),
                somaticBias: BiasRange(
                    min: 1.3, max: 1.8,
                    description: "Interoceptive markers of metabolic deficit",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Hypothalamus, ghrelin signaling, orbitofrontal cortex"],
                adaptiveValue: .homeostatic
            )
        ),
        PsychologicalState(
            id: 52,
            name: "Thirst",
            description: "Interoceptive precision elevated for osmotic/hydration signals",
            parameters: APGIParameters(
                predictionError: PredictionErrorSpec(
                    accuracy: ParameterRange(
                        min: 2, max: 3,
                        unit: .sigma,
                        description: "Fluid deficit generates persistent high-precision alarm"
                    ),
                    context: .homeostatic,
                    description: "Angiotensin and osmoreceptor signaling"
                ),
                precision: PrecisionProfile(
                    task: .suppressed(0.3),
                    distractor: .moderate(1.5),
                    description: "Elevated interoceptive precision"
                ),
                threshold: ThresholdRange(
                    adjustment: 20.0,
                    variance: 5.0,
                    unit: .percentage,
                    stability: .stable,
                    description: "Elevated threshold for non-essential cognition"
                ),
                somaticBias: BiasRange(
                    min: 1.2, max: 1.6,
                    description: "Interoceptive markers of dehydration",
                    dominance: .somatic
                )
            ),
            metadata: StateMetadata(
                duration: .medium,
                metabolicCost: .moderate,
                neurologicalBasis: ["Subfornical organ, hypothalamus, anterior cingulate"],
                adaptiveValue: .homeostatic
            )
        ),
    ]
}

extension PsychologicalState {
    var predictionError: String {
        self.parameters.predictionError.formattedAccuracy
    }

    var precision: String {
        let task = self.parameters.precision.task.formatted
        let distractor = self.parameters.precision.distractor.formatted
        return "Task \(task), Distractor \(distractor)"
    }

    var threshold: String {
        self.parameters.threshold.formattedRange
    }

    var somaticBias: String {
        self.parameters.somaticBias.formattedRange
    }

    /// Calculates similarity between two psychological states based on their parameters
    /// - Parameter other: The other state to compare with
    /// - Returns: A similarity score between 0 (completely different) and 1 (identical)
    func similarity(to other: PsychologicalState) -> Double {
        // Calculate similarity for each parameter and weight them
        let predictionErrorSimilarity = 1.0 - abs(
            (self.parameters.predictionError.accuracy.average
                - other.parameters.predictionError.accuracy.average) / 100.0
        )

        let precisionSimilarity = 1.0 - abs(
            (self.parameters.precision.task.value - other.parameters.precision.task.value) / 5.0
        )

        let thresholdSimilarity = 1.0 - abs(
            (self.parameters.threshold.adjustment - other.parameters.threshold.adjustment) / 100.0
        )

        let somaticBiasSimilarity = 1.0 - abs(
            (self.parameters.somaticBias.average - other.parameters.somaticBias.average) / 3.0
        )

        // Calculate weighted average (adjust weights as needed)
        let totalWeight = 4.0 // Total of all weights
        let weightedSum = predictionErrorSimilarity * 1.0 +
            precisionSimilarity * 1.0 +
            thresholdSimilarity * 1.0 +
            somaticBiasSimilarity * 1.0

        return max(0.0, min(1.0, weightedSum / totalWeight))
    }
}
