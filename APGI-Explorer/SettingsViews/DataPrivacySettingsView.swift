import SwiftUI
import os.log

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
  @State private var showingConsentReview = false
  @State private var showingWithdrawConsentConfirmation = false

  // Export/Delete operation states
  @State private var showingExportSuccess = false
  @State private var showingExportError = false
  @State private var showingDeleteSuccess = false
  @State private var showingDeleteError = false
  @State private var isExporting = false
  @State private var isDeleting = false
  @State private var exportURL: URL?
  @State private var errorMessage: String = ""
  @State private var deletedEntityCounts: [String: Int] = [:]

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

          // Privacy Policy Consent Status (read-only with explicit action)
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Privacy Policy")
                .font(.subheadline)
              Text(privacyPolicyAccepted ? "Accepted" : "Not Accepted")
                .font(.caption)
                .foregroundColor(privacyPolicyAccepted ? .green : .orange)
            }

            Spacer()

            if privacyPolicyAccepted {
              Button("Review") {
                showingConsentReview = true
              }
              .buttonStyle(.borderless)
            } else {
              Button("Accept...") {
                showingPrivacyPolicy = true
              }
              .buttonStyle(.borderedProminent)
              .tint(.blue)
            }
          }
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
      PrivacyPolicyView(onAccept: {
        privacyPolicyAccepted = true
      })
      .frame(minWidth: 600, minHeight: 500)
    }
    .sheet(isPresented: $showingConsentReview) {
      ConsentReviewSheet(
        isAccepted: privacyPolicyAccepted,
        onWithdraw: {
          showingWithdrawConsentConfirmation = true
        }
      )
      .frame(minWidth: 500, minHeight: 300)
    }
    .alert("Withdraw Consent?", isPresented: $showingWithdrawConsentConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Withdraw", role: .destructive) {
        privacyPolicyAccepted = false
        // Also disable related features
        enableDataCollection = false
        analyticsConsent = false
      }
    } message: {
      Text(
        "Withdrawing consent will disable data collection and analytics features. You can accept again at any time."
      )
    }
    .alert("Export Data", isPresented: self.$showingDataExport) {
      Button("Cancel", role: .cancel) {}
      Button("Export") {
        performDataExport()
      }
    } message: {
      Text(
        "Export all your profile data in a portable JSON format. This export includes all your profiles, quiz results, and settings."
      )
    }
    .alert("Delete All Data", isPresented: self.$showingDataDeletion) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        performDataDeletion()
      }
    } message: {
      Text(
        "This action cannot be undone. All your profiles, quiz results, and settings will be permanently deleted."
      )
    }
    .alert("Export Successful", isPresented: $showingExportSuccess) {
      Button("OK") {}
      Button("Show in Finder") {
        if let url = exportURL {
          NSWorkspace.shared.activateFileViewerSelecting([url])
        }
      }
    } message: {
      Text("Your data has been exported successfully to the Backups folder.")
    }
    .alert("Export Failed", isPresented: $showingExportError) {
      Button("OK") {}
    } message: {
      Text(errorMessage.isEmpty ? "Failed to export data. Please try again." : errorMessage)
    }
    .alert("Data Deleted", isPresented: $showingDeleteSuccess) {
      Button("OK") {}
    } message: {
      Text(deleteConfirmationMessage())
    }
    .alert("Delete Failed", isPresented: $showingDeleteError) {
      Button("OK") {}
    } message: {
      Text(errorMessage.isEmpty ? "Failed to delete some data. Please try again." : errorMessage)
    }
    .overlay {
      if isExporting || isDeleting {
        ProgressView()
          .scaleEffect(1.5)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color.black.opacity(0.2))
          .ignoresSafeArea()
      }
    }
  }

  private func performDataExport() {
    isExporting = true

    Task {
      do {
        let url = try await FileStorageManager.shared.createBackup()
        await MainActor.run {
          exportURL = url
          isExporting = false
          showingExportSuccess = true
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          isExporting = false
          showingExportError = true
        }
      }
    }
  }

  private func performDataDeletion() {
    isDeleting = true

    Task {
      do {
        let counts = try await deleteAllUserData()
        await MainActor.run {
          deletedEntityCounts = counts
          isDeleting = false
          showingDeleteSuccess = true
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          isDeleting = false
          showingDeleteError = true
        }
      }
    }
  }

  private func deleteAllUserData() async throws -> [String: Int] {
    let persistenceController = PersistenceController.shared
    let context = persistenceController.container.viewContext

    var deletedCounts: [String: Int] = [:]

    // Get all entities from the managed object model
    let entities = persistenceController.container.managedObjectModel.entities

    for entity in entities {
      guard let entityName = entity.name else { continue }

      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
      deleteRequest.resultType = .resultTypeCount

      do {
        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
        let count = result?.result as? Int ?? 0
        deletedCounts[entityName] = count
        os_log("Deleted %d %@ entities", log: OSLog.default, type: .info, count, entityName)
      } catch {
        os_log(
          "Error deleting %@: %{public}@", log: OSLog.default, type: .error, entityName,
          error.localizedDescription)
        deletedCounts[entityName] = -1  // Indicate error
      }
    }

    // Save context
    do {
      try context.save()
    } catch {
      os_log(
        "Error saving context after deletion: %{public}@", log: OSLog.default, type: .error,
        error.localizedDescription)
      throw error
    }

    // Reset UserDefaults (except critical system keys)
    resetUserDefaults()

    return deletedCounts
  }

  private func resetUserDefaults() {
    let defaults = UserDefaults.standard
    let keysToPreserve = [
      "hasCompletedOnboarding",  // Keep onboarding state
      "crashReportingConsent",  // Keep crash reporting consent
      "analyticsConsent",  // Keep analytics consent
    ]

    // Get all current keys
    let allKeys = defaults.dictionaryRepresentation().keys

    // Remove all keys except preserved ones
    for key in allKeys {
      if !keysToPreserve.contains(key) {
        defaults.removeObject(forKey: key)
      }
    }

    defaults.synchronize()
    os_log(
      "UserDefaults reset completed (preserved critical keys)", log: OSLog.default, type: .info)
  }

  private func deleteConfirmationMessage() -> String {
    var components: [String] = []

    for (entity, count) in deletedEntityCounts.sorted(by: { $0.key < $1.key }) {
      if count > 0 {
        components.append("• \(entity): \(count) deleted")
      } else if count == -1 {
        components.append("• \(entity): error during deletion")
      }
    }

    if components.isEmpty {
      return "No data was found to delete."
    }

    return "The following data has been permanently deleted:\n\n"
      + components.joined(separator: "\n")
  }
}
