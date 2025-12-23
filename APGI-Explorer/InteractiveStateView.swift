import SwiftUI

// MARK: - Interactive State Explorer

struct InteractiveStateView: View {
    let state: PsychologicalState
    @ObservedObject var stateModel: StateModel
    @ObservedObject var transitionModel: StateTransitionModel
    @Environment(\.appDependencies) private var dependencies

    private var analytics: AnalyticsService {
        dependencies.getAnalyticsService()
    }
    
    @State private var comparisonStates: [Int] = []
    @State private var nearbyStates: [PsychologicalState] = []
    @State private var showingTransitions = false
    
    init(state: PsychologicalState, 
         stateModel: StateModel, 
         transitionModel: StateTransitionModel) {
        self.state = state
        self.stateModel = stateModel
        self.transitionModel = transitionModel
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // State header
                    stateHeaderView
                    
                    // Radar chart comparing this state to others
                    StateComparisonRadar(
                        primary: state,
                        comparisons: comparisonStates.compactMap { getState($0) }
                    )
                    .frame(height: 300)
                    .padding()
                    
                    // Interactive parameter explorer
                    ParameterSliderView(state: state) { parameter, value in
                        Task {
                            await findStatesWithSimilarParameters(changing: parameter, to: value)
                        }
                    }
                    .padding()
                    
                    // Nearby states visualization
                    if stateModel.isLoadingSimilarStates {
                        LoadingIndicator(message: "Finding similar states...", size: .medium)
                            .padding()
                    } else if !nearbyStates.isEmpty {
                        nearbyStatesView
                    } else if !stateModel.isLoadingSimilarStates {
                        EmptyStateView.noSimilarStates
                            .padding()
                    }
                    
                    // Transition pathways
                    transitionSection
                    
                    Spacer()
                }
                .padding()
            }
            .refreshable {
                await loadDefaultComparisons()
            }
            .overlay {
                if stateModel.isLoadingStates {
                    LoadingOverlay(message: "Loading states...")
                }
            }
            .navigationTitle("State Explorer")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
        .onAppear {
            analytics.track(event: .stateViewed(id: state.id, name: state.name))
            Task {
                await loadDefaultComparisons()
            }
        }
    }

    private var nearbyPreviewStates: [PsychologicalState] {
        Array(nearbyStates.prefix(6))
    }
    
    // MARK: - Subviews
    
    private var stateHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryText)
            
            Text(state.description)
                .font(.subheadline)
                .foregroundColor(AppColors.secondaryText)
            
            // Parameter summary
            VStack(alignment: .leading, spacing: 4) {
                parameterSummaryRow("Prediction Error", state.predictionError)
                parameterSummaryRow("Precision", state.precision)
                parameterSummaryRow("Threshold", state.threshold)
                parameterSummaryRow("Somatic Bias", state.somaticBias)
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
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(nearbyPreviewStates) { nearbyState in
                    NavigationLink(destination: InteractiveStateView(
                        state: nearbyState,
                        stateModel: stateModel,
                        transitionModel: transitionModel
                    )) {
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
                
                Button(showingTransitions ? "Hide" : "Show") {
                    showingTransitions.toggle()
                }
                .font(.caption)
                .foregroundColor(AppColors.info)
            }
            
            if showingTransitions {
                if transitionsForState.isEmpty {
                    Text("No transition data available for this state.")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                } else {
                    ForEach(transitionsForState) { transition in
                        TransitionView(transition: transition, states: stateModel.states)
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
        transitionModel.possibleTransitions(from: state.id)
    }

    private func loadDefaultComparisons() async {
        // Load some default comparison states based on similarity
        let similarStates = await findSimilarStates(to: state, limit: 3)
        comparisonStates = similarStates.map { $0.id }
    }
    
    private func getState(_ id: Int) -> PsychologicalState? {
        return stateModel.states.first { $0.id == id }
    }
    
    private func findSimilarStates(to state: PsychologicalState, limit: Int = 5) async -> [PsychologicalState] {
        return await stateModel.findSimilarStates(to: state, limit: limit)
    }
    
    private func findStatesWithSimilarParameters(changing parameter: String, to value: Double) async {
        let allStates = stateModel.states
        
        // This is a simplified version - in a real implementation, you would
        // parse the parameter values more accurately and calculate distances
        let filteredStates = allStates
            .filter { $0.id != state.id }
            .map { ($0, calculateParameterDistance(state: $0, parameter: parameter, targetValue: value)) }
            .filter { $0.1 < 2.0 } // Filter by distance threshold
            .sorted { $0.1 < $1.1 }
            .prefix(8)
            .map { $0.0 }
        
        await MainActor.run {
            self.nearbyStates = filteredStates
        }
    }
    
    private func calculateParameterDistance(state: PsychologicalState, parameter: String, targetValue: Double) -> Double {
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
