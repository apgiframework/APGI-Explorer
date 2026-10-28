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
  @State private var selectedProfileID: UUID?
  private var selectedProfile: QuizProfile? {
    profileManager.profiles.first { $0.id == selectedProfileID }
  }
  private var profileSelection: Binding<UUID?> {
    Binding(get: { selectedProfile?.id }, set: { selectedProfileID = $0 })
  }

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
            label: "Illustrative reactivity",
            value: self.state.parameters.predictionError.formattedAccuracy
          )
          StateParameterRow(label: "Illustrative information prioritisation", value: "\(self.state.parameters.precision)")
          StateParameterRow(label: "Illustrative attention", value: "\(self.state.parameters.threshold)")
          StateParameterRow(
            label: "Illustrative body-signal attention", value: "\(self.state.parameters.somaticBias)")
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

            Picker("Select Profile", selection: profileSelection) {
              Text("Choose a profile").tag(Optional<UUID>.none)
              ForEach(self.profileManager.profiles, id: \.id) { profile in
                Text(profile.name).tag(Optional(profile.id))
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
              .background(self.selectedProfile == nil ? Color.gray : Color.blue)
              .cornerRadius(8)
            }
            .disabled(self.selectedProfile == nil)
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
      Text("This state has been associated with '\(self.selectedProfile?.name ?? "")'.")
    }
  }

  private func saveStateToProfile() {
    guard selectedProfile != nil else { return }
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
