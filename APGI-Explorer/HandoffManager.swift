import CoreSpotlight
import Intents
import SwiftUI

enum HandoffActivity {
    static let activityType = "com.apgi.continue-quiz"

    static func createUserActivity(quizModel: QuizModel, currentQuestionIndex: Int) -> NSUserActivity {
        let activity = NSUserActivity(activityType: activityType)
        activity.title = "Continue APGI Quiz"
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = false

        activity.userInfo = ["sessionID": quizModel.sessionID.uuidString]
        activity.isEligibleForSearch = false

        return activity
    }

    static func restoreUserActivity(_ activity: NSUserActivity, currentQuestionIndex: Binding<Int>)
        -> [Int: Int]? {
        // Personal data is local-only. Remote session resolution requires research mode.
        return nil
    }
}

// MARK: - View Modifier for Handoff Support

struct HandoffModifier: ViewModifier {
    let activity: NSUserActivity
    @State private var isActive = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                self.isActive = true
                self.activity.becomeCurrent()
            }
            .onDisappear {
                self.isActive = false
                self.activity.invalidate()
            }
            .onChange(of: self.isActive) {
                if self.isActive {
                    self.activity.becomeCurrent()
                } else {
                    self.activity.invalidate()
                }
            }
    }
}

extension View {
    func withHandoffSupport(activity: NSUserActivity) -> some View {
        self.modifier(HandoffModifier(activity: activity))
    }
}
