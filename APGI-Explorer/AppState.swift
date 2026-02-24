import Combine
import Foundation

class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(self.hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    static let shared = AppState()

    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    func completeOnboarding() {
        self.hasCompletedOnboarding = true
    }
}
