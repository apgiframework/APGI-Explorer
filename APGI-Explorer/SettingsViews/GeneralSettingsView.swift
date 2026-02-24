import SwiftUI

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @AppStorage("autoSaveEnabled") private var autoSaveProfiles: Bool = true
    @AppStorage("showTooltips") private var showTooltips: Bool = true
    @AppStorage("animationSpeed") private var animationSpeed: Double = 1.0
    @AppStorage("dataRetentionDays") private var dataRetentionDays: Int = 365
    @AppStorage("enableAnalytics") private var enableAnalytics: Bool = false
    @AppStorage("betaUpdates") private var betaUpdates: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Auto-save Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Management")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Toggle("Auto-save Profiles", isOn: self.$autoSaveProfiles)
                        .help("Automatically save profile changes")

                    HStack {
                        Text("Data Retention")
                        Spacer()
                        Text("\(self.dataRetentionDays) days")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(self.dataRetentionDays) },
                        set: { self.dataRetentionDays = Int($0) }
                    ), in: 30 ... 365, step: 1)
                        .help("Number of days to keep profile data")
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
                        .help("Display helpful tooltips throughout the app")

                    HStack {
                        Text("Animation Speed")
                        Spacer()
                        Text("\(self.animationSpeed, specifier: "%.1f")x")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: self.$animationSpeed, in: 0.5 ... 2.0, step: 0.1)
                        .help("Control the speed of UI animations")
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
                        .help("Help improve the app by sharing anonymous usage data")

                    Toggle("Beta Updates", isOn: self.$betaUpdates)
                        .help("Receive early access to new features and updates")
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
