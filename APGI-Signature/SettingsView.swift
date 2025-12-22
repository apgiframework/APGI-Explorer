import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultChartStyle") private var defaultChartStyle: ChartStyle = .radar
    @AppStorage("autoSaveProfiles") private var autoSaveProfiles: Bool = true
    @AppStorage("showTooltips") private var showTooltips: Bool = true
    @AppStorage("animationSpeed") private var animationSpeed: Double = 1.0
    @AppStorage("dataRetentionDays") private var dataRetentionDays: Int = 365
    @AppStorage("exportQuality") private var exportQuality: ExportQuality = .high
    @AppStorage("enableAnalytics") private var enableAnalytics: Bool = false
    
    private enum ExportQuality: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case ultra = "Ultra"
    }
    
    var body: some View {
        TabView {
            // General Settings
            generalSettingsTab
            
            // Appearance Settings
            appearanceSettingsTab
            
            // Data & Privacy Settings
            dataPrivacySettingsTab
            
            // Export Settings
            exportSettingsTab
            
            // Advanced Settings
            advancedSettingsTab
        }
        .frame(width: 500, height: 400)
    }
    
    // MARK: - General Settings Tab
    private var generalSettingsTab: some View {
        Form {
            Section(header: Text("Behavior")) {
                Toggle("Auto-save profiles", isOn: $autoSaveProfiles)
                Toggle("Show tooltips", isOn: $showTooltips)
            }
            
            Section(header: Text("Quizzes")) {
                HStack {
                    Text("Default animation speed")
                    Spacer()
                    Slider(value: $animationSpeed, in: 0.5...2.0, step: 0.1)
                    Text("\(animationSpeed, specifier: "%.1f")x")
                        .frame(width: 40)
                }
            }
            
            Section(header: Text("Notifications")) {
                Button("Reset Notification Preferences") {
                    resetNotificationPreferences()
                }
            }
        }
        .tabItem {
            Label("General", systemImage: "gear")
        }
    }
    
    // MARK: - Appearance Settings Tab
    private var appearanceSettingsTab: some View {
        Form {
            Section(header: Text("Charts")) {
                Picker("Default chart style", selection: $defaultChartStyle) {
                    ForEach(ChartStyle.allCases, id: \.self) { style in
                        Text(styleName(for: style)).tag(style)
                    }
                }
            }
            
            Section(header: Text("Colors")) {
                Button("Reset Color Scheme") {
                    resetColorScheme()
                }
            }
            
            Section(header: Text("Layout")) {
                Button("Reset Window Layouts") {
                    resetWindowLayouts()
                }
            }
        }
        .tabItem {
            Label("Appearance", systemImage: "paintbrush")
        }
    }
    
    // MARK: - Data & Privacy Settings Tab
    private var dataPrivacySettingsTab: some View {
        Form {
            Section(header: Text("Data Management")) {
                HStack {
                    Text("Data retention period")
                    Spacer()
                    Picker("Days", selection: $dataRetentionDays) {
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                        Text("180 days").tag(180)
                        Text("365 days").tag(365)
                        Text("Never").tag(Int.max)
                    }
                    .frame(width: 100)
                }
                
                Button("Clear All Data") {
                    clearAllData()
                }
                .foregroundColor(.red)
            }
            
            Section(header: Text("Privacy")) {
                Toggle("Enable analytics", isOn: $enableAnalytics)
                Button("Export Privacy Report") {
                    exportPrivacyReport()
                }
            }
            
            Section(header: Text("Backup")) {
                Button("Create Backup") {
                    createBackup()
                }
                Button("Restore from Backup") {
                    restoreFromBackup()
                }
            }
        }
        .tabItem {
            Label("Data & Privacy", systemImage: "lock.shield")
        }
    }
    
    // MARK: - Export Settings Tab
    private var exportSettingsTab: some View {
        Form {
            Section(header: Text("Quality")) {
                Picker("Default export quality", selection: $exportQuality) {
                    ForEach(ExportQuality.allCases, id: \.self) { quality in
                        Text(quality.rawValue).tag(quality)
                    }
                }
            }
            
            Section(header: Text("Formats")) {
                Toggle("Include metadata in exports", isOn: .constant(true))
                Toggle("Compress PDF exports", isOn: .constant(false))
            }
            
            Section(header: Text("Location")) {
                Button("Change Export Location") {
                    changeExportLocation()
                }
                Button("Reset to Default") {
                    resetExportLocation()
                }
            }
        }
        .tabItem {
            Label("Export", systemImage: "square.and.arrow.up")
        }
    }
    
    // MARK: - Advanced Settings Tab
    private var advancedSettingsTab: some View {
        Form {
            Section(header: Text("Debug")) {
                Toggle("Enable debug mode", isOn: .constant(false))
                Toggle("Show performance metrics", isOn: .constant(false))
            }
            
            Section(header: Text("Experimental")) {
                Toggle("Enable experimental features", isOn: .constant(false))
                Button("Reset All Settings") {
                    resetAllSettings()
                }
                .foregroundColor(.red)
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("2024.12.22")
                        .foregroundColor(.secondary)
                }
                
                Button("View License") {
                    viewLicense()
                }
            }
        }
        .tabItem {
            Label("Advanced", systemImage: "gearshape.2")
        }
    }
    
    // MARK: - Helper Methods
    private func styleName(for style: ChartStyle) -> String {
        switch style {
        case .radar: return "Radar"
        case .bar: return "Bar"
        case .line: return "Line"
        }
    }
    
    private func resetNotificationPreferences() {
        print("Resetting notification preferences...")
    }
    
    private func resetColorScheme() {
        print("Resetting color scheme...")
    }
    
    private func resetWindowLayouts() {
        print("Resetting window layouts...")
    }
    
    private func clearAllData() {
        print("Clearing all data...")
    }
    
    private func exportPrivacyReport() {
        print("Exporting privacy report...")
    }
    
    private func createBackup() {
        print("Creating backup...")
    }
    
    private func restoreFromBackup() {
        print("Restoring from backup...")
    }
    
    private func changeExportLocation() {
        print("Changing export location...")
    }
    
    private func resetExportLocation() {
        print("Resetting export location...")
    }
    
    private func resetAllSettings() {
        print("Resetting all settings...")
    }
    
    private func viewLicense() {
        print("Viewing license...")
    }
}
