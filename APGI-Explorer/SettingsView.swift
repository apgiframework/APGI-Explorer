import CoreData
import Foundation
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

struct SettingsView: View {
  @State private var selectedTab: SettingsTab = .general

  var body: some View {
    NavigationSplitView {
      // Sidebar
      List(selection: self.$selectedTab) {
        ForEach(SettingsTab.allCases, id: \.self) { tab in
          Label(tab.title, systemImage: tab.icon)
            .tag(tab)
        }
      }
      .navigationTitle("Settings")
      .frame(minWidth: 200)
    } detail: {
      // Detail view
      Group {
        switch self.selectedTab {
        case .general:
          GeneralSettingsView()
        case .appearance:
          AppearanceSettingsView()
        case .charts:
          ChartsSettingsView()
        case .privacy:
          DataPrivacySettingsView()
        case .notifications:
          NotificationsSettingsView()
        case .windowManagement:
          WindowManagementSettingsView()
        case .exportBackup:
          ExportBackupSettingsView()
        case .advanced:
          AdvancedSettingsView()
        case .psychologicalStates:
          PsychologicalStatesSettingsView()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(minWidth: 600, minHeight: 500)
  }
}

// MARK: - Settings Tab Enum

enum SettingsTab: CaseIterable {
  case general, appearance, charts, privacy, notifications, windowManagement,
    exportBackup, advanced, psychologicalStates

  var title: String {
    switch self {
    case .general: "General"
    case .appearance: "Appearance"
    case .charts: "Charts"
    case .privacy: "Privacy"
    case .notifications: "Notifications"
    case .windowManagement: "Window Management"
    case .exportBackup: "Export & Backup"
    case .advanced: "Advanced"
    case .psychologicalStates: "Psychological States"
    }
  }

  var icon: String {
    switch self {
    case .general: "gear"
    case .appearance: "paintbrush"
    case .charts: "chart.bar"
    case .privacy: "lock.shield"
    case .notifications: "bell"
    case .windowManagement: "rectangle.on.rectangle"
    case .exportBackup: "square.and.arrow.up"
    case .advanced: "wrench.and.screwdriver"
    case .psychologicalStates: "brain"
    }
  }
}

#Preview {
  SettingsView()
}

// MARK: - Missing Settings Views (Placeholders)

struct NotificationsSettingsView: View {
  @AppStorage("enableProfileUpdates") private var enableProfileUpdates = true
  @AppStorage("enableSystemAlerts") private var enableSystemAlerts = true

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("Notifications")
          .font(.largeTitle)
          .fontWeight(.bold)

        Form {
          Section(header: Text("Profile & Data")) {
            Toggle("Profile Updates", isOn: self.$enableProfileUpdates)
              .help("Get notified about profile changes and insights")
          }

          Section(header: Text("System")) {
            Toggle("System Alerts", isOn: self.$enableSystemAlerts)
              .help("Receive alerts for system events and errors")
          }

          Section {
            Text(
              "Notifications are managed by macOS System Settings. Enable notifications for APGI Explorer in System Settings > Notifications."
            )
            .font(.caption)
            .foregroundColor(.secondary)
          }
        }
      }
      .padding()
    }
    .navigationTitle("Notifications")
  }
}

struct WindowManagementSettingsView: View {
  @AppStorage("defaultWindowArrangement") private var defaultArrangement = "cascade"
  @AppStorage("rememberWindowPositions") private var rememberPositions = true
  @AppStorage("autoSaveWindowState") private var autoSaveState = true

  @Environment(\.showTooltips) private var tooltipsEnabled

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("Window Management")
          .font(.largeTitle)
          .fontWeight(.bold)

        Form {
          Section(header: Text("Arrangement")) {
            Picker("Default Arrangement", selection: self.$defaultArrangement) {
              Text("Cascade").tag("cascade")
              Text("Tile").tag("tile")
              Text("Side by Side").tag("sideBySide")
            }
            .pickerStyle(SegmentedPickerStyle())
            .conditionalHelp("Default arrangement for multiple windows", when: tooltipsEnabled)
          }

          Section(header: Text("Behavior")) {
            Toggle("Remember Window Positions", isOn: self.$rememberPositions)
              .conditionalHelp("Restore window positions on app launch", when: tooltipsEnabled)

            Toggle("Auto-Save Window State", isOn: self.$autoSaveState)
              .conditionalHelp("Automatically save window positions and sizes", when: tooltipsEnabled)
          }

          Section(header: Text("Window Types")) {
            Text("Main Window: 1000x700 minimum")
            Text("State Explorer: 1200x800 minimum")
            Text("Profile Comparison: 1000x700 minimum")
            Text("Settings: 600x500 minimum")
          }
        }
      }
      .padding()
    }
    .navigationTitle("Window Management")
  }
}

struct ExportBackupSettingsView: View {
  @AppStorage("exportFormat") private var defaultFormat: ExportFormat = .json
  @AppStorage("backupFrequency") private var backupFrequency = "weekly"
  @AppStorage("autoBackupEnabled") private var autoBackup = true
  @AppStorage("maxBackupFiles") private var maxBackupFiles: Int = 10

  @Environment(\.showTooltips) private var tooltipsEnabled

  @State private var maxBackupFilesString: String = "10"
  @StateObject private var validationManager = SettingsValidationManager()

  @State private var operationMessage = ""
  @State private var showOperationAlert = false
  @State private var isWorking = false

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("Export & Backup")
          .font(.largeTitle)
          .fontWeight(.bold)

        Form {
          Section(header: Text("Export Settings")) {
            Picker("Default Export Format", selection: self.$defaultFormat) {
              Text("JSON").tag(ExportFormat.json)
              Text("CSV").tag(ExportFormat.csv)
              Text("PDF").tag(ExportFormat.pdf)
              Text("PNG").tag(ExportFormat.png)
            }
            .pickerStyle(SegmentedPickerStyle())
            .help("Default format for data exports")
          }

          Section(header: Text("Backup Settings")) {
            Toggle("Enable Automatic Backups", isOn: self.$autoBackup)
              .conditionalHelp("Automatically backup data at scheduled intervals", when: tooltipsEnabled)

            if self.autoBackup {
              Picker("Backup Frequency", selection: self.$backupFrequency) {
                Text("Daily").tag("daily")
                Text("Weekly").tag("weekly")
                Text("Monthly").tag("monthly")
              }
              .pickerStyle(SegmentedPickerStyle())
              .conditionalHelp("How often to perform automatic backups", when: tooltipsEnabled)

              ValidatedTextField(
                title: "Max Backup Files",
                text: self.$maxBackupFilesString,
                validator: { text in
                  if let count = Int(text) {
                    return self.validationManager.validateMaxBackupFiles(count)
                  }
                  return ValidationError(field: "Max Backup Files", message: "Must be a valid integer", severity: .error)
                }
              )
              .conditionalHelp("Maximum number of automatic backups to keep before deleting older ones", when: tooltipsEnabled)
            }

            Button("Backup Now") {
              self.createBackupNow()
            }
            .disabled(self.isWorking)
            .conditionalHelp("Create a backup immediately", when: tooltipsEnabled)
          }

          Section(header: Text("Data Management")) {
            Button("Export All Profiles") {
              self.exportAllProfiles()
            }
            .disabled(self.isWorking)
            .conditionalHelp("Export all profile data", when: tooltipsEnabled)

            Button("Import Profiles") {
              self.importProfiles()
            }
            .disabled(self.isWorking)
            .conditionalHelp("Import profile data from file", when: tooltipsEnabled)
          }
        }
      }
      .padding()
    }
    .navigationTitle("Export & Backup")
    .onAppear {
      self.maxBackupFilesString = String(self.maxBackupFiles)
    }
    .onChange(of: self.maxBackupFilesString) { _, newValue in
      if let count = Int(newValue), self.validationManager.validateMaxBackupFiles(count) == nil {
        self.maxBackupFiles = count
      }
    }
    .onChange(of: self.backupFrequency) { _, newValue in
      if let frequency = BackupFrequency(rawValue: newValue) {
        UserDefaultsManager.shared.backupFrequency = frequency
      }
    }
    .alert("Export & Backup", isPresented: self.$showOperationAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(self.operationMessage)
    }
  }

  private func createBackupNow() {
    self.isWorking = true
    Task {
      do {
        let url = try await FileStorageManager.shared.createBackup()
        await MainActor.run {
          self.operationMessage = "Backup created successfully at:\n\(url.path)"
          self.showOperationAlert = true
          self.isWorking = false
        }
      } catch {
        await MainActor.run {
          self.operationMessage = "Failed to create backup: \(error.localizedDescription)"
          self.showOperationAlert = true
          self.isWorking = false
        }
      }
    }
  }

  private func exportAllProfiles() {
    self.createBackupNow()
  }

  private func importProfiles() {
    #if os(macOS)
      let panel = NSOpenPanel()
      panel.allowedContentTypes = [.json]
      panel.canChooseFiles = true
      panel.canChooseDirectories = false
      panel.allowsMultipleSelection = false
      panel.title = "Import Backup"
      panel.message = "Select a backup JSON file to restore."

      panel.begin { response in
        guard response == .OK, let url = panel.url else { return }
        self.isWorking = true
        Task {
          do {
            try await FileStorageManager.shared.restoreBackup(from: url)
            await MainActor.run {
              self.operationMessage = "Backup restored successfully."
              self.showOperationAlert = true
              self.isWorking = false
            }
          } catch {
            await MainActor.run {
              self.operationMessage = "Failed to import backup: \(error.localizedDescription)"
              self.showOperationAlert = true
              self.isWorking = false
            }
          }
        }
      }
    #else
      self.operationMessage = "Import is currently available on macOS only."
      self.showOperationAlert = true
    #endif
  }
}

struct PsychologicalStatesSettingsView: View {
  @AppStorage("autoRefreshStates") private var autoRefresh = false

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("Psychological States")
          .font(.largeTitle)
          .fontWeight(.bold)

        Form {
          Section(header: Text("Behavior")) {
            Toggle("Auto-Refresh States", isOn: self.$autoRefresh)
              .help("Automatically refresh state data periodically")
          }

          Section(header: Text("Performance")) {
            Text("States are displayed in grid mode for optimal browsing")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
      .padding()
    }
    .navigationTitle("Psychological States")
  }
}
