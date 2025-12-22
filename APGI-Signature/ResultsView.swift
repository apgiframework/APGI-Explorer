import SwiftUI

struct ResultsView: View {
    @StateObject private var profileManager = ProfileManager()
    @ObservedObject var quizModel: QuizModel
    @State private var profileName = ""
    @State private var showSavedAlert = false

    private var scores: [String: Int] {
        quizModel.calculateScore()
    }

    private var backgroundColor: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(.systemGroupedBackground)
        #endif
    }

    var body: some View {
        let profileType = profileManager.determineProfileType(for: scores)

        return VStack(spacing: 20) {
            Text("Quiz Results")
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(scores.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text("\(key.capitalized):")
                            .frame(width: 150, alignment: .leading)
                        Text("\(scores[key] ?? 0)")
                    }
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(10)

            Text("Profile Type: **\(profileType)**")
                .font(.headline)

            Form {
                Section(header: Text("Save Your Results")) {
                    TextField("Profile Name", text: $profileName)
                        .textFieldStyle(.roundedBorder)
                    Button(action: saveProfile) {
                        HStack {
                            Spacer()
                            Text("Save to Profile")
                            Spacer()
                        }
                    }
                    .disabled(profileName.isEmpty)
                }
            }
            .frame(width: 300)

            Spacer()
        }
        .padding()
        .navigationTitle("Results")
        .alert("Profile Saved!", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your results have been saved to '\(profileName)'.")
        }
    }

    private func saveProfile() {
        profileManager.createProfile(name: profileName, results: scores)
        showSavedAlert = true
        profileName = ""
    }
}
