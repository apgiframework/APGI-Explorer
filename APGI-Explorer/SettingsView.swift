import SwiftUI
import Foundation
import CoreData
import UniformTypeIdentifiers

struct SettingsView: View {
    // AppStorage bindings for all settings
    @AppStorage("preferredChartStyle") private var defaultChartStyle: ChartStyle = .radar
    @AppStorage("autoSaveProfiles") private var autoSaveProfiles: Bool = true
    @AppStorage("showTooltips") private var showTooltips: Bool = true
    @AppStorage("animationSpeed") private var animationSpeed: Double = 1.0
    @AppStorage("dataRetentionDays") private var dataRetentionDays: Int = 365
    @AppStorage("exportQuality") private var exportQuality: ExportQuality = .high
    @AppStorage("enableAnalytics") private var enableAnalytics: Bool = false
    
    // Theme manager integration
    @StateObject private var themeManager = ThemeManager.shared
    
    // Additional app settings from UserDefaultsManager
    @AppStorage("showConfidenceIndicators") private var showConfidenceIndicators: Bool = true
    @AppStorage("quizReminderEnabled") private var quizReminderEnabled: Bool = false
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("defaultProfileName") private var defaultProfileName: String = "My Profile"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // Additional settings
    @AppStorage("autoBackupEnabled") private var autoBackupEnabled: Bool = true
    @AppStorage("backupFrequency") private var backupFrequency: BackupFrequency = .weekly
    @AppStorage("maxBackupFiles") private var maxBackupFiles: Int = 10
    @AppStorage("windowArrangementPreference") private var windowArrangementPreference: WindowArrangement = .cascade
    @AppStorage("showWelcomeScreen") private var showWelcomeScreen: Bool = true
    @AppStorage("crashReportingEnabled") private var crashReportingEnabled: Bool = true
    @AppStorage("debugModeEnabled") private var debugModeEnabled: Bool = false
    @AppStorage("exportFormat") private var exportFormat: ExportFormat = .json
    @AppStorage("includeMetadataInExports") private var includeMetadataInExports: Bool = true
    @AppStorage("autoRefreshData") private var autoRefreshData: Bool = true
    @AppStorage("refreshInterval") private var refreshInterval: Double = 300.0 // 5 minutes
    @AppStorage("showAdvancedOptions") private var showAdvancedOptions: Bool = false
    @AppStorage("compactModeEnabled") private var compactModeEnabled: Bool = false
    @AppStorage("sidebarWidth") private var sidebarWidth: Double = 250.0
    @AppStorage("showGridLines") private var showGridLines: Bool = true
    @AppStorage("chartAnimationEnabled") private var chartAnimationEnabled: Bool = true
    @AppStorage("notificationSoundEnabled") private var notificationSoundEnabled: Bool = true
    @AppStorage("notificationBadgeEnabled") private var notificationBadgeEnabled: Bool = true
    
    // Additional settings for Psychological States view
    @AppStorage("statesDisplayMode") private var statesDisplayMode: DisplayMode = .list
    @AppStorage("showParameterSummary") private var showParameterSummary: Bool = true
    @AppStorage("statesAutoRefresh") private var statesAutoRefresh: Bool = false
    @AppStorage("statesRefreshInterval") private var statesRefreshInterval: Double = 60.0 // 1 minute
    
    // Profile Comparison settings
    @AppStorage("defaultComparisonMode") private var defaultComparisonMode: ComparisonMode = .radar
    @AppStorage("showComparisonSimilarity") private var showComparisonSimilarity: Bool = true
    @AppStorage("comparisonAnimationEnabled") private var comparisonAnimationEnabled: Bool = true
    
    @State private var showingResetAlert = false
    @State private var showingClearDataAlert = false
    @State private var showingOnboardingView = false
    @State private var selectedTab: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    private enum ExportQuality: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case ultra = "Ultra"
    }
    
    // Use enums from UserDefaultsManager instead of duplicating them
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            // Tab content with sidebar layout
            HSplitView {
                // Sidebar with navigation
                VStack(alignment: .leading, spacing: 0) {
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    
                    List(selection: $selectedTab) {
                        Section("Basic") {
                            Label("General", systemImage: "gear")
                                .tag(0)
                            Label("Appearance", systemImage: "paintpalette")
                                .tag(1)
                            Label("Charts", systemImage: "chart.bar")
                                .tag(2)
                        }
                        
                        Section("Data & Privacy") {
                            Label("Privacy", systemImage: "hand.raised")
                                .tag(3)
                            Label("Backup", systemImage: "arrow.down.doc")
                                .tag(4)
                        }
                        
                        Section("Advanced") {
                            Label("Notifications", systemImage: "bell")
                                .tag(5)
                            Label("Windows", systemImage: "square.3.layers.3d")
                                .tag(6)
                            Label("States", systemImage: "brain.head.profile")
                                .tag(7)
                            Label("Advanced", systemImage: "gearshape.2")
                                .tag(8)
                            Label("Comparison", systemImage: "chart.bar.doc.horizontal")
                                .tag(9)
                        }
                    }
                    .listStyle(SidebarListStyle())
                }
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
                
                // Content area
                Group {
                    switch selectedTab {
                    case 0:
                        generalSettingsTab
                    case 1:
                        appearanceSettingsTab
                    case 2:
                        chartsSettingsTab
                    case 3:
                        dataPrivacySettingsTab
                    case 4:
                        exportBackupSettingsTab
                    case 5:
                        notificationsSettingsTab
                    case 6:
                        windowSettingsTab
                    case 7:
                        psychologicalStatesSettingsTab
                    case 8:
                        advancedSettingsTab
                    case 9:
                        profileComparisonSettingsTab
                    default:
                        generalSettingsTab
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingOnboardingView) {
            OnboardingView()
        }
        .alert("Reset All Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text("This will restore all settings to their default values. This action cannot be undone.")
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all profiles, quiz results, and app data. This action cannot be undone.")
        }
    }
    
    // MARK: - General Settings Tab
    private var generalSettingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Onboarding Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Onboarding")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button("Show Onboarding Again") {
                            showingOnboardingView = true
                        }
                        .help("Review the app introduction and features")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Behavior Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Behavior")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Toggle("Auto-save profiles", isOn: $autoSaveProfiles)
                            .help("Automatically save changes to profiles")
                            .padding(.vertical, 4)
                        
                        Toggle("Show tooltips", isOn: $showTooltips)
                            .help("Display helpful tooltips throughout the app")
                            .padding(.vertical, 4)
                        
                        Toggle("Show confidence indicators", isOn: $showConfidenceIndicators)
                            .help("Show confidence levels in quiz results")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Quizzes Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quizzes")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        HStack {
                            Text("Default animation speed")
                            Spacer()
                            Slider(value: $animationSpeed, in: 0.5...2.0, step: 0.1)
                                .frame(width: 200)
                            Text("\(animationSpeed, specifier: "%.1f")x")
                                .frame(width: 40, alignment: .trailing)
                        }
                        .help("Control the speed of quiz animations")
                        .padding(.vertical, 4)
                        
                        Toggle("Quiz reminders", isOn: $quizReminderEnabled)
                            .help("Receive notifications to take periodic quizzes")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Profile Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Profile Settings")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        HStack {
                            Text("Default profile name")
                            Spacer()
                            TextField("My Profile", text: $defaultProfileName)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        .help("Default name for new profiles")
                        .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Notifications Settings Tab
    private var notificationsSettingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quiz Notifications Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quiz Notifications")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Toggle("Quiz reminders", isOn: $quizReminderEnabled)
                            .help("Receive notifications to take periodic quizzes")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Notification Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notification Settings")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Toggle("Notification sounds", isOn: $notificationSoundEnabled)
                            .help("Play sounds for notifications")
                            .padding(.vertical, 4)
                        
                        Toggle("Notification badges", isOn: $notificationBadgeEnabled)
                            .help("Show badge notifications on app icon")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // System Notifications Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Notifications")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button("Reset Notification Preferences") {
                            resetNotificationPreferences()
                        }
                        .help("Reset all notification settings to default")
                        
                        Button("Open System Notification Settings") {
                            #if os(macOS)
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
                            #endif
                        }
                        .help("Open system notification preferences")
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tabItem {
            Label("Notifications", systemImage: "bell")
        }
    }
    
    // MARK: - Appearance Settings Tab
    private var appearanceSettingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Theme Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Theme")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Picker("App theme", selection: $themeManager.currentTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(themeName(for: theme)).tag(theme)
                            }
                        }
                        .pickerStyle(RadioGroupPickerStyle())
                        .padding(.vertical, 8)
                        .onChange(of: themeManager.currentTheme) {
                            // Theme change is handled automatically by ThemeManager
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Accessibility Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Accessibility")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Toggle("Sound effects", isOn: $soundEffectsEnabled)
                            .help("Enable sound effects throughout the app")
                            .padding(.vertical, 4)
                        
                        Toggle("Haptic feedback", isOn: $hapticsEnabled)
                            .help("Enable haptic feedback on supported devices")
                            .padding(.vertical, 4)
                        
                        HStack {
                            Text("Background Color")
                            Spacer()
                            ColorPicker("", selection: .constant(Color(.windowBackgroundColor)))
                        }
                        .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tabItem {
            Label("Appearance", systemImage: "paintpalette")
        }
    }
    
    // MARK: - Charts Settings Tab
    private var chartsSettingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Chart Display Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chart Display")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Picker("Default chart style", selection: $defaultChartStyle) {
                            ForEach(ChartStyle.allCases, id: \.self) { style in
                                Text(styleName(for: style)).tag(style)
                            }
                        }
                        .help("Default chart type for new visualizations")
                        .padding(.vertical, 4)
                        
                        Toggle("Show grid lines", isOn: $showGridLines)
                            .help("Display grid lines on charts")
                            .padding(.vertical, 4)
                        
                        Toggle("Chart animations", isOn: $chartAnimationEnabled)
                            .help("Enable animations for chart transitions")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Chart Interaction Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Interaction")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Toggle("Show data points", isOn: .constant(true))
                            .help("Show individual data points on line and radar charts")
                            .padding(.vertical, 4)
                        
                        Toggle("Show values on bars", isOn: .constant(true))
                            .help("Display values on top of bar chart elements")
                            .padding(.vertical, 4)
                        
                        Toggle("Allow zooming", isOn: .constant(true))
                            .help("Allow zooming in on charts")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tabItem {
            Label("Charts", systemImage: "chart.bar")
        }
    }
    
    // MARK: - Data & Privacy Settings Tab
    private var dataPrivacySettingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Data Management Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Management")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        HStack {
                            Text("Data retention")
                            Spacer()
                            Picker("Days", selection: $dataRetentionDays) {
                                Text("30 days").tag(30)
                                Text("90 days").tag(90)
                                Text("180 days").tag(180)
                                Text("365 days").tag(365)
                                Text("Forever").tag(9999)
                            }
                            .frame(width: 120)
                        }
                        .help("How long to keep quiz and profile data")
                        .padding(.vertical, 4)
                        
                        Toggle("Enable analytics", isOn: $enableAnalytics)
                            .help("Help improve the app by sharing anonymous usage data")
                            .padding(.vertical, 4)
                        
                        Toggle("Crash reporting", isOn: $crashReportingEnabled)
                            .help("Automatically send crash reports to help fix bugs")
                            .padding(.vertical, 4)
                        
                        Toggle("Auto-refresh data", isOn: $autoRefreshData)
                            .help("Automatically refresh data throughout the app")
                            .padding(.vertical, 4)
                        
                        if autoRefreshData {
                            HStack {
                                Text("Refresh interval")
                                Spacer()
                                Picker("Minutes", selection: $refreshInterval) {
                                    Text("1 min").tag(60.0)
                                    Text("5 min").tag(300.0)
                                    Text("10 min").tag(600.0)
                                    Text("30 min").tag(1800.0)
                                    Text("1 hour").tag(3600.0)
                                }
                                .frame(width: 120)
                            }
                            .help("How often to refresh data throughout the app")
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Privacy Actions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Button("Export My Data") {
                                Task {
                                    let _ = try? await ProfileManager().exportAllProfiles()
                                }
                            }
                            .help("Download a copy of all your data")
                            
                            Spacer()
                        }
                        
                        HStack {
                            Button("Request Data Deletion") {
                                // Start data deletion process
                            }
                            .foregroundColor(.red)
                            .help("Request permanent deletion of all your data")
                            
                            Spacer()
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        HStack {
                            Button("Clear All Data") {
                                showingClearDataAlert = true
                            }
                            .foregroundColor(.red)
                            .help("Permanently delete all app data")
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tabItem {
            Label("Privacy", systemImage: "hand.raised")
        }
    }
    
    // MARK: - Window Management Settings Tab
    private var windowSettingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Window Behavior Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Window Behavior")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Toggle("Show welcome screen", isOn: $showWelcomeScreen)
                            .help("Show welcome screen on app launch")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Window Arrangement Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Window Arrangement")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Picker("Default arrangement", selection: $windowArrangementPreference) {
                            ForEach(WindowArrangement.allCases, id: \.self) { arrangement in
                                Text(arrangement.rawValue).tag(arrangement)
                            }
                        }
                        .help("Default window arrangement when opening multiple windows")
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Sidebar width")
                            Spacer()
                            Slider(value: $sidebarWidth, in: 150...400, step: 10)
                            Text("\(Int(sidebarWidth))px")
                                .frame(width: 50)
                        }
                        .help("Default width for the sidebar in pixels")
                        .padding(.vertical, 4)
                        
                        Button("Reset Window Layouts") {
                            resetWindowLayouts()
                        }
                        .help("Reset window positions and sizes to defaults")
                        .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Window Actions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Window Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button("Arrange Windows in Cascade") {
                            #if os(macOS)
                            WindowManager.shared.arrangeWindowsWithUserPreference()
                            #endif
                        }
                        .help("Arrange all windows using your preferred layout")
                        
                        Button("Tile Windows") {
                            #if os(macOS)
                            WindowManager.shared.arrangeWindows(.tile)
                            #endif
                        }
                        .help("Arrange all windows in a grid pattern")
                        
                        Button("Arrange Side by Side") {
                            #if os(macOS)
                            WindowManager.shared.arrangeWindows(.sideBySide)
                            #endif
                        }
                        .help("Arrange windows side by side")
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tabItem {
            Label("Windows", systemImage: "square.3.layers.3d")
        }
    }
    
    // MARK: - Export & Backup Settings Tab
    private var exportBackupSettingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Backup Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Backup Settings")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        // Backup Controls Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Backups")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 12) {
                                Toggle("Automatic", isOn: $autoBackupEnabled)
                                    .help("Enable automatic backups of your data")
                                
                                if autoBackupEnabled {
                                    HStack {
                                        Text("Backup Frequency")
                                        Spacer()
                                        Picker("", selection: $backupFrequency) {
                                            ForEach(BackupFrequency.allCases, id: \.self) { frequency in
                                                Text(frequency.rawValue).tag(frequency)
                                            }
                                        }
                                        .frame(width: 120)
                                    }
                                    
                                    HStack {
                                        Text("Max Backups")
                                        Spacer()
                                        Picker("", selection: $maxBackupFiles) {
                                            Text("5").tag(5)
                                            Text("10").tag(10)
                                            Text("20").tag(20)
                                            Text("50").tag(50)
                                            Text("Unlimited").tag(1000)
                                        }
                                        .frame(width: 120)
                                    }
                                }
                                
                                HStack {
                                    Button("Create Backup Now") {
                                        Task {
                                            let _ = try? await FileStorageManager.shared.createBackup()
                                        }
                                    }
                                    .help("Manually create a backup now")
                                    
                                    Spacer()
                                    
                                    Button("Restore Backup...") {
                                        // Show file picker for backup restoration
                                    }
                                    .help("Restore from a previous backup")
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
                
                // Export Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Data")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Picker("Export Format", selection: $exportFormat) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Text(format.rawValue.uppercased()).tag(format)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Toggle("Include Metadata", isOn: $includeMetadataInExports)
                            .help("Include additional metadata in exports")
                            .padding(.vertical, 4)
                        
                        Picker("Export Quality", selection: $exportQuality) {
                            ForEach(ExportQuality.allCases, id: \.self) { quality in
                                Text(quality.rawValue).tag(quality)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Button("Export All Data...") {
                            Task {
                                let _ = try? await ProfileManager().exportAllProfiles()
                            }
                        }
                        .help("Export all profiles and data to a file")
                        .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tabItem {
            Label("Backup", systemImage: "arrow.down.doc")
        }
    }
    
    // MARK: - Psychological States Settings Tab
    private var psychologicalStatesSettingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Display Options Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Display Options")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Picker("Default display mode", selection: $statesDisplayMode) {
                            ForEach(DisplayMode.allCases) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .help("Choose how psychological states are displayed by default")
                        .padding(.vertical, 4)
                        
                        Toggle("Show parameter summary", isOn: $showParameterSummary)
                            .help("Display summary information for psychological parameters")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Data Refresh Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Refresh")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Toggle("Auto-refresh states", isOn: $statesAutoRefresh)
                            .help("Automatically refresh psychological states data")
                            .padding(.vertical, 4)
                        
                        if statesAutoRefresh {
                            HStack {
                                Text("Refresh interval")
                                Spacer()
                                Slider(value: $statesRefreshInterval, in: 30...300, step: 30)
                                Text("\(Int(statesRefreshInterval))s")
                                    .frame(width: 40)
                            }
                            .help("How often to refresh the states data (in seconds)")
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Search & Performance Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Search & Performance")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Toggle("Enable live search", isOn: .constant(true))
                            .help("Search results update as you type")
                            .padding(.vertical, 4)
                        
                        Toggle("Show search hints", isOn: .constant(true))
                            .help("Display helpful hints for searching states")
                            .padding(.vertical, 4)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Toggle("Lazy loading", isOn: .constant(true))
                            .help("Load states data progressively for better performance")
                            .padding(.vertical, 4)
                        
                        Toggle("Cache search results", isOn: .constant(true))
                            .help("Cache search results for faster repeated searches")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tabItem {
            Label("States", systemImage: "brain.head.profile")
        }
    }
    
    // MARK: - Advanced Settings Tab
    private var advancedSettingsTab: some View {
        ScrollView {
            Form {
            Section(header: Text("Debug")) {
                Toggle("Enable debug mode", isOn: $debugModeEnabled)
                    .help("Show additional debugging information")
                Toggle("Show performance metrics", isOn: .constant(false))
                    .help("Display performance statistics")
            }
            
            Section(header: Text("Interface")) {
                Toggle("Show advanced options", isOn: $showAdvancedOptions)
                    .help("Display advanced options throughout the app")
                Toggle("Compact mode", isOn: $compactModeEnabled)
                    .help("Use a more compact interface layout")
            }
            
            Section(header: Text("Experimental")) {
                Toggle("Enable experimental features", isOn: .constant(false))
                    .help("Try out new features in development")
                Toggle("Beta updates", isOn: .constant(false))
                    .help("Receive beta versions of the app")
            }
            
            Section(header: Text("Reset Options")) {
                Button("Reset All Settings") {
                    showingResetAlert = true
                }
                .foregroundColor(.orange)
                .help("Restore all settings to their default values")
                
                Button("Clear Cache") {
                    clearCache()
                }
                .help("Clear temporary files and cache")
                
                Button("Reset Window Layouts") {
                    resetWindowLayouts()
                }
                .help("Reset window positions and sizes")
            }
            
            Section(header: Text("System")) {
                Button("Open Application Support Folder") {
                    #if os(macOS)
                    if let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                        let appSupportURL = supportURL.appendingPathComponent(Bundle.main.bundleIdentifier ?? "APGI-Explorer")
                        NSWorkspace.shared.open(appSupportURL)
                    }
                    #endif
                }
                .help("Open the app's support folder")
                
                Button("View System Information") {
                    // Show system info dialog
                }
                .help("Display system and app information")
            }
        }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tabItem {
            Label("Advanced", systemImage: "gearshape.2")
        }
    }
    
    // MARK: - Profile Comparison Settings Tab
    private var profileComparisonSettingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Comparison Display Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comparison Display")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Picker("Default comparison mode", selection: $defaultComparisonMode) {
                            ForEach(ComparisonMode.allCases) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .help("Default chart type for profile comparisons")
                        .padding(.vertical, 4)
                        
                        Toggle("Show similarity score", isOn: $showComparisonSimilarity)
                            .help("Display similarity percentage between profiles")
                            .padding(.vertical, 4)
                        
                        Toggle("Comparison animations", isOn: $comparisonAnimationEnabled)
                            .help("Enable animations for comparison transitions")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Comparison Options Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comparison Options")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Form {
                        Toggle("Show differences only", isOn: .constant(false))
                            .help("Highlight only the differences between profiles")
                            .padding(.vertical, 4)
                        
                        Toggle("Normalize values", isOn: .constant(true))
                            .help("Normalize values for better comparison")
                            .padding(.vertical, 4)
                        
                        Toggle("Show average profile", isOn: .constant(false))
                            .help("Display average profile in comparisons")
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Export Comparison Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Comparison")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button("Export Current Comparison") {
                            // Export current comparison
                        }
                        .help("Export the current profile comparison")
                        
                        Button("Save Comparison Template") {
                            // Save comparison template
                        }
                        .help("Save current comparison settings as template")
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tabItem {
            Label("Comparison", systemImage: "chart.bar.doc.horizontal")
        }
    }
    
    // MARK: - Helper Methods
    private func styleName(for style: ChartStyle) -> String {
        switch style {
        case .radar: return "Radar"
        case .bar: return "Bar"
        case .line: return "Line"
        case .area: return "Area"
        }
    }
    
    private func formatName(for format: ExportFormat) -> String {
        switch format {
        case .json: return "JSON"
        case .csv: return "CSV"
        case .pdf: return "PDF"
        case .png: return "PNG"
        }
    }
    
    private func themeName(for theme: AppTheme) -> String {
        switch theme {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
    
    private func getBuildNumber() -> String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "Unknown"
    }
    
    private func clearCache() {
        // Clear temporary files and cache
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
    
    private func resetNotificationPreferences() {
        UserDefaults.standard.removeObject(forKey: "quizReminderEnabled")
        UserDefaults.standard.synchronize()
        quizReminderEnabled = false
    }
    
    private func resetColorScheme() {
        themeManager.setTheme(.system)
    }
    
    private func resetWindowLayouts() {
        UserDefaults.standard.removeObject(forKey: "windowFrame")
        UserDefaults.standard.removeObject(forKey: "windowState")
        UserDefaults.standard.synchronize()
    }
    
    private func clearAllData() {
        // Clear Core Data
        let context = PersistenceController.shared.container.viewContext
        let entities = ["ProfileEntity", "QuizSession"]
        
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print("Failed to clear \(entity): \(error)")
            }
        }
        
        // Reset UserDefaults
        UserDefaultsManager.shared.resetToDefaults()
    }
    
    private func resetAllSettings() {
        UserDefaultsManager.shared.resetToDefaults()
        
        // Reset AppStorage values to defaults
        defaultChartStyle = .radar
        autoSaveProfiles = true
        showTooltips = true
        animationSpeed = 1.0
        dataRetentionDays = 365
        exportQuality = .high
        enableAnalytics = false
        themeManager.setTheme(.system)
        showConfidenceIndicators = true
        quizReminderEnabled = false
        soundEffectsEnabled = true
        hapticsEnabled = true
        defaultProfileName = "My Profile"
        
        // Reset new psychological states settings
        statesDisplayMode = .list
        showParameterSummary = true
        statesAutoRefresh = false
        statesRefreshInterval = 60.0
        
        // Reset new comparison settings
        defaultComparisonMode = .radar
        showComparisonSimilarity = true
        comparisonAnimationEnabled = true
        
        // Reset additional settings
        autoBackupEnabled = true
        backupFrequency = .weekly
        maxBackupFiles = 10
        windowArrangementPreference = .cascade
        showWelcomeScreen = true
        crashReportingEnabled = true
        debugModeEnabled = false
        exportFormat = .json
        includeMetadataInExports = true
        autoRefreshData = true
        refreshInterval = 300.0
        showAdvancedOptions = false
        compactModeEnabled = false
        sidebarWidth = 250.0
        showGridLines = true
        chartAnimationEnabled = true
        notificationSoundEnabled = true
        notificationBadgeEnabled = true
    }
    
    private func viewLicense() {
        if let licenseURL = Bundle.main.url(forResource: "LICENSE", withExtension: "txt") {
            NSWorkspace.shared.open(licenseURL)
        } else {
            // Open default license or show in-app
            print("No license file found")
        }
    }
    
    private func showDataDirectory() {
        if let dataDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appDataDir = dataDir.appendingPathComponent(Bundle.main.bundleIdentifier ?? "APGI-Explorer")
            NSWorkspace.shared.open(appDataDir)
        }
    }
    
    private func sendFeedback() {
        let feedbackURL = URL(string: "mailto:support@apgi-explorer.com?subject=APGI%20Explorer%20Feedback")
        if let url = feedbackURL {
            NSWorkspace.shared.open(url)
        }
    }
}
