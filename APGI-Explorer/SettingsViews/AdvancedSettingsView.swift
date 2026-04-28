import SwiftUI
import os.log

// MARK: - Advanced Settings View

struct AdvancedSettingsView: View {
  @AppStorage("enableExperimentalFeatures") private var enableExperimentalFeatures: Bool = false
  @AppStorage("showPerformanceMetrics") private var showPerformanceMetrics: Bool = false
  @AppStorage("enableDebugMode") private var enableDebugMode: Bool = false

  @Environment(\.showTooltips) private var tooltipsEnabled

  @State private var showingResetAlert = false
  @State private var showingClearDataAlert = false

  // Clear data operation states
  @State private var showingClearDataResult = false
  @State private var showingClearDataError = false
  @State private var isClearingData = false
  @State private var deletedEntityCounts: [String: Int] = [:]
  @State private var errorMessage: String = ""

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Experimental Features Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Experimental Features")
            .font(.headline)
            .fontWeight(.semibold)

          Toggle("Enable Experimental Features", isOn: self.$enableExperimentalFeatures)
            .conditionalHelp("Enable access to experimental features that may be unstable", when: tooltipsEnabled)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)

        // Debug Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Debug Options")
            .font(.headline)
            .fontWeight(.semibold)

          Toggle("Show Performance Metrics", isOn: self.$showPerformanceMetrics)
            .conditionalHelp("Display performance metrics and debugging information", when: tooltipsEnabled)

          Toggle("Enable Debug Mode", isOn: self.$enableDebugMode)
            .conditionalHelp("Enable additional debugging features and logging", when: tooltipsEnabled)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)

        // Reset Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Reset Options")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.red)

          Button("Reset All Settings") {
            self.showingResetAlert = true
          }
          .buttonStyle(.bordered)
          .tint(.orange)

          Button("Clear All Data") {
            self.showingClearDataAlert = true
          }
          .buttonStyle(.borderedProminent)
          .tint(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
      }
      .padding()
    }
    .navigationTitle("Advanced")
    .alert("Reset Settings", isPresented: self.$showingResetAlert) {
      Button("Cancel", role: .cancel) {
      }
      Button("Reset", role: .destructive) {
        self.resetAllSettings()
      }
    } message: {
      Text("This will reset all settings to their default values. This action cannot be undone.")
    }
    .alert("Clear All Data", isPresented: self.$showingClearDataAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Clear", role: .destructive) {
        self.clearAllDataWithReporting()
      }
    } message: {
      Text("This will permanently delete all profiles and data. This action cannot be undone.")
    }
    .alert("Data Cleared", isPresented: $showingClearDataResult) {
      Button("OK") {}
    } message: {
      Text(clearDataResultMessage())
    }
    .alert("Clear Data Failed", isPresented: $showingClearDataError) {
      Button("OK") {}
    } message: {
      Text(errorMessage.isEmpty ? "Failed to clear some data. Please try again." : errorMessage)
    }
    .overlay {
      if isClearingData {
        ProgressView("Clearing data...")
          .scaleEffect(1.2)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color.black.opacity(0.2))
          .ignoresSafeArea()
      }
    }
  }

  private func resetAllSettings() {
    // Reset all UserDefaults to default values (except critical consent keys)
    let keysToPreserve = [
      "hasCompletedOnboarding",
      "crashReportingConsent",
      "analyticsConsent",
      "privacyPolicyAccepted"
    ]

    let defaults = UserDefaults.standard
    let allKeys = defaults.dictionaryRepresentation().keys

    for key in allKeys where !keysToPreserve.contains(key) {
      defaults.removeObject(forKey: key)
    }

    defaults.synchronize()
    os_log("Settings reset completed (preserved critical keys)", log: OSLog.default, type: .info)
  }

  private func clearAllDataWithReporting() {
    isClearingData = true

    Task {
      do {
        let counts = try await performClearAllData()
        await MainActor.run {
          deletedEntityCounts = counts
          isClearingData = false
          showingClearDataResult = true
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          isClearingData = false
          showingClearDataError = true
        }
      }
    }
  }

  private func performClearAllData() async throws -> [String: Int] {
    let persistenceController = PersistenceController.shared
    let context = persistenceController.container.viewContext

    var deletedCounts: [String: Int] = [:]
    var hasErrors = false

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
        hasErrors = true
      }
    }

    // Save context
    do {
      try context.save()
    } catch {
      os_log(
        "Error saving context after clearing data: %{public}@", log: OSLog.default, type: .error,
        error.localizedDescription)
      throw error
    }

    // Reset UserDefaults (except critical keys)
    resetUserDefaultsAfterClear()

    if hasErrors {
      throw AdvancedSettingsError.partialDeletion
    }

    return deletedCounts
  }

  private func resetUserDefaultsAfterClear() {
    let defaults = UserDefaults.standard
    let keysToPreserve = [
      "hasCompletedOnboarding",
      "crashReportingConsent",
      "analyticsConsent",
      "privacyPolicyAccepted"
    ]

    let allKeys = defaults.dictionaryRepresentation().keys

    for key in allKeys where !keysToPreserve.contains(key) {
      defaults.removeObject(forKey: key)
    }

    defaults.synchronize()
    os_log("UserDefaults cleared (preserved critical keys)", log: OSLog.default, type: .info)
  }

  private func clearDataResultMessage() -> String {
    var components: [String] = []
    var totalDeleted = 0
    var errorCount = 0

    for (entity, count) in deletedEntityCounts.sorted(by: { $0.key < $1.key }) {
      if count > 0 {
        components.append("• \(entity): \(count) deleted")
        totalDeleted += count
      } else if count == -1 {
        components.append("• \(entity): error")
        errorCount += 1
      }
    }

    if components.isEmpty {
      return "No data was found to delete."
    }

    var message = "Deleted \(totalDeleted) total records:\n\n" + components.joined(separator: "\n")

    if errorCount > 0 {
      message += "\n\nNote: \(errorCount) entity type(s) encountered errors during deletion."
    }

    return message
  }
}

enum AdvancedSettingsError: LocalizedError {
  case partialDeletion

  var errorDescription: String? {
    switch self {
    case .partialDeletion:
      return "Some data could not be deleted due to errors."
    }
  }
}
