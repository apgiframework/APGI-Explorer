import Foundation
import Combine

// MARK: - Structured Parameter Models

struct ParameterRange: Codable {
    let min: Double
    let max: Double
    let unit: Unit
    let description: String
    
    enum Unit: String, Codable, CaseIterable {
        case percentage = "%"
        case sigma = "σ"
        case accuracy = "accuracy"
        case ratio = "ratio"
        case milliseconds = "ms"
        case seconds = "s"
        
        var symbol: String {
            return self.rawValue
        }
    }
    
    var formattedRange: String {
        if min == max {
            return "\(Int(min))\(unit.symbol)"
        }
        return "\(Int(min))-\(Int(max))\(unit.symbol)"
    }
    
    /// The average value of the range
    var average: Double {
        (min + max) / 2.0
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
            case .veryLow(let v), .low(let v), .moderate(let v),
                 .high(let v), .veryHigh(let v), .extreme(let v),
                 .suppressed(let v), .elevated(let v):
                return v
            case .baseline:
                return 0.0
            }
        }
        
        var description: String {
            switch self {
            case .veryLow: return "Very Low"
            case .low: return "Low"
            case .moderate: return "Moderate"
            case .high: return "High"
            case .veryHigh: return "Very High"
            case .extreme: return "Extreme"
            case .baseline: return "Baseline"
            case .suppressed: return "Suppressed"
            case .elevated: return "Elevated"
            }
        }
        
        var formatted: String {
            switch self {
            case .baseline:
                return "baseline"
            default:
                return "\(description)(\(value)σ)"
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
        case stable = "stable"
        case unstable = "unstable"
        case oscillating = "oscillating"
        case elevated = "elevated"
        case suppressed = "suppressed"
        case normal = "normal"
        case chaotic = "chaotic"
        
        var description: String {
            return self.rawValue
        }
    }
    
    var formattedRange: String {
        let varianceText = variance > 0 ? " (±\(Int(variance))% variance)" : ""
        return "\(adjustment > 0 ? "+" : "")\(Int(adjustment))\(unit.symbol)\(varianceText)"
    }
}

struct BiasRange: Codable {
    let min: Double
    let max: Double
    let description: String
    let dominance: Dominance
    
    enum Dominance: String, Codable, CaseIterable {
        case balanced = "balanced"
        case somatic = "somatic"
        case cognitive = "cognitive"
        case suppressed = "suppressed"
        case amplified = "amplified"
        case variable = "variable"
        
        var description: String {
            return self.rawValue
        }
    }
    
    var formattedRange: String {
        if min == max {
            return "\(min) (\(dominance.description))"
        }
        return "\(min)-\(max) (\(dominance.description))"
    }
    
    /// The average value of the bias range
    var average: Double {
        (min + max) / 2.0
    }
}

// MARK: - Enhanced Psychological State

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
            case social = "social"
            case threat = "threat"
            case novelty = "novelty"
            case homeostatic = "homeostatic"
            case benignViolation = "benign violation"
            case counterfactual = "counterfactual"
            case temporal = "temporal"
            case `internal` = "internal"
            case external = "external"
            
            var description: String {
                return self.rawValue
            }
        }
        
        var formattedAccuracy: String {
            return "\(accuracy.formattedRange) \(context.description)"
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
                return self.rawValue
            }
        }
        
        enum MetabolicCost: String, Codable, CaseIterable {
            case minimal = "minimal"
            case low = "low"
            case moderate = "moderate"
            case high = "high"
            case extreme = "extreme"
            case protective = "protective"
            
            var description: String {
                return self.rawValue
            }
        }
        
        enum AdaptiveValue: String, Codable, CaseIterable {
            case highlyAdaptive = "highly adaptive"
            case adaptive = "adaptive"
            case contextDependent = "context-dependent"
            case maladaptive = "maladaptive"
            case protective = "protective"
            case neutral = "neutral"
            
            var description: String {
                return self.rawValue
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
        let from: Int  // state ID
        let to: Int    // state ID
        let probability: Double
        let triggers: [Trigger]
        let duration: TimeInterval  // typical transition time
        let conditions: [Condition]
        
        init(
            id: UUID = UUID(),
            from: Int,
            to: Int,
            probability: Double,
            triggers: [Trigger],
            duration: TimeInterval,
            conditions: [Condition]
        ) {
            self.id = id
            self.from = from
            self.to = to
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
                case predictionError = "predictionError"
                case precision = "precision"
                case threshold = "threshold"
                case somaticBias = "somaticBias"
            }
            
            enum Direction: String, Codable, CaseIterable {
                case increase = "increase"
                case decrease = "decrease"
                case fluctuate = "fluctuate"
            }
            
            enum EventType: String, Codable, CaseIterable {
                case success = "success"
                case failure = "failure"
                case socialConnection = "social connection"
                case threat = "threat"
                case novelty = "novelty"
                case loss = "loss"
                case achievement = "achievement"
                case rejection = "rejection"
            }
            
            enum MetabolicLevel: String, Codable, CaseIterable {
                case depleted = "depleted"
                case low = "low"
                case moderate = "moderate"
                case high = "high"
            }
            
            enum SocialContext: String, Codable, CaseIterable {
                case alone = "alone"
                case intimate = "intimate"
                case group = "group"
                case `public` = "public"
                case competitive = "competitive"
                case cooperative = "cooperative"
            }
        }
        
        enum Condition: Codable {
            case thresholdMet(parameter: Trigger.Parameter, value: Double)
            case timeInState(duration: TimeInterval)
            case contextAvailable(context: String)
            case energyAvailable(level: Double)
        }
    }
    
    // Common transitions
    static let commonTransitions: [Transition] = [
        Transition(
            from: 13,  // Engagement
            to: 1,     // Flow
            probability: 0.3,
            triggers: [
                .parameterShift(parameter: .threshold, direction: .decrease, magnitude: 0.05),
                .temporalFactor(duration: 600)  // 10 min of sustained engagement
            ],
            duration: 300,
            conditions: [
                .timeInState(duration: 600),
                .thresholdMet(parameter: .precision, value: 4.0)
            ]
        ),
        Transition(
            from: 1,   // Flow
            to: 35,    // Overwhelm
            probability: 0.15,
            triggers: [
                .parameterShift(parameter: .precision, direction: .increase, magnitude: 2.0),
                .externalEvent(type: .threat)
            ],
            duration: 60,
            conditions: [
                .thresholdMet(parameter: .predictionError, value: 4.0)
            ]
        ),
        Transition(
            from: 15,  // Neutrality
            to: 12,    // Curiosity
            probability: 0.4,
            triggers: [
                .externalEvent(type: .novelty),
                .parameterShift(parameter: .threshold, direction: .decrease, magnitude: 0.1)
            ],
            duration: 120,
            conditions: [
                .contextAvailable(context: "novel stimuli")
            ]
        ),
        Transition(
            from: 20,  // Anxiety
            to: 8,     // Serenity
            probability: 0.25,
            triggers: [
                .externalEvent(type: .socialConnection),
                .parameterShift(parameter: .threshold, direction: .increase, magnitude: 0.2)
            ],
            duration: 600,
            conditions: [
                .timeInState(duration: 1800),
                .energyAvailable(level: 0.7)
            ]
        )
    ]
    
    init() {
        self.transitions = Self.commonTransitions
    }
    
    func possibleTransitions(from stateId: Int) -> [Transition] {
        return transitions.filter { $0.from == stateId }
    }
    
    func transitionProbability(from: Int, to: Int) -> Double {
        return transitions.first { $0.from == from && $0.to == to }?.probability ?? 0.0
    }
    
    func addTransition(_ transition: Transition) {
        transitions.append(transition)
    }
    
    func removeTransition(id: UUID) {
        transitions.removeAll { $0.id == id }
    }
}

// MARK: - Example Psychological States with Structured Data

extension PsychologicalState {
    static let exampleStates: [PsychologicalState] = [
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
        )
    ]
}

extension PsychologicalState {
    var predictionError: String {
        parameters.predictionError.formattedAccuracy
    }

    var precision: String {
        let task = parameters.precision.task.formatted
        let distractor = parameters.precision.distractor.formatted
        return "Task \(task), Distractor \(distractor)"
    }

    var threshold: String {
        parameters.threshold.formattedRange
    }

    var somaticBias: String {
        parameters.somaticBias.formattedRange
    }
    
    /// Calculates similarity between two psychological states based on their parameters
    /// - Parameter other: The other state to compare with
    /// - Returns: A similarity score between 0 (completely different) and 1 (identical)
    func similarity(to other: PsychologicalState) -> Double {
        // Calculate similarity for each parameter and weight them
        let predictionErrorSimilarity = 1.0 - abs(
            (self.parameters.predictionError.accuracy.average - other.parameters.predictionError.accuracy.average) / 100.0
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
