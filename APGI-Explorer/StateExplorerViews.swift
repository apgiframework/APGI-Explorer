// StateExplorerViews.swift
import SwiftUI

/// Factory for creating interactive psychological state exploration views
/// 
/// This struct provides a public API for creating views that allow users to explore
/// and interact with different psychological states. It encapsulates the state models
/// and provides a clean interface for view creation.
/// 
/// - Note: Available on iOS 16.0+ and macOS 13.0+
@available(iOS 16.0, macOS 13.0, *)
public struct StateExplorerViews {
    private static let stateModel = StateModel()
    private static let transitionModel = StateTransitionModel()

    /// Creates an interactive view for exploring a specific psychological state
    /// 
    /// - Parameter state: The psychological state to create an interactive view for
    /// - Returns: A view that allows users to interact with and explore the state
    public static func interactiveStateView(for state: PsychologicalState) -> some View {
        InteractiveStateView(
            state: state,
            stateModel: stateModel,
            transitionModel: transitionModel
        )
    }
}
