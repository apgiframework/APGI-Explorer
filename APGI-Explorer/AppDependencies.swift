import Combine
import Foundation
import SwiftUI

// MARK: - App Dependencies Coordinator

/// A centralized dependency injection container that manages shared app instances
class AppDependencies: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var profileManager: ProfileManager

    // MARK: - Core Dependencies

    let stateModel: StateModel
    let transitionModel: StateTransitionModel
    let analyticsService: AnalyticsService
    let stateSearchService: StateSearchService

    // MARK: - Singleton

    static let shared = AppDependencies()

    // MARK: - Initialization

    private init() {
        // Initialize all properties first
        self.stateModel = StateModel()
        self.transitionModel = StateTransitionModel()
        self.profileManager = ProfileManager()
        self.analyticsService = ConsoleAnalyticsService()
        self.stateSearchService = StateSearchService()
    }

    // MARK: - Convenience Methods

    /// Creates a new InteractiveStateView with injected dependencies
    func makeInteractiveStateView(state: PsychologicalState) -> InteractiveStateView {
        InteractiveStateView(
            state: state,
            stateModel: self.stateModel,
            transitionModel: self.transitionModel
        )
    }

    /// Provides dependencies for views that need StateModel
    func getStateModel() -> StateModel {
        self.stateModel
    }

    /// Provides dependencies for views that need StateTransitionModel
    func getTransitionModel() -> StateTransitionModel {
        self.transitionModel
    }

    /// Provides dependencies for views that need ProfileManager
    func getProfileManager() -> ProfileManager {
        self.profileManager
    }

    func getAnalyticsService() -> AnalyticsService {
        self.analyticsService
    }

    func getStateSearchService() -> StateSearchService {
        self.stateSearchService
    }

    /// Clears all cached similarity calculations
    func clearStateCache() {
        self.stateModel.clearCache()
    }
}

// MARK: - Environment Key for SwiftUI

struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies.shared
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Injects AppDependencies into the SwiftUI environment
    func withAppDependencies(_ dependencies: AppDependencies = AppDependencies.shared) -> some View {
        self.environment(\.appDependencies, dependencies)
    }
}
