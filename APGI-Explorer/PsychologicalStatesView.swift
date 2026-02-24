import SwiftUI
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

// DisplayMode is defined in UserDefaultsManager.swift

struct PsychologicalStatesView: View {
    @StateObject private var stateModel = StateModel()
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    @State private var searchText = ""
    @State private var selectedParameter = "All"
    @AppStorage("statesDisplayMode") private var displayMode: DisplayMode = .list
    @AppStorage("showParameterSummary") private var showParameterSummary: Bool = true
    @AppStorage("enableLiveSearch") private var enableLiveSearch: Bool = true
    @AppStorage("showSearchHints") private var showSearchHints: Bool = true
    @AppStorage("lazyLoading") private var lazyLoading: Bool = true
    @AppStorage("cacheSearchResults") private var cacheSearchResults: Bool = true

    private var searchService: StateSearchService {
        self.dependencies.getStateSearchService()
    }

    private let parameters = ["All", "ε (Prediction Error)", "π (Precision)", "θₜ (Threshold)", "β (Somatic Bias)"]
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [.blue, .purple]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var filteredStates: [PsychologicalState] {
        var result = self.stateModel.states

        if !self.searchText.isEmpty {
            // MED-001 Fix: Handle special characters properly in search
            let sanitizedSearchText = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            result = self.searchService.search(query: sanitizedSearchText, in: result)
        }

        if let key = parameterKey(for: selectedParameter), selectedParameter != "All" {
            result.sort { state1, state2 in
                let val1 = self.extractNumericValue(from: self.getValue(for: state1, key: key))
                let val2 = self.extractNumericValue(from: self.getValue(for: state2, key: key))
                return val1 > val2
            }
        } else {
            result.sort { $0.name < $1.name }
        }

        return result
    }

    private var selectedParameterKey: String? {
        self.parameterKey(for: self.selectedParameter)
    }

    private func colorForParameter(_ key: String) -> Color {
        switch key {
        case "predictionError": .red
        case "precision": .green
        case "threshold": .orange
        case "somaticBias": .purple
        default: .blue
        }
    }

    private func formattedParameterValue(_ value: String, for key: String) -> String {
        let numValue = self.extractNumericValue(from: value)
        if key == "threshold" || key == "somaticBias" {
            return String(format: "%.2f", numValue)
        }
        return value
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            self.mainContent
        }
        .navigationTitle("Psychological States")
        .toolbar {
            ToolbarItem {
                if !self.searchText.isEmpty || self.selectedParameter != "All" {
                    Button(action: self.resetFilters) {
                        Label("Reset", systemImage: "arrow.uturn.left.circle")
                    }
                }
            }
        }
        .onAppear {
            self.stateModel.states.sort { $0.name < $1.name }
        }
        .onChange(of: self.selectedParameter) {
            self.showParameterSummary = self.selectedParameter != "All"
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            self.searchAndFilterBar
            self.contentArea
        }
    }

    private var searchAndFilterBar: some View {
        VStack(spacing: 0) {
            self.searchBar
            self.parameterSummaryView
        }
        .background(Material.ultraThinMaterial)
        .animation(.easeInOut, value: self.showParameterSummary)
    }

    private var searchBar: some View {
        HStack {
            self.searchTextField
            Spacer()
            self.displayModeToggle
            self.filterMenu
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var searchTextField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .padding(.leading, 8)

            TextField("Search states...", text: self.$searchText)
                .textFieldStyle(.plain)
                .padding(.vertical, 8)
                .padding(.trailing, 8)
                .background(AppColors.secondaryBackground.opacity(0.5))
                .cornerRadius(8)
                .overlay(self.searchHintsOverlay)
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var searchHintsOverlay: some View {
        if self.showSearchHints, self.searchText.isEmpty {
            HStack {
                Text("Try: anxiety, focus, creativity...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
        }
    }

    private var displayModeToggle: some View {
        Picker("Display Mode", selection: self.$displayMode) {
            ForEach(DisplayMode.allCases) { mode in
                Image(systemName: mode.icon).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 100)
    }

    private var filterMenu: some View {
        Menu {
            Picker("Sort by", selection: self.$selectedParameter) {
                ForEach(self.parameters, id: \.self) { param in
                    Label(param, systemImage: self.iconName(for: self.parameterKey(for: param)))
                        .tag(param)
                }
            }
        } label: {
            Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
                .padding(8)
                .background(AppColors.buttonBackground.opacity(0.1))
                .cornerRadius(8)
        }
        .menuStyle(.borderlessButton)
    }

    @ViewBuilder
    private var parameterSummaryView: some View {
        if self.showParameterSummary, self.selectedParameterKey != nil {
            HStack {
                Text("Showing by: ").font(.caption).foregroundColor(.secondary)
                self.parameterFilterButtons
                Spacer()
                Button(action: { self.showParameterSummary = false }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                })
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .transition(.opacity)
        }
    }

    private var parameterFilterButtons: some View {
        HStack(spacing: 16) {
            ForEach(["predictionError", "precision", "threshold", "somaticBias"], id: \.self) { key in
                if let paramName = parameterName(for: key) {
                    self.parameterFilterButton(key: key, paramName: paramName)
                }
            }
        }
    }

    private func parameterFilterButton(key: String, paramName: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(self.colorForParameter(key).opacity(0.7))
                .frame(width: 10, height: 10)
            Text(paramName.prefix(1))
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            self.selectedParameterKey == key ?
                self.colorForParameter(key).opacity(0.2) :
                Color.gray.opacity(0.1)
        )
        .cornerRadius(12)
        .accessibleTap(
            action: { self.selectedParameter = self.parameterDisplayName(for: key) ?? "All" },
            accessibilityLabel: "Select \(self.parameterDisplayName(for: key) ?? "All") parameter",
            accessibilityHint: "Filters states by \(self.parameterDisplayName(for: key) ?? "All") parameter"
        )
    }

    @ViewBuilder
    private var contentArea: some View {
        if self.filteredStates.isEmpty {
            self.emptyStateView
        } else if self.displayMode == .list {
            self.listView
        } else {
            self.gridView
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("No states found")
                .font(.headline)
            Text("Try adjusting your search or filter criteria")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - View Components

    private var listView: some View {
        List(self.filteredStates, id: \.id) { state in
            NavigationLink(destination: StateDetailView(state: state)) {
                HStack(spacing: 12) {
                    // Icon/Emoji
                    ZStack {
                        Circle()
                            .fill(self.colorForState(state).opacity(0.2))
                            .frame(width: 40, height: 40)

                        // Use first letter of state name as fallback
                        Text(state.name.prefix(1))
                            .font(.headline)
                            .foregroundColor(self.colorForState(state))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.name)
                            .font(.headline)
                            .lineLimit(1)

                        if let key = selectedParameterKey, key != "All" {
                            self.parameterRow(state: state, key: key)
                        } else {
                            self.allParametersRow(state: state)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            .listRowSeparator(.visible, edges: .all)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
        .listStyle(.plain)
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12),
            ], spacing: 12) {
                ForEach(self.filteredStates, id: \.id) { state in
                    NavigationLink(destination: StateDetailView(state: state)) {
                        VStack(spacing: 12) {
                            // State icon/emoji
                            ZStack {
                                Circle()
                                    .fill(self.colorForState(state).opacity(0.2))
                                    .frame(width: 50, height: 50)

                                // Use first letter of state name as fallback
                                Text(state.name.prefix(1))
                                    .font(.title3.bold())
                                    .foregroundColor(self.colorForState(state))
                            }

                            // State name
                            Text(state.name)
                                .font(.subheadline.bold())
                                .multilineTextAlignment(.center)
                                .lineLimit(2)

                            // Parameter value if filtered
                            if let key = selectedParameterKey, key != "All" {
                                VStack(spacing: 4) {
                                    Text(self.parameterDisplayName(for: key)?.prefix(1) ?? "")
                                        .font(.caption.bold())
                                        .frame(width: 24, height: 24)
                                        .background(AppColors.success.opacity(0.2))
                                        .foregroundColor(AppColors.success)

                                    Text(self.formattedParameterValue(self.getValue(for: state, key: key), for: key))
                                        .font(.caption.monospaced())
                                        .foregroundColor(self.colorForParameter(key))
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(AppColors.adaptiveGray5)
                                .cornerRadius(12)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
        .background(AppColors.secondaryBackground.opacity(0.5))
    }

    private func parameterRow(state: PsychologicalState, key: String) -> some View {
        let value = self.getValue(for: state, key: key)
        _ = self.extractNumericValue(from: value) // Extract numeric value for potential future use

        return HStack(spacing: 8) {
            // Parameter indicator
            Text(key.prefix(1).uppercased())
                .font(.caption2.bold())
                .frame(width: 20, height: 20, alignment: .center)
                .background(self.colorForParameter(key).opacity(0.2))
                .foregroundColor(self.colorForParameter(key))
                .clipShape(Circle())

            // Parameter name and value
            Text(self.parameterDisplayName(for: key) ?? key)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // Value with visual indicator
            HStack(spacing: 4) {
                Text(self.formattedParameterValue(value, for: key))
                    .font(.caption.monospaced())
                    .foregroundColor(self.colorForParameter(key))

                // Visual indicator (bar or circle)
                if key != "threshold", key != "somaticBias" {
                    Circle()
                        .fill(self.colorForParameter(key).opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private func allParametersRow(state _: PsychologicalState) -> some View {
        HStack(spacing: 4) {
            ForEach(["predictionError", "precision", "threshold", "somaticBias"], id: \.self) { key in
                if key != "threshold", key != "somaticBias" {
                    Circle()
                        .fill(self.colorForParameter(key).opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            Text("View details")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.leading, 4)
        }
    }

    // MARK: - Helper Functions

    private func parameterKey(for option: String) -> String? {
        switch option {
        case "ε (Prediction Error)": "predictionError"
        case "π (Precision)": "precision"
        case "θₜ (Threshold)": "threshold"
        case "β (Somatic Bias)": "somaticBias"
        default: nil
        }
    }

    private func parameterDisplayName(for key: String) -> String? {
        switch key {
        case "predictionError": "ε"
        case "precision": "π"
        case "threshold": "θₜ"
        case "somaticBias": "β"
        default: nil
        }
    }

    private func parameterName(for key: String) -> String? {
        switch key {
        case "predictionError": "Prediction Error"
        case "precision": "Precision"
        case "threshold": "Threshold"
        case "somaticBias": "Somatic Bias"
        default: nil
        }
    }

    private func iconName(for key: String?) -> String {
        switch key {
        case "predictionError": "exclamationmark.triangle"
        case "precision": "scope"
        case "threshold": "line.horizontal.3.decrease.circle"
        case "somaticBias": "brain.head.profile"
        default: "list.bullet"
        }
    }

    private func getValue(for state: PsychologicalState, key: String) -> String {
        switch key {
        case "predictionError": state.predictionError
        case "precision": state.precision
        case "threshold": state.threshold
        case "somaticBias": state.somaticBias
        default: ""
        }
    }

    private func colorForState(_ state: PsychologicalState) -> Color {
        // This is a simple hash-based color generation
        // You might want to replace this with a more sophisticated approach
        let hash = abs(state.name.hashValue)
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal]
        return colors[hash % colors.count]
    }

    private func extractNumericValue(from string: String) -> Double {
        // Create a character set that includes numbers and decimal point
        let allowedChars = CharacterSet(charactersIn: "0123456789.")
        let filtered = string.unicodeScalars.filter { allowedChars.contains($0) }
        let filteredString = String(String.UnicodeScalarView(filtered))
        return Double(filteredString) ?? 0
    }

    private func resetFilters() {
        withAnimation {
            self.searchText = ""
            self.selectedParameter = "All"
        }
    }
}
