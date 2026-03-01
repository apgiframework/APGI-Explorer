import Combine
import Foundation
import SwiftUI

class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    static let shared = AppState()

    private init() {
    }

    func completeOnboarding() {
        self.hasCompletedOnboarding = true
    }
}
