import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
  import AppKit
#endif

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
  @State private var operationMessage = ""
  @State private var showingOperationResult = false
  @State private var isWorking = false

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

          HStack {
            Text("Privacy Policy Status")
            Spacer()
            Label(
              self.privacyPolicyAccepted ? "Accepted" : "Not Accepted",
              systemImage: self.privacyPolicyAccepted ? "checkmark.seal.fill" : "xmark.seal"
            )
            .foregroundColor(self.privacyPolicyAccepted ? .green : .red)
            .font(.caption)
          }
          .help("Policy acceptance is managed through onboarding and policy flow")
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
          .disabled(self.isWorking)

          Button("Delete All Data") {
            self.showingDataDeletion = true
          }
          .buttonStyle(.borderedProminent)
          .tint(.red)
          .disabled(self.isWorking)
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
        self.exportData()
      }
    } message: {
      Text("Export all your profile data in a portable format.")
    }
    .alert("Delete All Data", isPresented: self.$showingDataDeletion) {
      Button("Cancel", role: .cancel) {
      }
      Button("Delete", role: .destructive) {
        self.deleteAllData()
      }
    } message: {
      Text("This action cannot be undone. All your profiles and data will be permanently deleted.")
    }
    .alert("Data & Privacy", isPresented: self.$showingOperationResult) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(self.operationMessage)
    }
  }

  private func exportData() {
    self.isWorking = true
    Task {
      do {
        let profiles = try await PersistenceController.shared.fetchProfiles()
        let export = UserDataExport(
          profiles: profiles,
          exportDate: Date(),
          appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "Unknown",
          deviceInfo: ["platform": "macOS"]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(export)

        #if os(macOS)
          let panel = NSSavePanel()
          panel.allowedContentTypes = [.json]
          panel.nameFieldStringValue = "APGI_UserData_\(Int(Date().timeIntervalSince1970)).json"
          panel.title = "Export My Data"
          panel.begin { response in
            guard response == .OK, let url = panel.url else {
              self.isWorking = false
              return
            }
            do {
              try data.write(to: url, options: .atomic)
              self.operationMessage = "Data exported successfully to:\n\(url.path)"
            } catch {
              self.operationMessage = "Export failed: \(error.localizedDescription)"
            }
            self.showingOperationResult = true
            self.isWorking = false
          }
        #else
          self.operationMessage = "Data export is currently available on macOS only."
          self.showingOperationResult = true
          self.isWorking = false
        #endif
      } catch {
        await MainActor.run {
          self.operationMessage = "Export failed: \(error.localizedDescription)"
          self.showingOperationResult = true
          self.isWorking = false
        }
      }
    }
  }

  private func deleteAllData() {
    self.isWorking = true
    Task {
      do {
        let profiles = try await PersistenceController.shared.fetchProfiles()
        for profile in profiles {
          try await PersistenceController.shared.deleteProfile(profile)
        }

        try await SecurityManager.shared.clearAllSecureData()
        CrashReportingManager.shared.clearCrashReports()

        await MainActor.run {
          self.operationMessage = "All user data has been deleted successfully."
          self.showingOperationResult = true
          self.isWorking = false
        }
      } catch {
        await MainActor.run {
          self.operationMessage = "Deletion failed: \(error.localizedDescription)"
          self.showingOperationResult = true
          self.isWorking = false
        }
      }
    }
  }
}
