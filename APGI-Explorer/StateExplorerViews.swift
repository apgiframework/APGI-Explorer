import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
public struct StateExplorerViews {
    private static let stateModel = StateModel()
    private static let transitionModel = StateTransitionModel()

    public static func interactiveStateView(for state: PsychologicalState) -> some View {
        InteractiveStateView(
            state: state,
            stateModel: self.stateModel,
            transitionModel: self.transitionModel
        )
    }
}
