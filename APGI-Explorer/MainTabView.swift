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

            NavigationStack {
                PsychologicalStatesView()
            }
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

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .frame(minWidth: 800, minHeight: 600)
        .preferredColorScheme(self.themeManager.currentTheme.getColorScheme())
        .environment(\.currentTheme, self.themeManager.currentTheme)
        .onReceive(self.themeManager.$currentTheme) { _ in
            // Theme will be applied automatically through preferredColorScheme
        }
    }
}
