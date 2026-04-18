import CoreSpotlight
import Intents
import SwiftUI

enum HandoffActivity {
  static let activityType = "com.apgi.continue-quiz"

  static func createUserActivity(quizModel: QuizModel, currentQuestionIndex: Int) -> NSUserActivity
  {
    let activity = NSUserActivity(activityType: activityType)
    activity.title = "Continue APGI Quiz"
    activity.isEligibleForHandoff = true
    activity.isEligibleForSearch = true
    activity.isEligibleForPublicIndexing = false

    // Add state information
    activity.userInfo = [
      "questionIndex": currentQuestionIndex,
      "answers": quizModel.answers,
      "timestamp": Date().timeIntervalSince1970,
    ]

    // Add content attributes for search
    if #available(iOS 14.0, *) {
      let attributes = CSSearchableItemAttributeSet()
      attributes.title = "Continue APGI Quiz"
      attributes.contentDescription = "Continue your APGI personality assessment"
      activity.contentAttributeSet = attributes
    }

    return activity
  }

  static func restoreUserActivity(_ activity: NSUserActivity, currentQuestionIndex: Binding<Int>)
    -> [Int: Int]?
  {
    guard activity.activityType == self.activityType,
      let userInfo = activity.userInfo,
      let answers = userInfo["answers"] as? [Int: Int],
      let questionIndex = userInfo["questionIndex"] as? Int,
      let timestamp = userInfo["timestamp"] as? TimeInterval
    else {
      return nil
    }

    // Don't restore if the activity is too old (older than 7 days)
    let activityDate = Date(timeIntervalSince1970: timestamp)
    if abs(activityDate.timeIntervalSinceNow) > 60 * 60 * 24 * 7 {
      return nil
    }

    // Restore the question index
    currentQuestionIndex.wrappedValue = questionIndex

    // Return the restored answers
    return answers
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
