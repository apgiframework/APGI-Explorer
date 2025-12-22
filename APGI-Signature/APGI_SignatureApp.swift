import SwiftUI
import AppKit
import CoreData

// MARK: - Notification Extensions
extension Notification.Name {
    static let newQuizSession = Notification.Name("newQuizSession")
    static let openRecentProfile = Notification.Name("openRecentProfile")
}

@main
struct APGISignatureApp: App {
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var stateModel = StateModel()
    
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(profileManager)
                .environmentObject(stateModel)
                .withGlobalKeyboardShortcuts(profileManager: profileManager)
        }
        .commands {
            MenuCommands(profileManager: profileManager, stateModel: stateModel)
        }
        
        #if os(macOS)
        // Add dedicated window for state exploration
        WindowGroup("State Explorer", id: "state-explorer") {
            PsychologicalStatesView()
                .environmentObject(stateModel)
        }
        .defaultSize(width: 1200, height: 800)
        
        // Add window for profile comparison
        WindowGroup("Profile Comparison", id: "profile-comparison") {
            ProfileComparisonView()
                .environmentObject(profileManager)
        }
        .defaultSize(width: 1000, height: 700)
        
        Settings {
            SettingsView()
                .environmentObject(profileManager)
        }
        #endif
    }
}
