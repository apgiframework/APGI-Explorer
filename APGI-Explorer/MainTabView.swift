import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var stateModel: StateModel
    @EnvironmentObject var appState: AppState
    
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
    }
}

struct AppSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .padding()
            
            Button("Show Onboarding Again") {
                appState.hasCompletedOnboarding = false
            }
            .padding()
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
