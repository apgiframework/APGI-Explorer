// TransitionView.swift
import SwiftUI

struct TransitionView: View {
    let transition: StateTransitionModel.Transition
    let states: [PsychologicalState]

    private var fromState: PsychologicalState? {
        states.first { $0.id == transition.from }
    }

    private var toState: PsychologicalState? {
        states.first { $0.id == transition.toState }
    }

    var body: some View {
        if let fromState = fromState, let toState = toState {
            VStack(alignment: .leading, spacing: LayoutConstants.tinySpacing) {
                HStack {
                    Text(fromState.name)
                        .font(.subheadline)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    Text(toState.name)
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.0f%%", transition.probability * DataConstants.probabilityMultiplier))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }

                if !transition.triggers.isEmpty {
                    Text("Triggers:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    ForEach(Array(transition.triggers.enumerated()), id: \.offset) { _, trigger in
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
        case .parameterShift(let parameter, let direction, let magnitude):
            return "\(parameter.rawValue) \(direction.rawValue) by \(String(format: "%.1f", magnitude))"
        case .externalEvent(let type):
            return "External: \(type.rawValue)"
        case .temporalFactor(let duration):
            return "After \(Int(duration))s"
        case .metabolicConstraint(let level):
            return "Metabolic: \(level.rawValue)"
        case .socialContext(let context):
            return "Social: \(context.rawValue)"
        }
    }
}
