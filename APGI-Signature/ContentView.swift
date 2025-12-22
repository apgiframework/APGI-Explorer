import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink("Start Quiz") {
                    IntroView()
                }
                NavigationLink("Browse Psychological States") {
                    PsychologicalStatesView()
                }
            }
            .padding()
            .navigationTitle("Quiz App")
        }
    }
}
