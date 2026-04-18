import SwiftUI
import os.log

// MARK: - Empty State View

struct EmptyStateView: View {
  let icon: String
  let title: String
  let message: String
  let actionTitle: String?
  let action: (() -> Void)?

  init(
    icon: String, title: String, message: String, actionTitle: String? = nil,
    action: (() -> Void)? = nil
  ) {
    self.icon = icon
    self.title = title
    self.message = message
    self.actionTitle = actionTitle
    self.action = action
  }

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: self.icon)
        .font(.system(size: 60))
        .foregroundColor(AppColors.secondaryText)

      Text(self.title)
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(AppColors.primaryText)

      Text(self.message)
        .font(.body)
        .foregroundColor(AppColors.secondaryText)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      if let actionTitle, let action {
        Button(actionTitle, action: action)
          .buttonStyle(PrimaryButtonStyle())
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.primaryBackground)
  }
}

// MARK: - Predefined Empty States

extension EmptyStateView {
  static let noStates = EmptyStateView(
    icon: "brain.head.profile",
    title: "No States Available",
    message:
      "Psychological states could not be loaded. Please check your connection and try again.",
    actionTitle: "Retry",
    action: nil  // Will be set by the parent view
  )

  static let noSimilarStates = EmptyStateView(
    icon: "magnifyingglass",
    title: "No Similar States",
    message:
      "We couldn't find any states similar to the current one. Try adjusting your search criteria.",
    actionTitle: nil,
    action: nil
  )

  static let noTransitions = EmptyStateView(
    icon: "arrow.triangle.2.circlepath",
    title: "No Transitions Available",
    message:
      "No transition data is available for this state. This might be because it's an isolated state or data is still being collected.",
    actionTitle: nil,
    action: nil
  )

  static let noQuizData = EmptyStateView(
    icon: "questionmark.circle",
    title: "No Quiz Data",
    message:
      "Complete the APGI assessment to see your psychological profile and explore different states.",
    actionTitle: "Start Quiz",
    action: nil  // Will be set by the parent view
  )

  static let noProfiles = EmptyStateView(
    icon: "person.3.sequence",
    title: "No Profiles",
    message:
      "No psychological profiles have been created yet. Take the assessment to generate your first profile.",
    actionTitle: "Take Assessment",
    action: nil  // Will be set by the parent view
  )
}

// MARK: - Preview

struct EmptyStateView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      EmptyStateView.noStates
        .previewDisplayName("No States")

      EmptyStateView.noSimilarStates
        .previewDisplayName("No Similar States")

      EmptyStateView(
        icon: "tray",
        title: "Custom Empty State",
        message: "This is a custom empty state with an action button.",
        actionTitle: "Do Something",
        action: { os_log("Action tapped", log: OSLog.default, type: .info) }
      )
      .previewDisplayName("Custom with Action")
    }
  }
}
