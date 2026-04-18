import Combine
import Foundation

class StateTransitionModel: ObservableObject {
  @Published var transitions: [Transition] = []
  @Published var currentState: PsychologicalState?

  struct Transition: Identifiable, Codable {
    let id: UUID
    let from: Int  // state ID
    let toState: Int  // state ID
    let probability: Double
    let triggers: [Trigger]
    let duration: TimeInterval  // typical transition time
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
      from: 13,  // Engagement
      toState: 1,  // Flow
      probability: 0.3,
      triggers: [
        .parameterShift(parameter: .threshold, direction: .decrease, magnitude: 0.05),
        .temporalFactor(duration: 600),  // 10 min of sustained engagement
      ],
      duration: 300,
      conditions: [
        .timeInState(duration: 600),
        .thresholdMet(parameter: .precision, value: 4.0),
      ]
    ),
    Transition(
      from: 1,  // Flow
      toState: 35,  // Overwhelm
      probability: 0.15,
      triggers: [
        .parameterShift(parameter: .precision, direction: .increase, magnitude: 2.0),
        .externalEvent(type: .threat),
      ],
      duration: 60,
      conditions: [
        .thresholdMet(parameter: .predictionError, value: 4.0)
      ]
    ),
    Transition(
      from: 15,  // Neutrality
      toState: 12,  // Curiosity
      probability: 0.4,
      triggers: [
        .externalEvent(type: .novelty),
        .parameterShift(parameter: .threshold, direction: .decrease, magnitude: 0.1),
      ],
      duration: 120,
      conditions: [
        .contextAvailable(context: "novel stimuli")
      ]
    ),
    Transition(
      from: 20,  // Anxiety
      toState: 8,  // Serenity
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
