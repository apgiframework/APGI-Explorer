import AppKit
import CoreData
import CoreSpotlight
import OSLog
import SwiftUI
import UserNotifications

// MARK: - Notification Extensions

extension Notification.Name {
  static let newQuizSession = Notification.Name("newQuizSession")
  static let openRecentProfile = Notification.Name("openRecentProfile")
}

@main
struct APGIExplorerApp: App {
  private static let logger = Logger()
  @StateObject private var profileManager = ProfileManager()
  @StateObject private var stateModel = StateModel()
  @StateObject private var appState = AppState.shared
  @StateObject private var themeManager = ThemeManager.shared
  @AppStorage("fontSize") private var fontSize: Double = 16.0

  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  let persistenceController = PersistenceController.shared

  init() {
    // Check for screenshot mode command line argument
    if CommandLine.arguments.contains("--screenshot-mode") {
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        APGI_Explorer.ScreenshotAutomationRunner.run()
      }
    }

    // Request notification permissions
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
      granted, error in
      if let error {
        Self.logger.logError("Notification authorization failed: \(error.localizedDescription)")
      } else if granted {
        Self.logger.log("Notification permission granted")
      } else {
        Self.logger.log("Notification permission denied")
      }
    }

    // Start automatic backup scheduling
    DispatchQueue.main.async {
      FileStorageManager.shared.scheduleAutomaticBackups()
    }
  }

  var body: some Scene {
    WindowGroup {
      if self.appState.hasCompletedOnboarding {
        MainTabView()
          .environment(\.managedObjectContext, self.persistenceController.container.viewContext)
          .environmentObject(self.profileManager)
          .environmentObject(self.stateModel)
          .environmentObject(self.appState)
          .environmentObject(self.themeManager)
          .environment(\.font, Font.system(size: self.fontSize))
          .withGlobalKeyboardShortcuts(profileManager: self.profileManager)
          .preferredColorScheme(self.themeManager.currentTheme.getColorScheme())
          .environment(\.currentTheme, self.themeManager.currentTheme)
          .onContinueUserActivity(HandoffActivity.activityType) { _ in
            // Handle handoff at app level when no quiz view is active
            ConsoleAnalyticsService.shared.track(event: .handoffActivityRestored)
          }
      } else {
        OnboardingView()
          .environmentObject(self.appState)
          .environmentObject(self.themeManager)
          .environment(\.font, Font.system(size: self.fontSize))
          #if os(macOS)
            .frame(minWidth: 800, minHeight: 600)
          #endif
          .preferredColorScheme(self.themeManager.currentTheme.getColorScheme())
          .environment(\.currentTheme, self.themeManager.currentTheme)
          .onContinueUserActivity(HandoffActivity.activityType) { _ in
            // Handle handoff during onboarding
            ConsoleAnalyticsService.shared.track(event: .handoffActivityRestored)
          }
      }
    }
    .defaultSize(width: 1000, height: 700)
    .windowResizability(.contentSize)
    .commands {
      MenuCommands(profileManager: self.profileManager, stateModel: self.stateModel)
    }

    #if os(macOS)
      // Keep these windows available but they'll be accessible from the main window tabs by default
      WindowGroup("State Explorer", id: "state-explorer") {
        PsychologicalStatesView()
          .environmentObject(self.stateModel)
          .environmentObject(self.themeManager)
          .environment(\.font, Font.system(size: self.fontSize))
          .environment(\.appDependencies, AppDependencies.shared)
          .preferredColorScheme(self.themeManager.currentTheme.getColorScheme())
          .environment(\.currentTheme, self.themeManager.currentTheme)
      }
      .defaultSize(width: 1200, height: 800)

      WindowGroup("Profile Comparison", id: "profile-comparison") {
        ProfileComparisonView()
          .environmentObject(self.profileManager)
          .environmentObject(self.themeManager)
          .environment(\.font, Font.system(size: self.fontSize))
          .preferredColorScheme(self.themeManager.currentTheme.getColorScheme())
          .environment(\.currentTheme, self.themeManager.currentTheme)
      }
      .defaultSize(width: 1000, height: 700)

      Settings {
        SettingsView()
          .environmentObject(AppState.shared)
          .environmentObject(self.themeManager)
          .environment(\.font, Font.system(size: self.fontSize))
          .preferredColorScheme(self.themeManager.currentTheme.getColorScheme())
          .environment(\.currentTheme, self.themeManager.currentTheme)
      }

      MenuBarExtra("APGI Explorer", systemImage: "brain.head.profile") {
        MenuBarView()
      }
    #endif
  }
}
