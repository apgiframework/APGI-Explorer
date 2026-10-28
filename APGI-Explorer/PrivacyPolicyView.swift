import SwiftUI
import os.log

struct PrivacyPolicyView: View {
  @Environment(\.dismiss) private var dismiss: DismissAction
  @State private var consentToAnalytics = false
  @State private var consentToCrashReporting = false
  @AppStorage("privacyPolicyAccepted") private var privacyPolicyAccepted = false
  @AppStorage("analyticsConsent") private var analyticsConsent = false
  @AppStorage("crashReportingConsent") private var crashReportingConsent = false

  var onAccept: (() -> Void)?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: LayoutConstants.mediumSpacing) {
          // Header
          VStack(alignment: .leading, spacing: LayoutConstants.smallSpacing) {
            Text("Privacy Policy")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(AppColors.primaryText)

            Text("Last updated: October 27, 2026")
              .font(.caption)
              .foregroundColor(AppColors.secondaryText)
          }
          .padding(.bottom)

          // Privacy Policy Content
          Text(
            "Personal questionnaire answers, answer changes and response timing are stored locally. "
              + "The app requests public release metadata from api.apgiframework.com without sending questionnaire answers. "
              + "Research participation and paid products are unavailable in this release."
          )
            .font(.body)
          self.privacyPolicyContent

          // Data Collection Section
          self.dataCollectionSection

          // Consent Section
          self.consentSection

          // Action Buttons
          self.actionButtons
        }
        .padding()
      }
      .navigationTitle("Privacy Policy")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        #if os(iOS)
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Close") {
              self.dismiss()
            }
            .accessibilityLabel("Close privacy policy")
          }
        #else
          ToolbarItem(placement: .primaryAction) {
            Button("Close") {
              self.dismiss()
            }
            .accessibilityLabel("Close privacy policy")
          }
        #endif
      }
    }
  }

  private var privacyPolicyContent: some View {
    VStack(alignment: .leading, spacing: LayoutConstants.mediumSpacing) {
      // Introduction
      InfoCard(title: "Our Commitment to Privacy") {
        Text(
          "APGI Explorer is committed to protecting your privacy and ensuring the security "
            + "of your personal data. This privacy policy explains how we collect, use, and protect "
            + "your information when you use our application."
        )
        .font(.body)
      }

      // Data We Collect
      InfoCard(title: "Information We Collect") {
        VStack(alignment: .leading, spacing: LayoutConstants.smallSpacing) {
          Text(
            "• **Psychological Assessment Data**: Your quiz responses and "
              + "generated profiles are stored locally on your device.")
          Text(
            "• **Usage Analytics**: Anonymous usage patterns to improve the app experience (optional)."
          )
          Text("• **Crash Reports**: Technical information when the app crashes (optional).")
          Text("• **Device Information**: Basic device type and OS version for compatibility.")
        }
        .font(.body)
      }

      // How We Use Data
      InfoCard(title: "How We Use Your Data") {
        VStack(alignment: .leading, spacing: LayoutConstants.smallSpacing) {
          Text("• **Profile Generation**: To create and store your psychological profiles.")
          Text("• **App Improvement**: Anonymous analytics help us understand usage patterns.")
          Text("• **Bug Fixes**: Crash reports help us identify and fix issues.")
          Text("• **Feature Development**: Usage data guides our development priorities.")
        }
        .font(.body)
      }

      // Data Protection
      InfoCard(title: "Data Protection & Security") {
        VStack(alignment: .leading, spacing: LayoutConstants.smallSpacing) {
          Text("• **Local Storage**: All personal data is stored locally on your device.")
          Text("• **No Cloud Sync**: We don't automatically sync your data to cloud services.")
          Text("• **Encryption**: Sensitive data is encrypted when stored.")
          Text("• **No Third-Party Sharing**: We never sell or share your personal data.")
        }
        .font(.body)
      }

      // Your Rights
      InfoCard(title: "Your Rights") {
        VStack(alignment: .leading, spacing: LayoutConstants.smallSpacing) {
          Text("• **Access**: You can view all data stored about you in the app.")
          Text("• **Export**: Export your profiles and data at any time.")
          Text("• **Delete**: Remove your data and profiles permanently.")
          Text("• **Consent**: Choose what data to share for analytics and crash reporting.")
        }
        .font(.body)
      }
    }
  }

  private var dataCollectionSection: some View {
    VStack(alignment: .leading, spacing: LayoutConstants.mediumSpacing) {
      Text("Data Collection Preferences")
        .font(.headline)
        .foregroundColor(AppColors.primaryText)

      VStack(spacing: LayoutConstants.smallSpacing) {
        // Analytics Consent
        ToggleRow(
          title: "Anonymous Analytics",
          description: "Help improve APGI Explorer by sharing anonymous usage data",
          isOn: self.$consentToAnalytics
        )

        // Crash Reporting Consent
        ToggleRow(
          title: "Crash Reports",
          description: "Automatically send crash reports to help us fix bugs",
          isOn: self.$consentToCrashReporting
        )
      }
      .padding()
      .background(AppColors.cardBackground)
      .cornerRadius(LayoutConstants.cardCornerRadius)
    }
  }

  private var consentSection: some View {
    VStack(alignment: .leading, spacing: LayoutConstants.mediumSpacing) {
      Text("Consent & Agreement")
        .font(.headline)
        .foregroundColor(AppColors.primaryText)

      Text(
        "By using APGI Explorer, you acknowledge that you have read and understood this privacy "
          + "policy. You can change your data sharing preferences at any time in Settings."
      )
      .font(.body)
      .foregroundColor(AppColors.secondaryText)
    }
  }

  private var actionButtons: some View {
    VStack(spacing: LayoutConstants.smallSpacing) {
      Button(
        action: {
          self.saveConsentPreferences()
          self.privacyPolicyAccepted = true
          onAccept?()
          HapticFeedback.shared.lightImpact()
          self.dismiss()
        },
        label: {
          Text("Accept & Continue")
            .frame(maxWidth: .infinity)
        }
      )
      .buttonStyle(PrimaryButtonStyle())
      .accessibilityLabel("Accept privacy policy and continue")

      Button("Export My Data") {
        self.exportUserData()
      }
      .buttonStyle(SecondaryButtonStyle())
      .accessibilityLabel("Export all my data")

      Button("Delete All Data") {
        self.deleteAllData()
      }
      .buttonStyle(DestructiveButtonStyle())
      .accessibilityLabel("Delete all my data")
    }
    .padding(.top)
  }

  private func saveConsentPreferences() {
    self.analyticsConsent = self.consentToAnalytics
    self.crashReportingConsent = self.consentToCrashReporting

    // Update analytics settings
    if self.consentToAnalytics {
      #if os(iOS)
        AnalyticsService.shared.enableAnalytics()
      #endif
    } else {
      #if os(iOS)
        AnalyticsService.shared.disableAnalytics()
      #endif
    }

    // Update crash reporting settings
    if self.consentToCrashReporting {
      CrashReportingManager.shared.enableCrashReporting()
    } else {
      CrashReportingManager.shared.disableCrashReporting()
    }
  }

  private func exportUserData() {
    Task {
      do {
        let profileManager = ProfileManager()
        let url = try await profileManager.exportAllUserData()

        #if os(iOS)
          HapticFeedback.shared.notification(.success)
        #endif
        // Show share sheet or save file
        os_log("Data exported to: %@", url.absoluteString)
      } catch {
        #if os(iOS)
          HapticFeedback.shared.notification(.error)
        #endif
        ErrorHandlingManager.shared.handle(error, context: "Privacy Policy Export")
      }
    }
  }

  private func deleteAllData() {
    // Show confirmation dialog
    // This would need to be implemented with proper confirmation
    Task {
      do {
        let profileManager = ProfileManager()
        try await profileManager.deleteAllUserData()
        #if os(iOS)
          HapticFeedback.shared.notification(.success)
        #endif
        os_log("All user data deleted")
      } catch {
        #if os(iOS)
          HapticFeedback.shared.notification(.error)
        #endif
        ErrorHandlingManager.shared.handle(error, context: "Privacy Policy Delete")
      }
    }
  }
}

struct ToggleRow: View {
  let title: String
  let description: String
  @Binding var isOn: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: LayoutConstants.tinySpacing) {
      HStack {
        Text(self.title)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(AppColors.primaryText)

        Spacer()

        Toggle("", isOn: self.$isOn)
          .labelsHidden()
          .accessibilityLabel(self.title)
          .accessibilityHint(self.description)
      }

      Text(self.description)
        .font(.caption)
        .foregroundColor(AppColors.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Consent Review Sheet

struct ConsentReviewSheet: View {
  @Environment(\.dismiss) private var dismiss
  let isAccepted: Bool
  let onWithdraw: () -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          // Status Icon
          Image(systemName: isAccepted ? "checkmark.shield.fill" : "exclamationmark.shield")
            .font(.system(size: 60))
            .foregroundColor(isAccepted ? .green : .orange)

          // Status Title
          Text("Privacy Policy Consent")
            .font(.title)
            .fontWeight(.bold)

          // Status Description
          VStack(spacing: 16) {
            HStack {
              Image(systemName: isAccepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isAccepted ? .green : .red)
              Text("Status: \(isAccepted ? "Accepted" : "Not Accepted")")
                .font(.headline)
              Spacer()
            }

            if isAccepted {
              Text(
                "You have previously accepted the Privacy Policy. Your consent allows us to provide analytics and crash reporting features."
              )
              .font(.body)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
            } else {
              Text(
                "You have not yet accepted the Privacy Policy. Please review and accept to enable all features."
              )
              .font(.body)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
            }
          }
          .padding()
          .background(Color.secondary.opacity(0.1))
          .cornerRadius(12)

          // Actions
          VStack(spacing: 12) {
            if isAccepted {
              Button("View Privacy Policy") {
                dismiss()
              }
              .buttonStyle(.bordered)

              Button("Withdraw Consent") {
                onWithdraw()
                dismiss()
              }
              .buttonStyle(.borderedProminent)
              .tint(.red)
            } else {
              Button("Review and Accept") {
                dismiss()
              }
              .buttonStyle(.borderedProminent)
            }
          }

          Spacer()
        }
        .padding()
      }
      .navigationTitle("Consent Status")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            dismiss()
          }
        }
      }
    }
    .frame(minWidth: 500, minHeight: 400)
  }
}

#Preview {
  PrivacyPolicyView()
}
