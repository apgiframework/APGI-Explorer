import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var stateModel: StateModel
    @EnvironmentObject var appState: AppState
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            PsychologicalStatesView()
                .tabItem {
                    Label("States", systemImage: "brain.head.profile")
                }
            
            PsychologicalStatesVisualizationView()
                .tabItem {
                    Label("Visualization", systemImage: "chart.scatter")
                }
            
            ProfileComparisonView()
                .tabItem {
                    Label("Compare", systemImage: "person.2.fill")
                }
            
            AppSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .frame(minWidth: 800, minHeight: 600)
        .preferredColorScheme(themeManager.currentTheme.getColorScheme())
        .environment(\.currentTheme, themeManager.currentTheme)
        .onReceive(themeManager.$currentTheme) { theme in
            // Theme will be applied automatically through preferredColorScheme
        }
    }
}

struct AppSettingsView: View {
    var body: some View {
        SettingsView()
    }
}
