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
        case .cloudSync:
          CloudSyncSettingsView()
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
  case general, appearance, charts, privacy, cloudSync, notifications, windowManagement,
    exportBackup, advanced, psychologicalStates

  var title: String {
    switch self {
    case .general: "General"
    case .appearance: "Appearance"
    case .charts: "Charts"
    case .privacy: "Privacy"
    case .cloudSync: "Cloud Sync"
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
    case .cloudSync: "icloud"
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
  @AppStorage("quizReminderEnabled") private var enableQuizReminders = true
  @AppStorage("enableProfileUpdates") private var enableProfileUpdates = true
  @AppStorage("enableSystemAlerts") private var enableSystemAlerts = true

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("Notifications")
          .font(.largeTitle)
          .fontWeight(.bold)

        Form {
          Section(header: Text("Quiz & Assessment")) {
            Toggle("Quiz Reminders", isOn: self.$enableQuizReminders)
              .help("Receive reminders to complete assessments")
          }

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
            .help("Default arrangement for multiple windows")
          }

          Section(header: Text("Behavior")) {
            Toggle("Remember Window Positions", isOn: self.$rememberPositions)
              .help("Restore window positions on app launch")

            Toggle("Auto-Save Window State", isOn: self.$autoSaveState)
              .help("Automatically save window positions and sizes")
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
  @AppStorage("defaultExportFormat") private var defaultFormat = "json"
  @AppStorage("backupFrequency") private var backupFrequency = "weekly"
  @AppStorage("autoBackupEnabled") private var autoBackup = true

  @State private var showingBackupSuccess = false
  @State private var showingBackupError = false
  @State private var showingExportSuccess = false
  @State private var showingExportError = false
  @State private var showingImportPanel = false
  @State private var lastBackupURL: URL?
  @State private var lastExportURL: URL?
  @State private var errorMessage: String = ""

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("Export & Backup")
          .font(.largeTitle)
          .fontWeight(.bold)

        Form {
          Section(header: Text("Export Settings")) {
            Picker("Default Export Format", selection: self.$defaultFormat) {
              Text("JSON").tag("json")
              Text("CSV").tag("csv")
              Text("PDF").tag("pdf")
              Text("PNG").tag("png")
            }
            .pickerStyle(SegmentedPickerStyle())
            .help("Default format for data exports")
          }

          Section(header: Text("Backup Settings")) {
            Toggle("Enable Automatic Backups", isOn: self.$autoBackup)
              .help("Automatically backup data at scheduled intervals")

            if self.autoBackup {
              Picker("Backup Frequency", selection: self.$backupFrequency) {
                Text("Daily").tag("daily")
                Text("Weekly").tag("weekly")
                Text("Monthly").tag("monthly")
              }
              .pickerStyle(SegmentedPickerStyle())
              .help("How often to perform automatic backups")
            }

            Button("Backup Now") {
              performManualBackup()
            }
            .help("Create a backup immediately")
          }

          Section(header: Text("Data Management")) {
            Button("Export All Profiles") {
              performExportAllProfiles()
            }
            .help("Export all profile data")

            Button("Import Profiles") {
              showingImportPanel = true
            }
            .help("Import profile data from file")
          }
        }
      }
      .padding()
    }
    .navigationTitle("Export & Backup")
    .alert("Backup Successful", isPresented: $showingBackupSuccess) {
      Button("OK") {}
      Button("Show in Finder") {
        if let url = lastBackupURL {
          NSWorkspace.shared.activateFileViewerSelecting([url])
        }
      }
    } message: {
      Text("Your backup has been created successfully.")
    }
    .alert("Backup Failed", isPresented: $showingBackupError) {
      Button("OK") {}
    } message: {
      Text(errorMessage.isEmpty ? "Failed to create backup. Please try again." : errorMessage)
    }
    .alert("Export Successful", isPresented: $showingExportSuccess) {
      Button("OK") {}
      Button("Show in Finder") {
        if let url = lastExportURL {
          NSWorkspace.shared.activateFileViewerSelecting([url])
        }
      }
    } message: {
      Text("All profiles have been exported successfully.")
    }
    .alert("Export Failed", isPresented: $showingExportError) {
      Button("OK") {}
    } message: {
      Text(errorMessage.isEmpty ? "Failed to export profiles. Please try again." : errorMessage)
    }
    .sheet(isPresented: $showingImportPanel) {
      ImportProfileSheet()
    }
  }

  private func performManualBackup() {
    Task {
      do {
        let backupURL = try await FileStorageManager.shared.createBackup()
        await MainActor.run {
          lastBackupURL = backupURL
          showingBackupSuccess = true
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          showingBackupError = true
        }
      }
    }
  }

  private func performExportAllProfiles() {
    Task {
      do {
        let exportURL = try await FileStorageManager.shared.createBackup()
        await MainActor.run {
          lastExportURL = exportURL
          showingExportSuccess = true
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          showingExportError = true
        }
      }
    }
  }
}

// MARK: - Import Profile Sheet

struct ImportProfileSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State private var importURL: URL?
  @State private var showingFilePicker = false
  @State private var importSuccess = false
  @State private var importError = false
  @State private var errorMessage = ""

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Image(systemName: "arrow.down.doc")
          .font(.system(size: 60))
          .foregroundColor(.accentColor)

        Text("Import Profile")
          .font(.title)
          .fontWeight(.bold)

        Text("Select a JSON backup file to import profiles into APGI Explorer.")
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal)

        if let url = importURL {
          VStack(alignment: .leading, spacing: 8) {
            Text("Selected file:")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(url.lastPathComponent)
              .font(.subheadline)
              .fontWeight(.medium)
          }
          .padding()
          .background(Color.secondary.opacity(0.1))
          .cornerRadius(8)
        }

        Button(importURL == nil ? "Choose File..." : "Import") {
          if importURL == nil {
            showingFilePicker = true
          } else {
            performImport()
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(importURL == nil)

        Spacer()
      }
      .padding()
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
    .frame(minWidth: 400, minHeight: 300)
    .fileImporter(
      isPresented: $showingFilePicker,
      allowedContentTypes: [.json],
      allowsMultipleSelection: false
    ) { result in
      switch result {
      case .success(let urls):
        if let url = urls.first {
          importURL = url
        }
      case .failure(let error):
        errorMessage = error.localizedDescription
        importError = true
      }
    }
    .alert("Import Successful", isPresented: $importSuccess) {
      Button("OK") {
        dismiss()
      }
    } message: {
      Text("Profile(s) imported successfully.")
    }
    .alert("Import Failed", isPresented: $importError) {
      Button("OK") {}
    } message: {
      Text(
        errorMessage.isEmpty
          ? "Failed to import profile. Please check the file and try again." : errorMessage)
    }
  }

  private func performImport() {
    guard let url = importURL else { return }

    Task {
      do {
        try await FileStorageManager.shared.restoreBackup(from: url)
        await MainActor.run {
          importSuccess = true
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          importError = true
        }
      }
    }
  }
}

struct PsychologicalStatesSettingsView: View {
  @AppStorage("showStateDescriptions") private var showDescriptions = true
  @AppStorage("autoRefreshStates") private var autoRefresh = false
  @AppStorage("stateDisplayMode") private var displayMode = "grid"

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("Psychological States")
          .font(.largeTitle)
          .fontWeight(.bold)

        Form {
          Section(header: Text("Display")) {
            Picker("Display Mode", selection: self.$displayMode) {
              Text("Grid").tag("grid")
              Text("List").tag("list")
              Text("Cards").tag("cards")
            }
            .pickerStyle(SegmentedPickerStyle())
            .help("Choose how states are displayed")

            Toggle("Show Descriptions", isOn: self.$showDescriptions)
              .help("Display detailed descriptions for each state")
          }

          Section(header: Text("Behavior")) {
            Toggle("Auto-Refresh States", isOn: self.$autoRefresh)
              .help("Automatically refresh state data periodically")
          }

          Section(header: Text("Performance")) {
            Text("Grid mode: Optimized for browsing")
            Text("List mode: Compact for quick access")
            Text("Cards mode: Detailed with animations")
          }
        }
      }
      .padding()
    }
    .navigationTitle("Psychological States")
  }
}
