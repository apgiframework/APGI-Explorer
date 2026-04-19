import AppKit
import SwiftUI
import os.log

struct MenuBarView: View {
  @Environment(\.openWindow) var openWindow

  var body: some View {
    Button("Open Main Window") {
      // Bring main window to front
      if let mainWindow = NSApplication.shared.windows.first(where: {
        $0.identifier?.rawValue == "main"
      }) {
        mainWindow.makeKeyAndOrderFront(nil)
      }
    }
    Button("New Profile") {
      createNewProfile()
    }
    Divider()
    Button("Take Screenshots") {
      runScreenshotAutomation()
    }
    Divider()
    Button("Quit") {
      NSApplication.shared.terminate(nil)
    }
  }

  private func createNewProfile() {
    // Bring main window to front first
    if let mainWindow = NSApplication.shared.windows.first(where: {
      $0.identifier?.rawValue == "main"
    }) {
      mainWindow.makeKeyAndOrderFront(nil)
    }

    // Create new profile using ProfileManager
    Task {
      do {
        let profileManager = ProfileManager()
        let newProfile = try await profileManager.createProfile(
          name: "New Profile",
          results: [:]
        )
        await MainActor.run {
          profileManager.currentProfile = newProfile
        }
      } catch {
        // Error will be handled by ProfileManager's error publishing
        os_log(
          "Failed to create new profile from menu bar: %{public}@",
          log: OSLog.default, type: .error,
          error.localizedDescription)
      }
    }
  }

  /// Method A: Quick Start Screenshot Automation
  /// Uses the convenience function from ScreenshotAutomation.swift
  private func runScreenshotAutomation() {
    // Bring main window to front first
    if let mainWindow = NSApplication.shared.windows.first(where: {
      $0.identifier?.rawValue == "main"
    }) {
      mainWindow.makeKeyAndOrderFront(nil)
    }

    os_log(
      "📸 Starting screenshot automation via Menu Bar (Method A - Quick Start)",
      log: OSLog.default, type: .info)

    // Check screen recording permission
    guard ScreenRecordingPermission.hasPermission else {
      os_log("❌ Screen recording permission not granted", log: OSLog.default, type: .error)
      ScreenRecordingPermission.requestPermission()

      // Show alert to user
      let alert = NSAlert()
      alert.messageText = "Screen Recording Permission Required"
      alert.informativeText =
        "Please grant screen recording permission in System Settings > Privacy & Security > Screen Recording, then try again."
      alert.alertStyle = .warning
      alert.addButton(withTitle: "OK")
      alert.runModal()
      return
    }

    // Method A: Use the quick start convenience function
    // This uses default settings: ~/Desktop/Screenshots, PNG, Light+Dark modes, multiple resolutions
    quickStartScreenshotAutomation()

    os_log(
      "✅ Screenshot automation completed. Check ~/Desktop/Screenshots for output.",
      log: OSLog.default, type: .info)

    // Show completion alert
    let alert = NSAlert()
    alert.messageText = "Screenshots Captured"
    alert.informativeText =
      "Screenshots have been saved to ~/Desktop/Screenshots. A screenshot_report.json file contains details about the captured images."
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Open Folder")
    alert.addButton(withTitle: "OK")

    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
      // Open the screenshots folder
      let screenshotsURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
        .first?
        .appendingPathComponent("Screenshots")
      if let url = screenshotsURL {
        NSWorkspace.shared.open(url)
      }
    }
  }
}
