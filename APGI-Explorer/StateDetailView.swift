import SwiftUI
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

struct StateDetailView: View {
    let state: PsychologicalState
    @StateObject private var profileManager = ProfileManager()
    @State private var showSavedAlert = false
    @State private var selectedProfileName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // State Name and Description
                VStack(alignment: .leading, spacing: 8) {
                    Text(self.state.name)
                        .font(.largeTitle)
                        .foregroundColor(.primary)
                    Text(self.state.description)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)

                Divider()

                // APGI Parameters Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("APGI Parameters")
                        .font(.headline)

                    StateParameterRow(
                        label: "Prediction Error (ε)",
                        value: self.state.parameters.predictionError.formattedAccuracy
                    )
                    StateParameterRow(label: "Precision (π)", value: "\(self.state.parameters.precision)")
                    StateParameterRow(label: "Threshold (θₜ)", value: "\(self.state.parameters.threshold)")
                    StateParameterRow(label: "Somatic Bias (β)", value: "\(self.state.parameters.somaticBias)")
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .cornerRadius(10)

                // Optional: Save this state to a profile for reference
                if !self.profileManager.profiles.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Associate with Profile")
                            .font(.headline)

                        Picker("Select Profile", selection: self.$selectedProfileName) {
                            ForEach(self.profileManager.profiles, id: \.id) { profile in
                                Text(profile.name).tag(profile.name)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 300)

                        Button(action: self.saveStateToProfile) {
                            HStack {
                                Spacer()
                                Text("Save to Selected Profile")
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(self.selectedProfileName.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(8)
                        }
                        .disabled(self.selectedProfileName.isEmpty)
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle(self.state.name)
        .alert("State Saved!", isPresented: self.$showSavedAlert) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text("This state has been associated with '\(self.selectedProfileName)'.")
        }
        .onAppear {
            if !self.profileManager.profiles.isEmpty {
                self.selectedProfileName = self.profileManager.profiles[0].name
            }
        }
    }

    private func saveStateToProfile() {
        // In a real app, you would update the profile to include this state
        // For example: profileManager.addStateToProfile(state, profileName: selectedProfileName)
        self.showSavedAlert = true
    }
}

// MARK: - Helper View

private struct StateParameterRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(self.label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(self.value)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
