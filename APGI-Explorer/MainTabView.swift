import SwiftUI

struct MainTabView: View {
  @EnvironmentObject var profileManager: ProfileManager
  @EnvironmentObject var stateModel: StateModel
  @EnvironmentObject var appState: AppState
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    TabView {
      NavigationStack {
        ContentView()
      }
      .tabItem {
        Label("Home", systemImage: "house.fill")
      }

      NavigationStack {
        PsychologicalStatesView()
      }
      .tabItem {
        Label("States", systemImage: "brain.head.profile")
      }

      NavigationStack {
        PsychologicalStatesVisualizationView()
      }
      .tabItem {
        Label("Visualization", systemImage: "chart.dots.scatter")
      }

      NavigationStack {
        ProfileComparisonView()
      }
      .tabItem {
        Label("Compare", systemImage: "person.2.fill")
      }

      NavigationStack {
        SettingsView()
      }
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
