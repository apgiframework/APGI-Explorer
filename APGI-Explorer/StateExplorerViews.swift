import SwiftUI

/// A factory struct that provides access to state exploration views for psychological state visualization.
/// This struct serves as a centralized access point for creating interactive views that allow users
/// to explore and compare different psychological states within the APGI framework.
@available(iOS 16.0, macOS 13.0, *)
public struct StateExplorerViews {
  /// Shared state model instance used across all state exploration views
  private static let stateModel = StateModel()
  /// Shared transition model instance used across all state exploration views
  private static let transitionModel = StateTransitionModel()

  /// Creates an interactive state view for the given psychological state.
  /// - Parameter state: The psychological state to visualize.
  /// - Returns: An interactive view for exploring the state.
  public static func interactiveStateView(for state: PsychologicalState) -> some View {
    InteractiveStateView(
      state: state,
      stateModel: self.stateModel,
      transitionModel: self.transitionModel
    )
  }
}
