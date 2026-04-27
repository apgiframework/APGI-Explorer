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
      Task {
        let starterProfile = QuizProfile(
          id: UUID(),
          name: "New Profile",
          dateCreated: Date(),
          dateModified: Date(),
          results: ["ε": 50, "π": 50, "θₜ": 50, "β": 50]
        )
        try? await PersistenceController.shared.saveProfile(starterProfile)
      }

      // Bring main window to front so the new profile is visible in app context.
      if let mainWindow = NSApplication.shared.windows.first(where: {
        $0.identifier?.rawValue == "main"
      }) {
        mainWindow.makeKeyAndOrderFront(nil)
      }
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
}
