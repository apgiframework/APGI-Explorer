import SwiftUI

typealias StateTransition = StateTransitionModel.Transition

struct TransitionView: View {
    let transition: StateTransition
    let states: [PsychologicalState]

    private var fromState: PsychologicalState? {
        self.states.first { $0.id == self.transition.from }
    }

    private var toState: PsychologicalState? {
        self.states.first { $0.id == self.transition.toState }
    }

    var body: some View {
        if let fromState, let toState {
            VStack(alignment: .leading, spacing: LayoutConstants.tinySpacing) {
                HStack {
                    Text(fromState.name)
                        .font(.subheadline)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    Text(toState.name)
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.0f%%", self.transition.probability * DataConstants.probabilityMultiplier))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }

                if !self.transition.triggers.isEmpty {
                    Text("Triggers:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    ForEach(Array(self.transition.triggers.enumerated()), id: \.offset) { _, trigger in
                        Text(trigger.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, LayoutConstants.tinySpacing)
        }
    }
}

extension StateTransitionModel.Transition.Trigger: CustomStringConvertible {
    var description: String {
        switch self {
        case let .parameterShift(parameter, direction, magnitude):
            "\(parameter.rawValue) \(direction.rawValue) by \(String(format: "%.1f", magnitude))"
        case let .externalEvent(type):
            "External: \(type.rawValue)"
        case let .temporalFactor(duration):
            "After \(Int(duration))s"
        case let .metabolicConstraint(level):
            "Metabolic: \(level.rawValue)"
        case let .socialContext(context):
            "Social: \(context.rawValue)"
        }
    }
}
