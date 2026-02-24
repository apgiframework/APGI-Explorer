import os.log
import SwiftUI

// MARK: - Advanced Settings View

struct AdvancedSettingsView: View {
    @AppStorage("enableExperimentalFeatures") private var enableExperimentalFeatures: Bool = false
    @AppStorage("betaUpdates") private var betaUpdates: Bool = false
    @AppStorage("showPerformanceMetrics") private var showPerformanceMetrics: Bool = false
    @AppStorage("enableDebugMode") private var enableDebugMode: Bool = false

    @State private var showingResetAlert = false
    @State private var showingClearDataAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Experimental Features Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Experimental Features")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Toggle("Enable Experimental Features", isOn: self.$enableExperimentalFeatures)
                        .help("Enable access to experimental features that may be unstable")

                    Toggle("Beta Updates", isOn: self.$betaUpdates)
                        .help("Receive early access to beta versions and features")
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
                        .help("Display performance metrics and debugging information")

                    Toggle("Enable Debug Mode", isOn: self.$enableDebugMode)
                        .help("Enable additional debugging features and logging")
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
            Button("Cancel", role: .cancel) {
            }
            Button("Clear", role: .destructive) {
                self.clearAllData()
            }
        } message: {
            Text("This will permanently delete all profiles and data. This action cannot be undone.")
        }
    }

    private func resetAllSettings() {
        // Reset all UserDefaults to default values
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        UserDefaults.standard.synchronize()
    }

    private func clearAllData() {
        // Clear all Core Data
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        let entities = persistenceController.container.managedObjectModel.entities
        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                do {
                    try context.execute(deleteRequest)
                } catch {
                    os_log("Error deleting %@: %@", entityName, error.localizedDescription)
                }
            }
        }

        do {
            try context.save()
        } catch {
            os_log("Error saving context after clearing data: %@", error.localizedDescription)
        }
    }
}
