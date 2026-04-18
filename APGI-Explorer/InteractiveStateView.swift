import SwiftUI

// MARK: - Interactive State Explorer

struct InteractiveStateView: View {
  let state: PsychologicalState
  @ObservedObject var stateModel: StateModel
  @ObservedObject var transitionModel: StateTransitionModel
  @Environment(\.appDependencies) private var dependencies

  private var analytics: AnalyticsService {
    self.dependencies.getAnalyticsService()
  }

  @State private var comparisonStates: [Int] = []
  @State private var nearbyStates: [PsychologicalState] = []
  @State private var showingTransitions = false

  init(
    state: PsychologicalState,
    stateModel: StateModel,
    transitionModel: StateTransitionModel
  ) {
    self.state = state
    self.stateModel = stateModel
    self.transitionModel = transitionModel
  }

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 20) {
          // State header
          self.stateHeaderView

          // Radar chart comparing this state to others
          StateComparisonRadar(
            primary: self.state,
            comparisons: self.comparisonStates.compactMap { self.getState($0) }
          )
          .frame(height: 300)
          .padding()

          // Interactive parameter explorer
          ParameterSliderView(state: self.state) { parameter, value in
            Task {
              await self.findStatesWithSimilarParameters(changing: parameter, to: value)
            }
          }
          .padding()

          // Nearby states visualization
          if self.stateModel.isLoadingSimilarStates {
            LoadingIndicator(message: "Finding similar states...", size: .medium)
              .padding()
          } else if !self.nearbyStates.isEmpty {
            self.nearbyStatesView
          } else if !self.stateModel.isLoadingSimilarStates {
            EmptyStateView.noSimilarStates
              .padding()
          }

          // Transition pathways
          self.transitionSection

          Spacer()
        }
        .padding()
      }
      .refreshable {
        await self.loadDefaultComparisons()
      }
      .overlay {
        if self.stateModel.isLoadingStates {
          LoadingOverlay(message: "Loading states...")
        }
      }
      .navigationTitle("State Explorer")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
      #endif
    }
    .onAppear {
      self.analytics.track(event: .stateViewed(id: self.state.id, name: self.state.name))
      Task {
        await self.loadDefaultComparisons()
      }
    }
  }

  private var nearbyPreviewStates: [PsychologicalState] {
    Array(self.nearbyStates.prefix(6))
  }

  // MARK: - Subviews

  private var stateHeaderView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(self.state.name)
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(AppColors.primaryText)

      Text(self.state.description)
        .font(.subheadline)
        .foregroundColor(AppColors.secondaryText)

      // Parameter summary
      VStack(alignment: .leading, spacing: 4) {
        self.parameterSummaryRow("Prediction Error", self.state.predictionError)
        self.parameterSummaryRow("Precision", self.state.precision)
        self.parameterSummaryRow("Threshold", self.state.threshold)
        self.parameterSummaryRow("Somatic Bias", self.state.somaticBias)
      }
      .font(.caption)
      .foregroundColor(AppColors.secondaryText)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(AppColors.cardBackground)
    .cornerRadius(12)
  }

  private func parameterSummaryRow(_ title: String, _ value: String) -> some View {
    let titleText = Text("\(title):").fontWeight(.medium)
    let valueText = Text(value)

    return HStack {
      titleText
      valueText
      Spacer()
    }
  }

  private var nearbyStatesView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Similar States")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(AppColors.primaryText)

      LazyVGrid(
        columns: [
          GridItem(.flexible()),
          GridItem(.flexible()),
        ], spacing: 12
      ) {
        ForEach(self.nearbyPreviewStates) { nearbyState in
          NavigationLink(
            destination: InteractiveStateView(
              state: nearbyState,
              stateModel: self.stateModel,
              transitionModel: self.transitionModel
            )
          ) {
            VStack(alignment: .leading, spacing: 4) {
              Text(nearbyState.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(AppColors.primaryText)

              Text(nearbyState.description)
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
                .lineLimit(2)

              Text("ID: \(nearbyState.id)")
                .font(.caption2)
                .foregroundColor(AppColors.tertiaryText)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.similarityHighlight)
            .cornerRadius(8)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
    }
    .padding()
    .background(AppColors.secondaryBackground)
    .cornerRadius(12)
  }

  private var transitionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Common Transitions")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(AppColors.primaryText)

        Spacer()

        Button(self.showingTransitions ? "Hide" : "Show") {
          self.showingTransitions.toggle()
        }
        .font(.caption)
        .foregroundColor(AppColors.info)
      }

      if self.showingTransitions {
        if self.transitionsForState.isEmpty {
          Text("No transition data available for this state.")
            .font(.caption)
            .foregroundColor(AppColors.secondaryText)
        } else {
          ForEach(self.transitionsForState) { transition in
            TransitionView(transition: transition, states: self.stateModel.states)
            Divider()
          }
        }
      }
    }
    .padding()
    .background(AppColors.secondaryBackground)
    .cornerRadius(12)
  }

  // MARK: - Helper Methods

  private var transitionsForState: [StateTransitionModel.Transition] {
    self.transitionModel.possibleTransitions(from: self.state.id)
  }

  private func loadDefaultComparisons() async {
    // Load some default comparison states based on similarity
    let similarStates = await findSimilarStates(to: state, limit: 3)
    self.comparisonStates = similarStates.map(\.id)
  }

  private func getState(_ id: Int) -> PsychologicalState? {
    self.stateModel.states.first { $0.id == id }
  }

  private func findSimilarStates(to state: PsychologicalState, limit: Int = 5) async
    -> [PsychologicalState]
  {
    await self.stateModel.findSimilarStates(to: state, limit: limit)
  }

  private func findStatesWithSimilarParameters(changing parameter: String, to value: Double) async {
    let allStates = self.stateModel.states

    // This is a simplified version - in a real implementation, you would
    // parse the parameter values more accurately and calculate distances
    let filteredStates =
      allStates
      .filter { $0.id != self.state.id }
      .map {
        ($0, self.calculateParameterDistance(state: $0, parameter: parameter, targetValue: value))
      }
      .filter { $0.1 < 2.0 }  // Filter by distance threshold
      .sorted { $0.1 < $1.1 }
      .prefix(8)
      .map(\.0)

    await MainActor.run {
      self.nearbyStates = filteredStates
    }
  }

  private func calculateParameterDistance(
    state: PsychologicalState, parameter: String, targetValue: Double
  ) -> Double {
    let currentValue: Double

    switch parameter {
    case "predictionError":
      currentValue = state.parameters.predictionError.accuracy.average
    case "precision":
      currentValue = state.parameters.precision.task.value
    case "threshold":
      currentValue = state.parameters.threshold.adjustment
    case "somaticBias":
      currentValue = state.parameters.somaticBias.average
    default:
      return Double.infinity
    }

    return abs(currentValue - targetValue)
  }
}

// MARK: - Preview

struct InteractiveStateView_Previews: PreviewProvider {
  static var previews: some View {
    if let sampleState = PsychologicalState.exampleStates.first {
      InteractiveStateView(
        state: sampleState,
        stateModel: StateModel(),
        transitionModel: StateTransitionModel()
      )
    } else {
      Text("No sample states available")
    }
  }
}
