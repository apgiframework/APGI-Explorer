import SwiftUI

// MARK: - Data & Privacy Settings View

struct DataPrivacySettingsView: View {
  @AppStorage("enableCrashReporting") private var enableCrashReporting: Bool = true
  @AppStorage("enableDataCollection") private var enableDataCollection: Bool = false
  @AppStorage("privacyPolicyAccepted") private var privacyPolicyAccepted: Bool = false
  @AppStorage("analyticsConsent") private var analyticsConsent: Bool = false
  @AppStorage("crashReportingConsent") private var crashReportingConsent: Bool = false

  @State private var showingPrivacyPolicy = false
  @State private var showingDataExport = false
  @State private var showingDataDeletion = false

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 20) {
        // Privacy Settings Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Privacy Controls")
            .font(.headline)
            .fontWeight(.semibold)

          Toggle("Enable Crash Reporting", isOn: self.$enableCrashReporting)
            .help("Automatically send crash reports to help improve the app")

          Toggle("Enable Data Collection", isOn: self.$enableDataCollection)
            .help("Allow collection of anonymous usage data for analytics")

          Toggle("Privacy Policy Accepted", isOn: self.$privacyPolicyAccepted)
            .help("You must accept the privacy policy to use the app")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)

        // Consent Management Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Consent Management")
            .font(.headline)
            .fontWeight(.semibold)

          Toggle("Analytics Consent", isOn: self.$analyticsConsent)
            .help("Consent to analytics data collection")

          Toggle("Crash Reporting Consent", isOn: self.$crashReportingConsent)
            .help("Consent to automatic crash reporting")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)

        // Data Management Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Data Management")
            .font(.headline)
            .fontWeight(.semibold)

          Button("View Privacy Policy") {
            self.showingPrivacyPolicy = true
          }
          .buttonStyle(.bordered)

          Button("Export My Data") {
            self.showingDataExport = true
          }
          .buttonStyle(.bordered)

          Button("Delete All Data") {
            self.showingDataDeletion = true
          }
          .buttonStyle(.borderedProminent)
          .tint(.red)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
      }
      .padding()
    }
    .navigationTitle("Data & Privacy")
    .sheet(isPresented: self.$showingPrivacyPolicy) {
      PrivacyPolicyView()
        .frame(minWidth: 600, minHeight: 500)
    }
    .alert("Export Data", isPresented: self.$showingDataExport) {
      Button("Cancel", role: .cancel) {
      }
      Button("Export") {
        // Handle data export
      }
    } message: {
      Text("Export all your profile data in a portable format.")
    }
    .alert("Delete All Data", isPresented: self.$showingDataDeletion) {
      Button("Cancel", role: .cancel) {
      }
      Button("Delete", role: .destructive) {
        // Handle data deletion
      }
    } message: {
      Text("This action cannot be undone. All your profiles and data will be permanently deleted.")
    }
  }
}
