import SwiftUI
import AppKit
import CoreData

// MARK: - Notification Extensions
extension Notification.Name {
    static let newQuizSession = Notification.Name("newQuizSession")
    static let openRecentProfile = Notification.Name("openRecentProfile")
}

@main
struct APGIExplorerApp: App {
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var stateModel = StateModel()
    @StateObject private var appState = AppState.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    let persistenceController = PersistenceController.shared
    
    init() {
        // Run screenshot automation when requested (both debug and production)
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0) {
            ScreenshotAutomationRunner.run()
        }
        
        // Start automatic backup scheduling
        DispatchQueue.main.async {
            FileStorageManager.shared.scheduleAutomaticBackups()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(profileManager)
                    .environmentObject(stateModel)
                    .environmentObject(appState)
                    .environmentObject(themeManager)
                    .withGlobalKeyboardShortcuts(profileManager: profileManager)
                    .preferredColorScheme(themeManager.currentTheme.getColorScheme())
                    .environment(\.currentTheme, themeManager.currentTheme)
                    .onContinueUserActivity(HandoffActivity.activityType) { userActivity in
                        // Handle handoff at app level when no quiz view is active
                        ConsoleAnalyticsService.shared.track(event: .handoffActivityRestored)
                    }
            } else {
                OnboardingView()
                    .environmentObject(appState)
                    .environmentObject(themeManager)
                    .frame(minWidth: 800, minHeight: 600)
                    .preferredColorScheme(themeManager.currentTheme.getColorScheme())
                    .environment(\.currentTheme, themeManager.currentTheme)
                    .onContinueUserActivity(HandoffActivity.activityType) { userActivity in
                        // Handle handoff during onboarding
                        ConsoleAnalyticsService.shared.track(event: .handoffActivityRestored)
                    }
            }
        }
        .defaultSize(width: 1000, height: 700)
        .windowResizability(.contentSize)
        .commands {
            MenuCommands(profileManager: profileManager, stateModel: stateModel)
            
            // Add keyboard shortcuts for navigation
            CommandGroup(after: .newItem) {
                Button("Go to States") {
                    NSApp.sendAction(Selector(("show" + "States")), to: nil, from: nil)
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Go to Compare") {
                    NSApp.sendAction(Selector(("show" + "Compare")), to: nil, from: nil)
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Go to Settings") {
                    NSApp.sendAction(Selector(("show" + "Settings")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        #if os(macOS)
        // Keep these windows available but they'll be accessible from the main window tabs by default
        WindowGroup("State Explorer", id: "state-explorer") {
            PsychologicalStatesView()
                .environmentObject(stateModel)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.getColorScheme())
                .environment(\.currentTheme, themeManager.currentTheme)
        }
        .defaultSize(width: 1200, height: 800)
        
        WindowGroup("Profile Comparison", id: "profile-comparison") {
            ProfileComparisonView()
                .environmentObject(profileManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.getColorScheme())
                .environment(\.currentTheme, themeManager.currentTheme)
        }
        .defaultSize(width: 1000, height: 700)
        
        Settings {
            SettingsView()
                .environmentObject(AppState.shared)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.getColorScheme())
                .environment(\.currentTheme, themeManager.currentTheme)
        }
        #endif
    }
}
