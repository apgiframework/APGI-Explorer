import SwiftUI

struct PsychologicalStatesVisualizationView: View {
  @StateObject private var stateModel = StateModel()
  @State private var selectedState: PsychologicalState?
  @State private var searchText = ""
  @State private var hoveredStateId: Int?

  // Chart dimensions and scaling
  private let chartPadding: CGFloat = 40
  private let pointSize: CGFloat = 8

  var body: some View {
    HSplitView {
      // Left side - Phase Space Chart
        VStack(spacing: 0) {
          // Header with legend
          VStack(spacing: APGISpacing.sm) {
            Text("Phase Space: Precision vs. Threshold")
              .font(APGITypography.h2)
              .padding(.top, APGISpacing.md)

            // Legend
            HStack(spacing: 20) {
              self.legendItem(color: .neuromodGreen, label: "Positive")
              self.legendItem(color: .precisionRed, label: "Negative")
              self.legendItem(color: .thresholdBlue, label: "Neutral")
              self.legendItem(color: .errorYellow, label: "Overwhelm")
              self.legendItem(color: .workspacePurple, label: "Transcendent")
            }
          }
          .padding(.horizontal, APGISpacing.md)

          // Chart
          self.phaseSpaceChart
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(APGISpacing.md)

          // Instructions
          Text("Click a node to view detailed parameter breakdown.")
            .font(APGITypography.micro)
            .foregroundColor(.inactiveSlate)
            .padding(.bottom, APGISpacing.sm)

          // State Library
          self.stateLibrary
            .frame(height: 200)
            .background(Color.darkNavy)
        }
        .frame(minWidth: 500)

        // Right side - State Details
        VStack {
          if let state = selectedState {
            self.stateDetailsView(state: state)
          } else {
            self.emptyStateDetails
          }
        }
        .frame(minWidth: 400, maxWidth: .infinity)
        .background(Color.spaceBlack)
      }
    .navigationTitle("Psychological States Visualization")
    .onAppear {
      self.stateModel.states.sort { $0.name < $1.name }
    }
  }

  // MARK: - Phase Space Chart

  private var phaseSpaceChart: some View {
    GeometryReader { geometry in
      ZStack {
        // Grid lines and quadrant labels
        self.quadrantOverlay(size: geometry.size)

        // Data points
        ForEach(self.stateModel.states, id: \.id) { state in
          let position = self.calculatePosition(for: state, in: geometry.size)
          let color = self.colorForState(state)
          let isSelected = self.selectedState?.id == state.id
          let isHovered = self.hoveredStateId == state.id

          Circle()
            .fill(color)
            .frame(
              width: isSelected ? self.pointSize * 2 : self.pointSize,
              height: isSelected ? self.pointSize * 2 : self.pointSize
            )
            .overlay(
              Circle()
                .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
            )
            .scaleEffect(isHovered ? 1.2 : 1.0)
            .position(position)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .accessibleTap(
              action: { self.selectedState = state },
              accessibilityLabel: "Select \(state.name) state",
              accessibilityHint: "View detailed information about \(state.name) psychological state"
            )
            .onHover { hovering in
              self.hoveredStateId = hovering ? state.id : nil
            }
        }
      }
    }
  }

  private func quadrantOverlay(size: CGSize) -> some View {
    ZStack {
      // Grid lines
      Path { path in
        // Vertical center line
        path.move(to: CGPoint(x: size.width / 2, y: 0))
        path.addLine(to: CGPoint(x: size.width / 2, y: size.height))

        // Horizontal center line
        path.move(to: CGPoint(x: 0, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
      }
      .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

      // Quadrant labels
      VStack {
        HStack {
          self.quadrantLabel(
            "HIGH THRESHOLD / BLOCKED\n(Stoic, Bored, Depressed)", alignment: .leading)
          Spacer()
          self.quadrantLabel("HIGH PRECISION / REACTIVE\n(Flow, Fear, Anger)", alignment: .trailing)
        }
        Spacer()
        HStack {
          self.quadrantLabel("LOW PRECISION / REACTIVE\n(Anxiety, Chaos)", alignment: .leading)
          Spacer()
          self.quadrantLabel("LOW THRESHOLD / BLOCKED\n(Calm, Relaxed)", alignment: .trailing)
        }
      }
      .padding()

      // Axis labels
      VStack {
        Text("Illustrative attention (θ)")
          .font(.caption)
          .foregroundColor(.secondary)
        Spacer()
        HStack {
          Text("Net Precision (Π)")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
      }
      .padding()
    }
  }

  private func quadrantLabel(_ text: String, alignment: Alignment) -> some View {
    Text(text)
      .font(.caption2)
      .foregroundColor(.secondary)
      .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
      .frame(maxWidth: 150, alignment: alignment)
  }

  // MARK: - State Library

  private var stateLibrary: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("State Library")
        .font(.headline)
        .padding(.horizontal)

      // Search bar
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.secondary)
          .padding(.leading, 8)

        TextField("Q Search states...", text: self.$searchText)
          .textFieldStyle(.plain)
          .padding(.vertical, 8)
          .padding(.trailing, 8)
      }
      .background(Color(NSColor.textBackgroundColor))
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.gray.opacity(0.3), lineWidth: 1)
      )
      .padding(.horizontal)

      // State list
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 4) {
          ForEach(self.filteredStates, id: \.id) { state in
            self.stateLibraryItem(state: state)
          }
        }
        .padding(.horizontal)
      }
    }
  }

  private var filteredStates: [PsychologicalState] {
    if self.searchText.isEmpty {
      return self.stateModel.states
    }
    return self.stateModel.states.filter { state in
      state.name.localizedCaseInsensitiveContains(self.searchText)
    }
  }

  private func stateLibraryItem(state: PsychologicalState) -> some View {
    HStack {
      Circle()
        .fill(self.colorForState(state))
        .frame(width: 8, height: 8)

      Text(state.name)
        .font(.caption)
        .foregroundColor(.primary)

      Spacer()

      if state.name.lowercased().contains("flow") {
        Text("OPTIMAL")
          .font(.caption2)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Color.green.opacity(0.2))
          .foregroundColor(.green)
          .cornerRadius(4)
      }
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 8)
    .background(
      self.selectedState?.id == state.id ? AppColors.buttonBackground.opacity(0.1) : Color.clear
    )
    .cornerRadius(6)
    .accessibleTap(
      action: { self.selectedState = state },
      accessibilityLabel: "Select \(state.name) from library",
      accessibilityHint: "Choose \(state.name) to view in the main visualization"
    )
  }

  // MARK: - State Details

  private func stateDetailsView(state: PsychologicalState) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // Header
        HStack {
          Image(systemName: "bolt.fill")
            .foregroundColor(.orange)
            .font(.title2)

          Text(state.name)
            .font(.title.bold())

          Spacer()
        }
        .padding(.horizontal)

        // Metrics
        VStack(alignment: .leading, spacing: 8) {
          Text(self.formatStateMetrics(state))
            .font(.subheadline.monospaced())
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }

        // Parameter Fingerprint (Radar Chart)
        VStack(alignment: .leading, spacing: 12) {
          Text("PARAMETER FINGERPRINT")
            .font(.headline)
            .padding(.horizontal)

          self.radarChart(for: state)
            .frame(height: 250)
            .padding(.horizontal)
        }

        // Description
        VStack(alignment: .leading, spacing: 12) {
          Text("Description")
            .font(.headline)
            .padding(.horizontal)

          Text(state.description)
            .font(.body)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.bottom)
        }
      }
    }
  }

  private var emptyStateDetails: some View {
    VStack(spacing: 20) {
      Spacer()

      Image(systemName: "dot.radiowaves.left.and.right")
        .font(.system(size: 60))
        .foregroundColor(.secondary.opacity(0.5))

      Text("Select a State")
        .font(.title2.bold())
        .foregroundColor(.secondary)

      Text("Click on any node in the phase space to view detailed parameter breakdown")
        .font(.body)
        .foregroundColor(.secondary.opacity(0.7))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Spacer()
    }
  }

  // MARK: - Helper Functions

  private func calculatePosition(for state: PsychologicalState, in size: CGSize) -> CGPoint {
    let padding: CGFloat = 40
    let chartWidth = size.width - (padding * 2)
    let chartHeight = size.height - (padding * 2)

    // Extract precision and threshold values from actual data
    let precision = self.extractPrecisionValue(from: state)
    let threshold = self.extractThresholdValue(from: state)

    // Normalize to 0-1 range based on actual data ranges
    let normalizedPrecision = self.normalizeValue(precision, min: -1, max: 6)
    let normalizedThreshold = self.normalizeValue(threshold, min: -40, max: 20)

    // Convert to coordinates
    let coordX = padding + (normalizedPrecision * chartWidth)
    let coordY = padding + ((1 - normalizedThreshold) * chartHeight)  // Invert Y for traditional coordinates

    return CGPoint(x: coordX, y: coordY)
  }

  private func extractPrecisionValue(from state: PsychologicalState) -> Double {
    // Extract precision from the state's precision profile
    state.parameters.precision.task.value
  }

  private func extractThresholdValue(from state: PsychologicalState) -> Double {
    // Extract threshold adjustment from the state's threshold range
    state.parameters.threshold.adjustment
  }

  private func normalizeValue(_ value: Double, min: Double, max: Double) -> Double {
    let range = max - min
    let normalizedValue = (value - min) / range
    return Swift.max(0.0, Swift.min(1.0, normalizedValue))
  }

  private func colorForState(_ state: PsychologicalState) -> Color {
    // Determine color based on state characteristics using actual data
    let precision = self.extractPrecisionValue(from: state)
    let threshold = self.extractThresholdValue(from: state)

    // Flow state and similar positive states: high precision, moderate negative threshold
    if precision > 3.0, threshold > -25, threshold < -5 {
      return .green  // Positive states (like Flow, Joy)
    }
    // Anxiety, Fear, Anger: high precision, very negative threshold
    else if precision > 3.5, threshold <= -25 {
      return .red  // Negative states (like Anxiety, Fear)
    }
    // Overwhelm, chaotic states: very high precision, neutral threshold
    else if precision >= 4.5, abs(threshold) < 10 {
      return .orange  // Overwhelm/chaotic states
    }
    // Awe, transcendent states: high precision, very negative threshold
    else if precision > 3.5, threshold <= -20, state.name.contains("Awe") {
      return .purple  // Transcendent states
    } else {
      return .blue  // Neutral or other states
    }
  }

  private func legendItem(color: Color, label: String) -> some View {
    HStack(spacing: 4) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private func formatStateMetrics(_ state: PsychologicalState) -> String {
    let precision = self.extractPrecisionValue(from: state)
    let threshold = self.extractThresholdValue(from: state)

    return "Π_task > \(String(format: "%.1f", precision))σ | "
      + "θ_i \(threshold > 0 ? "+" : "")\(String(format: "%.0f", threshold))%"
  }

  private func radarChart(for state: PsychologicalState) -> some View {
    // Enhanced radar chart with actual parameter data
    RadarChartView(state: state)
  }
}

// MARK: - Radar Chart View

struct RadarChartView: View {
  let state: PsychologicalState

  private struct Parameter {
    let name: String
    let value: Double
    let key: String
  }

  private let parameters: [Parameter] = [
    Parameter(name: "Ext. Precision", value: 0.8, key: "precision"),
    Parameter(name: "Reactivity", value: 0.6, key: "reactivity"),
    Parameter(name: "Illustrative body-signal attention", value: 0.4, key: "somaticBias"),
    Parameter(name: "Focus Stability", value: 0.9, key: "focus"),
    Parameter(name: "Cognitive Load", value: 0.3, key: "cognitive")
  ]

  var body: some View {
    GeometryReader { geometry in
      let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
      let radius = min(geometry.size.width, geometry.size.height) / 2 - 40

      ZStack {
        // Background grid
        self.radarGrid(center: center, radius: radius)

        // Data polygon
        self.radarData(center: center, radius: radius)

        // Labels
        self.radarLabels(center: center, radius: radius)
      }
    }
  }

  private func radarGrid(center: CGPoint, radius: CGFloat) -> some View {
    ZStack {
      // Concentric pentagons
      ForEach(1...5, id: \.self) { level in
        Path { path in
          let levelRadius = radius * CGFloat(level) / 5
          for index in 0..<5 {
            let angle = Double(index) * 2 * .pi / 5 - .pi / 2
            let pointX = center.x + levelRadius * cos(angle)
            let pointY = center.y + levelRadius * sin(angle)

            if index == 0 {
              path.move(to: CGPoint(x: pointX, y: pointY))
            } else {
              path.addLine(to: CGPoint(x: pointX, y: pointY))
            }
          }
          path.closeSubpath()
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
      }

      // Spokes
      ForEach(0..<5, id: \.self) { index in
        let angle = Double(index) * 2 * .pi / 5 - .pi / 2
        let spokeX = center.x + radius * cos(angle)
        let spokeY = center.y + radius * sin(angle)

        Path { path in
          path.move(to: center)
          path.addLine(to: CGPoint(x: spokeX, y: spokeY))
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
      }
    }
  }

  private func radarData(center: CGPoint, radius: CGFloat) -> some View {
    Path { path in
      for (index, param) in self.parameters.enumerated() {
        let angle = Double(index) * 2 * .pi / 5 - .pi / 2
        let value = self.extractParameterValue(for: param.key, from: self.state)
        let distance = radius * CGFloat(value)
        let dataX = center.x + distance * cos(angle)
        let dataY = center.y + distance * sin(angle)

        if index == 0 {
          path.move(to: CGPoint(x: dataX, y: dataY))
        } else {
          path.addLine(to: CGPoint(x: dataX, y: dataY))
        }
      }
      path.closeSubpath()
    }
    .fill(Color.orange.opacity(0.3))
    .stroke(Color.orange, lineWidth: 2)
  }

  private func radarLabels(center: CGPoint, radius: CGFloat) -> some View {
    ForEach(Array(self.parameters.enumerated()), id: \.offset) { index, param in
      let angle = Double(index) * 2 * .pi / 5 - .pi / 2
      let labelRadius = radius + 20
      let labelX = center.x + labelRadius * cos(angle)
      let labelY = center.y + labelRadius * sin(angle)

      Text(param.name)
        .font(.caption2)
        .foregroundColor(.secondary)
        .position(CGPoint(x: labelX, y: labelY))
    }
  }

  private func extractParameterValue(for key: String, from state: PsychologicalState) -> Double {
    switch key {
    case "precision":
      return self.normalizeValue(state.parameters.precision.task.value, min: -1, max: 6)
    case "reactivity":
      // Calculate reactivity based on precision difference between task and distractor
      let taskPrecision = state.parameters.precision.task.value
      let distractorPrecision = state.parameters.precision.distractor.value
      let reactivity = abs(taskPrecision - distractorPrecision)
      return self.normalizeValue(reactivity, min: 0, max: 5)
    case "somaticBias":
      // Use somatic bias range average
      let biasAvg = (state.parameters.somaticBias.min + state.parameters.somaticBias.max) / 2.0
      return self.normalizeValue(biasAvg, min: 0.5, max: 2.5)
    case "focus":
      // Focus stability based on threshold variance (inverse)
      let variance = state.parameters.threshold.variance
      return Swift.max(0.0, 1.0 - self.normalizeValue(variance, min: 0, max: 50))
    case "cognitive":
      // Cognitive load based on prediction error magnitude
      let errorValue = self.extractErrorMagnitude(from: state)
      return self.normalizeValue(errorValue, min: 0, max: 15)
    default:
      return 0.5
    }
  }

  private func extractErrorMagnitude(from state: PsychologicalState) -> Double {
    // Extract a meaningful numeric value from prediction error
    let accuracy = state.parameters.predictionError.accuracy

    switch accuracy.unit {
    case .accuracy:
      // Convert accuracy to error (100 - accuracy)
      return 100.0 - accuracy.average
    case .sigma:
      return accuracy.average
    case .percentage:
      return accuracy.average
    case .ratio:
      return accuracy.average
    default:
      return accuracy.average
    }
  }

  private func normalizeValue(_ value: Double, min: Double, max: Double) -> Double {
    let range = max - min
    let normalizedValue = (value - min) / range
    return Swift.max(0.0, Swift.min(1.0, normalizedValue))
  }
}

#Preview {
  PsychologicalStatesVisualizationView()
    .frame(width: 1200, height: 800)
}
