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

// MARK: - Animation Speed Environment

struct AnimationSpeedKey: EnvironmentKey {
  static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
  var animationSpeed: Double {
    get { self[AnimationSpeedKey.self] }
    set { self[AnimationSpeedKey.self] = newValue }
  }
}

/// Helper to get animation duration adjusted by speed
extension Double {
  func adjustedForAnimationSpeed(_ speed: Double) -> Double {
    self / max(0.1, speed)
  }
}

// MARK: - Show Tooltips Environment

struct ShowTooltipsKey: EnvironmentKey {
  static let defaultValue: Bool = true
}

extension EnvironmentValues {
  var showTooltips: Bool {
    get { self[ShowTooltipsKey.self] }
    set { self[ShowTooltipsKey.self] = newValue }
  }
}

/// View extension for conditional help
extension View {
  @ViewBuilder
  func conditionalHelp(_ text: String, when showTooltips: Bool) -> some View {
    if showTooltips {
      self.help(text)
    } else {
      self
    }
  }
}

// MARK: - Debug & Experimental Feature Environment

struct DebugModeKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

struct ExperimentalFeaturesKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

extension EnvironmentValues {
  var debugModeEnabled: Bool {
    get { self[DebugModeKey.self] }
    set { self[DebugModeKey.self] = newValue }
  }

  var experimentalFeaturesEnabled: Bool {
    get { self[ExperimentalFeaturesKey.self] }
    set { self[ExperimentalFeaturesKey.self] = newValue }
  }
}

/// View modifier to conditionally show views based on debug mode
struct DebugModeModifier: ViewModifier {
  @Environment(\.debugModeEnabled) private var isDebugMode

  func body(content: Content) -> some View {
    if isDebugMode {
      content
    } else {
      EmptyView()
    }
  }
}

/// View modifier to conditionally show experimental features
struct ExperimentalFeatureModifier: ViewModifier {
  @Environment(\.experimentalFeaturesEnabled) private var isExperimentalEnabled

  func body(content: Content) -> some View {
    if isExperimentalEnabled {
      content
    } else {
      EmptyView()
    }
  }
}

extension View {
  /// Only show this view when debug mode is enabled
  func debugOnly() -> some View {
    self.modifier(DebugModeModifier())
  }

  /// Only show this view when experimental features are enabled
  func experimentalOnly() -> some View {
    self.modifier(ExperimentalFeatureModifier())
  }
}

@main
struct APGIExplorerApp: App {
  private static let logger = Logger()
  @StateObject private var profileManager = ProfileManager()
  @StateObject private var stateModel = StateModel()
  @StateObject private var appState = AppState.shared
  @StateObject private var themeManager = ThemeManager.shared
  @AppStorage("fontSize") private var fontSize: Double = 16.0
  @AppStorage("animationSpeed") private var animationSpeed: Double = 1.0
  @AppStorage("showTooltips") private var showTooltips: Bool = true
  @AppStorage("enableDebugMode") private var debugMode: Bool = false
  @AppStorage("enableExperimentalFeatures") private var experimentalFeatures: Bool = false

  /// Computed animation duration multiplier - lower speed = slower animations
  private var animationMultiplier: Double {
    1.0 / max(0.1, animationSpeed)
  }

  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  let persistenceController = PersistenceController.shared

  init() {
    // Check for screenshot mode command line argument
    if CommandLine.arguments.contains("--screenshot-mode") {
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        ScreenshotAutomationRunner.run()
      }
    }

    // Request notification permissions
    DispatchQueue.main.async {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error {
          // Silently handle notification authorization failures - notifications are optional
          Self.logger.log("Notification authorization not available: \(error.localizedDescription)")
        } else if granted {
          Self.logger.log("Notification permission granted")
        } else {
          Self.logger.log("Notification permission denied by user")
        }
      }
    }

    // Start automatic backup scheduling if enabled
    DispatchQueue.main.async {
      if UserDefaults.standard.bool(forKey: "autoBackupEnabled") {
        FileStorageManager.shared.scheduleAutomaticBackups()
      }
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
          .environment(\.animationSpeed, self.animationSpeed)
          .environment(\.showTooltips, self.showTooltips)
          .environment(\.debugModeEnabled, self.debugMode)
          .environment(\.experimentalFeaturesEnabled, self.experimentalFeatures)
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
          .environment(\.animationSpeed, self.animationSpeed)
          .environment(\.showTooltips, self.showTooltips)
          .environment(\.debugModeEnabled, self.debugMode)
          .environment(\.experimentalFeaturesEnabled, self.experimentalFeatures)
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
          .environment(\.animationSpeed, self.animationSpeed)
          .environment(\.showTooltips, self.showTooltips)
          .environment(\.debugModeEnabled, self.debugMode)
          .environment(\.experimentalFeaturesEnabled, self.experimentalFeatures)
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
          .environment(\.animationSpeed, self.animationSpeed)
          .environment(\.showTooltips, self.showTooltips)
          .environment(\.debugModeEnabled, self.debugMode)
          .environment(\.experimentalFeaturesEnabled, self.experimentalFeatures)
          .preferredColorScheme(self.themeManager.currentTheme.getColorScheme())
          .environment(\.currentTheme, self.themeManager.currentTheme)
      }
      .defaultSize(width: 1000, height: 700)

      Settings {
        SettingsView()
          .environmentObject(AppState.shared)
          .environmentObject(self.themeManager)
          .environment(\.font, Font.system(size: self.fontSize))
          .environment(\.animationSpeed, self.animationSpeed)
          .environment(\.showTooltips, self.showTooltips)
          .environment(\.debugModeEnabled, self.debugMode)
          .environment(\.experimentalFeaturesEnabled, self.experimentalFeatures)
          .preferredColorScheme(self.themeManager.currentTheme.getColorScheme())
          .environment(\.currentTheme, self.themeManager.currentTheme)
      }

      MenuBarExtra("APGI Explorer", systemImage: "brain.head.profile") {
        MenuBarView()
      }
    #endif
  }
}
