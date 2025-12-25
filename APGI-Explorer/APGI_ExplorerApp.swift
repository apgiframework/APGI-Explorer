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
    
    let persistenceController = PersistenceController.shared
    
    init() {
        // Run screenshot automation in debug mode
        #if DEBUG
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0) {
            ScreenshotAutomationRunner.run()
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(profileManager)
                    .environmentObject(stateModel)
                    .environmentObject(appState)
                    .withGlobalKeyboardShortcuts(profileManager: profileManager)
            } else {
                OnboardingView()
                    .environmentObject(appState)
                    .frame(minWidth: 800, minHeight: 600)
            }
        }
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
        }
        .defaultSize(width: 1200, height: 800)
        
        WindowGroup("Profile Comparison", id: "profile-comparison") {
            ProfileComparisonView()
                .environmentObject(profileManager)
        }
        .defaultSize(width: 1000, height: 700)
        
        Settings {
            AppSettingsView()
                .environmentObject(AppState.shared)
        }
        #endif
    }
}
