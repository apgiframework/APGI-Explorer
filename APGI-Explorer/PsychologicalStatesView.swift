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
  @AppStorage("autoRefreshStates") private var autoRefreshStates: Bool = false

  @State private var refreshTimer: Timer?
  @State private var lastRefreshTime = Date()

  private var searchService: StateSearchService {
    self.dependencies.getStateSearchService()
  }

  /// Refresh interval in seconds when auto-refresh is enabled
  private let refreshInterval: TimeInterval = 30.0

  private let parameters = [
    "All", "Illustrative reactivity", "Illustrative information prioritisation", "Illustrative attention", "Illustrative body-signal attention"
  ]
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
    case "predictionError": .precisionRed
    case "precision": .neuromodGreen
    case "threshold": .thresholdBlue
    case "somaticBias": .workspacePurple
    default: .thresholdBlue
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
    .onChange(of: self.selectedParameter) {
      self.showParameterSummary = self.selectedParameter != "All"
    }
    .onAppear {
      self.setupRefreshTimer()
    }
    .onDisappear {
      self.invalidateRefreshTimer()
    }
    .onChange(of: self.autoRefreshStates) { _, newValue in
      if newValue {
        self.setupRefreshTimer()
      } else {
        self.invalidateRefreshTimer()
      }
    }
  }

  /// Sets up the refresh timer for auto-refresh functionality
  private func setupRefreshTimer() {
    guard self.autoRefreshStates else { return }

    // Invalidate any existing timer first
    self.invalidateRefreshTimer()

    // Create new timer that fires every refreshInterval seconds
    self.refreshTimer = Timer.scheduledTimer(withTimeInterval: self.refreshInterval, repeats: true) { _ in
      Task { @MainActor in
        await self.refreshStateData()
      }
    }
  }

  /// Invalidates the refresh timer
  private func invalidateRefreshTimer() {
    self.refreshTimer?.invalidate()
    self.refreshTimer = nil
  }

  /// Performs the actual data refresh
  private func refreshStateData() async {
    // Update the last refresh time
    self.lastRefreshTime = Date()

    // Trigger a refresh by recreating the state model or calling its refresh method
    // Since StateModel is an ObservableObject, we can trigger an update
    await self.stateModel.refreshIfNeeded()
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
    .background(Color.darkNavy)
    .animation(.easeInOut, value: self.showParameterSummary)
  }

  private var searchBar: some View {
    HStack {
      self.searchTextField
      Spacer()
      self.displayModeToggle
      self.filterMenu
    }
    .padding(.horizontal, APGISpacing.md)
    .padding(.vertical, APGISpacing.sm)
  }

  private var searchTextField: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.inactiveSlate)
        .padding(.leading, 8)

      TextField(self.showSearchHints ? "Search states (e.g. anxiety, focus)..." : "Search states...", text: self.$searchText)
        .textFieldStyle(.plain)
        .padding(.vertical, 8)
        .padding(.trailing, 8)
        .background(Color.spaceBlack)
        .cornerRadius(APGIRadius.standard)
    }
    .background(Color.spaceBlack)
    .cornerRadius(APGIRadius.standard)
    .overlay(
      RoundedRectangle(cornerRadius: APGIRadius.standard)
        .stroke(Color.darkNavy, lineWidth: 1)
    )
  }

  @ViewBuilder
  private var searchHintsOverlay: some View {
    // Removed because we now use dynamic TextField placeholders to prevent text overlapping
  }

  private var displayModeToggle: some View {
    Picker("Display Mode", selection: self.$displayMode) {
      ForEach(DisplayMode.allCases) { mode in
        Image(systemName: mode.icon).tag(mode)
      }
    }
    .pickerStyle(.segmented)
    .labelsHidden()
    .frame(width: 120)
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
        .background(Color.thresholdBlue.opacity(0.1))
        .cornerRadius(APGIRadius.standard)
    }
    .menuStyle(.borderlessButton)
  }

  @ViewBuilder
  private var parameterSummaryView: some View {
    if self.showParameterSummary, self.selectedParameterKey != nil {
      HStack {
        Text("Showing by: ").font(APGITypography.micro).foregroundColor(.inactiveSlate)
        self.parameterFilterButtons
        Spacer()
        Button(
          action: { self.showParameterSummary = false },
          label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.inactiveSlate)
          }
        )
        .buttonStyle(.plain)
      }
      .padding(.horizontal, APGISpacing.md)
      .padding(.bottom, APGISpacing.sm)
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
        .font(APGITypography.micro)
        .foregroundColor(.primary)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      self.selectedParameterKey == key
        ? self.colorForParameter(key).opacity(0.2) : Color.inactiveSlate.opacity(0.1)
    )
    .cornerRadius(12)
    .accessibleTap(
      action: { self.selectedParameter = self.parameterFullName(for: key) ?? "All" },
      accessibilityLabel: "Select \(self.parameterDisplayName(for: key) ?? "All") parameter",
      accessibilityHint:
        "Filters states by \(self.parameterDisplayName(for: key) ?? "All") parameter"
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
        .foregroundColor(.inactiveSlate)
      Text("No states found")
        .font(APGITypography.h3)
      Text("Try adjusting your search or filter criteria")
        .font(APGITypography.body)
        .foregroundColor(.inactiveSlate)
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
              .font(APGITypography.h3)
              .foregroundColor(self.colorForState(state))
          }

          VStack(alignment: .leading, spacing: 4) {
            Text(state.name)
              .font(APGITypography.label)
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
            .foregroundColor(.inactiveSlate)
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
      LazyVGrid(
        columns: [
          GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)
        ], spacing: 12
      ) {
        ForEach(self.filteredStates, id: \.id) { state in
          NavigationLink(destination: StateDetailView(state: state)) {
            InteractiveCard(action: {}, content: {
              VStack(spacing: 12) {
                // State icon/emoji
                ZStack {
                  Circle()
                    .fill(self.colorForState(state).opacity(0.2))
                    .frame(width: 50, height: 50)

                  // Use first letter of state name as fallback
                  Text(state.name.prefix(1))
                    .font(APGITypography.h2)
                    .foregroundColor(self.colorForState(state))
                }

                // State name
                Text(state.name)
                  .font(APGITypography.label)
                  .multilineTextAlignment(.center)
                  .lineLimit(2)

                // Parameter value if filtered
                if let key = selectedParameterKey, key != "All" {
                  VStack(spacing: 4) {
                    Text(self.parameterDisplayName(for: key)?.prefix(1) ?? "")
                      .font(APGITypography.micro.bold())
                      .frame(width: 24, height: 24)
                      .background(Color.neuromodGreen.opacity(0.2))
                      .foregroundColor(.neuromodGreen)

                    Text(self.formattedParameterValue(self.getValue(for: state, key: key), for: key))
                      .font(APGITypography.mono)
                      .foregroundColor(self.colorForParameter(key))
                  }
                  .padding(.vertical, 4)
                  .padding(.horizontal, 8)
                  .background(Color.darkNavy)
                  .cornerRadius(12)
                }
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
            })
          }
          .buttonStyle(.plain)
        }
      }
      .padding(12)
    }
    .background(Color.darkNavy.opacity(0.5))
  }

  private func parameterRow(state: PsychologicalState, key: String) -> some View {
    let value = self.getValue(for: state, key: key)
    _ = self.extractNumericValue(from: value)  // Extract numeric value for potential future use

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
    case "Illustrative reactivity": "predictionError"
    case "Illustrative information prioritisation": "precision"
    case "Illustrative attention": "threshold"
    case "Illustrative body-signal attention": "somaticBias"
    default: nil
    }
  }

  private func parameterFullName(for key: String) -> String? {
    switch key {
    case "predictionError": return "Illustrative reactivity"
    case "precision": return "Illustrative information prioritisation"
    case "threshold": return "Illustrative attention"
    case "somaticBias": return "Illustrative body-signal attention"
    default: return nil
    }
  }

  private func parameterDisplayName(for key: String) -> String? {
    switch key {
    case "predictionError": "Illustrative reactivity"
    case "precision": "Illustrative information prioritisation"
    case "threshold": "Illustrative attention"
    case "somaticBias": "Illustrative body-signal attention"
    default: nil
    }
  }

  private func parameterName(for key: String) -> String? {
    switch key {
    case "predictionError": "Illustrative reactivity"
    case "precision": "Illustrative information prioritisation"
    case "threshold": "Illustrative attention"
    case "somaticBias": "Illustrative body-signal attention"
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
