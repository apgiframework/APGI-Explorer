import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// DisplayMode is defined in UserDefaultsManager.swift

struct PsychologicalStatesView: View {
    @StateObject private var stateModel = StateModel()
    @Environment(\.appDependencies) private var dependencies
    @State private var searchText = ""
    @State private var selectedParameter = "All"
    @AppStorage("statesDisplayMode") private var displayMode: DisplayMode = .list
    @State private var showParameterSummary = true
    
    private var searchService: StateSearchService {
        dependencies.getStateSearchService()
    }
    
    private let parameters = ["All", "ε (Prediction Error)", "π (Precision)", "θₜ (Threshold)", "β (Somatic Bias)"]
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [.blue, .purple]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var filteredStates: [PsychologicalState] {
        var result = stateModel.states

        if !searchText.isEmpty {
            result = searchService.search(query: searchText, in: result)
        }

        if let key = parameterKey(for: selectedParameter), selectedParameter != "All" {
            result.sort { state1, state2 in
                let val1 = extractNumericValue(from: getValue(for: state1, key: key))
                let val2 = extractNumericValue(from: getValue(for: state2, key: key))
                return val1 > val2
            }
        } else {
            result.sort { $0.name < $1.name }
        }

        return result
    }
    
    private var selectedParameterKey: String? {
        parameterKey(for: selectedParameter)
    }
    
    private func colorForParameter(_ key: String) -> Color {
        switch key {
        case "predictionError": return .red
        case "precision": return .green
        case "threshold": return .orange
        case "somaticBias": return .purple
        default: return .blue
        }
    }
    
    private func formattedParameterValue(_ value: String, for key: String) -> String {
        let numValue = extractNumericValue(from: value)
        if key == "threshold" || key == "somaticBias" {
            return String(format: "%.2f", numValue)
        }
        return value
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            VStack(spacing: 0) {
                HStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                        
                        TextField("Search states...", text: $searchText)
                            .textFieldStyle(.plain)
                            .padding(.vertical, 8)
                            .padding(.trailing, 8)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                            .cornerRadius(8)
                    }
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    // Display mode toggle
                    Picker("Display Mode", selection: $displayMode) {
                        ForEach(DisplayMode.allCases) { mode in
                            Image(systemName: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                    
                    // Filter menu
                    Menu {
                        Picker("Sort by", selection: $selectedParameter) {
                            ForEach(parameters, id: \.self) { param in
                                Label(param, systemImage: iconName(for: parameterKey(for: param)))
                                    .tag(param)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Material.ultraThinMaterial)
                
                // Parameter summary
                if showParameterSummary && selectedParameterKey != nil {
                    HStack {
                        Text("Showing by: ").font(.caption).foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            ForEach(["predictionError", "precision", "threshold", "somaticBias"], id: \.self) { key in
                                if let paramName = parameterName(for: key) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(colorForParameter(key).opacity(0.7))
                                            .frame(width: 10, height: 10)
                                        Text(paramName.prefix(1))
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        selectedParameterKey == key ?
                                        colorForParameter(key).opacity(0.2) :
                                        Color.gray.opacity(0.1)
                                    )
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        selectedParameter = parameterDisplayName(for: key) ?? "All"
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { showParameterSummary = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.opacity)
                }
            }
            .background(Material.ultraThinMaterial)
            .animation(.easeInOut, value: showParameterSummary)
            
            // Content
            if filteredStates.isEmpty {
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
            } else if displayMode == .list {
                listView
            } else {
                gridView
            }
        }
        .navigationTitle("Psychological States")
        .toolbar {
            ToolbarItem {
                if !searchText.isEmpty || selectedParameter != "All" {
                    Button(action: resetFilters) {
                        Label("Reset", systemImage: "arrow.uturn.left.circle")
                    }
                }
            }
        }
        .onAppear {
            stateModel.states.sort { $0.name < $1.name }
        }
        .onChange(of: selectedParameter) {
            showParameterSummary = selectedParameter != "All"
        }
    }

    // MARK: - View Components
    
    private var listView: some View {
        List(filteredStates, id: \.id) { state in
            NavigationLink(destination: StateDetailView(state: state)) {
                HStack(spacing: 12) {
                    // Icon/Emoji
                    ZStack {
                        Circle()
                            .fill(colorForState(state).opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        // Use first letter of state name as fallback
                        Text(state.name.prefix(1))
                            .font(.headline)
                            .foregroundColor(colorForState(state))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if let key = selectedParameterKey, key != "All" {
                            parameterRow(state: state, key: key)
                        } else {
                            allParametersRow(state: state)
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
                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)
            ], spacing: 12) {
                ForEach(filteredStates, id: \.id) { state in
                    NavigationLink(destination: StateDetailView(state: state)) {
                        VStack(spacing: 12) {
                            // State icon/emoji
                            ZStack {
                                Circle()
                                    .fill(colorForState(state).opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                // Use first letter of state name as fallback
                                Text(state.name.prefix(1))
                                    .font(.title3.bold())
                                    .foregroundColor(colorForState(state))
                            }
                            
                            // State name
                            Text(state.name)
                                .font(.subheadline.bold())
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            // Parameter value if filtered
                            if let key = selectedParameterKey, key != "All" {
                                VStack(spacing: 4) {
                                    Text(parameterDisplayName(for: key)?.prefix(1) ?? "")
                                        .font(.caption.bold())
                                        .frame(width: 24, height: 24)
                                        .background(colorForParameter(key).opacity(0.2))
                                        .clipShape(Circle())
                                    
                                    Text(formattedParameterValue(getValue(for: state, key: key), for: key))
                                        .font(.caption.monospaced())
                                        .foregroundColor(colorForParameter(key))
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.gray.opacity(0.1))
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
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    private func parameterRow(state: PsychologicalState, key: String) -> some View {
        let value = getValue(for: state, key: key)
        _ = extractNumericValue(from: value) // Extract numeric value for potential future use
        
        return HStack(spacing: 8) {
            // Parameter indicator
            Text(key.prefix(1).uppercased())
                .font(.caption2.bold())
                .frame(width: 20, height: 20, alignment: .center)
                .background(colorForParameter(key).opacity(0.2))
                .foregroundColor(colorForParameter(key))
                .clipShape(Circle())
            
            // Parameter name and value
            Text(parameterDisplayName(for: key) ?? key)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Value with visual indicator
            HStack(spacing: 4) {
                Text(formattedParameterValue(value, for: key))
                    .font(.caption.monospaced())
                    .foregroundColor(colorForParameter(key))
                
                // Visual indicator (bar or circle)
                if key != "threshold" && key != "somaticBias" {
                    Circle()
                        .fill(colorForParameter(key).opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    private func allParametersRow(state: PsychologicalState) -> some View {
        HStack(spacing: 4) {
            ForEach(["predictionError", "precision", "threshold", "somaticBias"], id: \.self) { key in
                if key != "threshold" && key != "somaticBias" {
                    Circle()
                        .fill(colorForParameter(key).opacity(0.3))
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
        case "ε (Prediction Error)": return "predictionError"
        case "π (Precision)": return "precision"
        case "θₜ (Threshold)": return "threshold"
        case "β (Somatic Bias)": return "somaticBias"
        default: return nil
        }
    }
    
    private func parameterDisplayName(for key: String) -> String? {
        switch key {
        case "predictionError": return "ε"
        case "precision": return "π"
        case "threshold": return "θₜ"
        case "somaticBias": return "β"
        default: return nil
        }
    }
    
    private func parameterName(for key: String) -> String? {
        switch key {
        case "predictionError": return "Prediction Error"
        case "precision": return "Precision"
        case "threshold": return "Threshold"
        case "somaticBias": return "Somatic Bias"
        default: return nil
        }
    }
    
    private func iconName(for key: String?) -> String {
        switch key {
        case "predictionError": return "exclamationmark.triangle"
        case "precision": return "scope"
        case "threshold": return "line.horizontal.3.decrease.circle"
        case "somaticBias": return "brain.head.profile"
        default: return "list.bullet"
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
            searchText = ""
            selectedParameter = "All"
        }
    }
}
