import SwiftUI

// MARK: - General Settings View

struct GeneralSettingsView: View {
  @AppStorage("autoSaveEnabled") private var autoSaveProfiles: Bool = true
  @AppStorage("showTooltips") private var showTooltips: Bool = true
  @AppStorage("animationSpeed") private var animationSpeed: Double = 1.0
  @AppStorage("analyticsEnabled") private var enableAnalytics: Bool = false
  @AppStorage("betaUpdates") private var betaUpdates: Bool = false
  @AppStorage("defaultProfileName") private var defaultProfileName: String = "My Profile"

  @StateObject private var validationManager = SettingsValidationManager()

  @Environment(\.showTooltips) private var tooltipsEnabled

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        ExplorerAPIStatusView()
        ResearchEntryView()
        // Profile Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Profile")
            .font(.headline)
            .fontWeight(.semibold)

          ValidatedTextField(
            title: "Default Profile Name",
            text: self.$defaultProfileName,
            validator: self.validationManager.validateDefaultProfileName
          )
          .conditionalHelp("The default name assigned to newly created profiles", when: tooltipsEnabled)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)

        // Data Management Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Data Management")
            .font(.headline)
            .fontWeight(.semibold)

          Toggle("Auto-save Profiles", isOn: self.$autoSaveProfiles)
            .conditionalHelp("Automatically save profile changes", when: tooltipsEnabled)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)

        // Interface Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Interface")
            .font(.headline)
            .fontWeight(.semibold)

          Toggle("Show Tooltips", isOn: self.$showTooltips)
            .conditionalHelp("Display helpful tooltips throughout the app", when: true)  // Always show help for this setting

          HStack {
            Text("Animation Speed")
            Spacer()
            Text("\(self.animationSpeed, specifier: "%.1f")x")
              .foregroundColor(.secondary)
          }

          Slider(value: self.$animationSpeed, in: 0.5...2.0, step: 0.1)
            .conditionalHelp("Control the speed of UI animations", when: tooltipsEnabled)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)

        // Analytics Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Analytics & Feedback")
            .font(.headline)
            .fontWeight(.semibold)

          Toggle("Enable Analytics", isOn: self.$enableAnalytics)
            .conditionalHelp("Help improve the app by sharing anonymous usage data", when: tooltipsEnabled)

          Toggle("Beta Updates", isOn: self.$betaUpdates)
            .conditionalHelp("Receive early access to new features and updates", when: tooltipsEnabled)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
      }
      .padding()
    }
    .navigationTitle("General")
  }
}
