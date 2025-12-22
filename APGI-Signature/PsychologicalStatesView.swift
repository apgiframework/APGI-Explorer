import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PsychologicalStatesView: View {
    @StateObject private var stateModel = StateModel()
    @State private var searchText = ""
    @State private var selectedParameter = "All"

    private let parameters = ["All", "ε (Prediction Error)", "π (Precision)", "θₜ (Threshold)", "β (Somatic Bias)"]

    private var filteredStates: [PsychologicalState] {
        var result = stateModel.states

        if !searchText.isEmpty {
            result = result.filter { state in
                state.name.localizedCaseInsensitiveContains(searchText) ||
                state.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let key = parameterKey(for: selectedParameter) {
            result.sort { state1, state2 in
                let val1 = extractNumericValue(from: getValue(for: state1, key: key))
                let val2 = extractNumericValue(from: getValue(for: state2, key: key))
                return val1 > val2
            }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search states...", text: $searchText)
                    .textFieldStyle(.plain)

                Spacer()

                Menu {
                    Picker("Filter by", selection: $selectedParameter) {
                        ForEach(parameters, id: \.self) { param in
                            Text(param).tag(param)
                        }
                    }
                } label: {
                    Label("Filter", systemImage: "slider.horizontal.3")
                }
                .menuStyle(.borderedButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))

            List(filteredStates, id: \.id) { state in
                NavigationLink(destination: StateDetailView(state: state)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.name)
                            .font(.headline)

                        if let key = parameterKey(for: selectedParameter) {
                            HStack {
                                Text(key.prefix(1))
                                    .font(.caption)
                                    .bold()
                                    .frame(width: 20, alignment: .center)
                                    .background(Circle().fill(Color.blue.opacity(0.2)))

                                Text(getValue(for: state, key: key))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .listStyle(.plain)
            .navigationTitle("Psychological States")
            .toolbar {
                ToolbarItem {
                    if !searchText.isEmpty || selectedParameter != "All" {
                        Button(action: resetFilters) {
                            Image(systemName: "arrow.uturn.left")
                        }
                    }
                }
            }
        }
        .onAppear {
            stateModel.states.sort { $0.name < $1.name }
        }
    }

    private func parameterKey(for option: String) -> String? {
        switch option {
        case "ε (Prediction Error)": return "predictionError"
        case "π (Precision)": return "precision"
        case "θₜ (Threshold)": return "threshold"
        case "β (Somatic Bias)": return "somaticBias"
        default: return nil
        }
    }

    private func getValue(for state: PsychologicalState, key: String) -> String {
        switch key {
        case "predictionError": return state.predictionError
        case "precision": return state.precision
        case "threshold": return state.threshold
        case "somaticBias": return state.somaticBias
        default: return ""
        }
    }

    private func extractNumericValue(from string: String) -> Double {
        let components = string.components(separatedBy: CharacterSet.decimalDigits.inverted)
        let numbers = components.compactMap { Double($0) }
        return numbers.first ?? 0
    }

    private func resetFilters() {
        searchText = ""
        selectedParameter = "All"
    }
}
