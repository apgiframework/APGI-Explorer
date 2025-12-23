// StateComparisonRadar.swift
import SwiftUI
import Charts

struct StateComparisonRadar: View {
    let primary: PsychologicalState
    let comparisons: [PsychologicalState]
    
    private var allStates: [PsychologicalState] {
        [primary] + comparisons
    }
    
    private func valueForState(_ state: PsychologicalState, parameter: String) -> Double {
        switch parameter {
        case "Prediction Error": return Double(state.parameters.predictionError.accuracy.min) / 100.0
        case "Precision": 
            if case let .veryHigh(value) = state.parameters.precision.task {
                return value / 5.0
            }
            return 0.5
        case "Threshold": return abs(state.parameters.threshold.adjustment) / 100.0
        case "Somatic Bias": return state.parameters.somaticBias.max / 3.0
        default: return 0.5
        }
    }
    
    var body: some View {
        VStack {
            Text("State Comparison")
                .font(.headline)
            
            Chart {
                ForEach(allStates) { state in
                    ForEach(["Prediction Error", "Precision", "Threshold", "Somatic Bias"], id: \.self) { parameter in
                        LineMark(
                            x: .value("Parameter", parameter),
                            y: .value("Value", valueForState(state, parameter: parameter))
                        )
                        .foregroundStyle(by: .value("State", state.id == primary.id ? "Current" : "Comparison \(state.id)"))
                        .interpolationMethod(.cardinal)
                        .lineStyle(StrokeStyle(lineWidth: state.id == primary.id ? 3 : 2))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(preset: .aligned, position: .bottom) { value in
                    AxisValueLabel {
                        Text(value.as(String.self) ?? "")
                            .font(.caption)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(.visible)
        }
    }
}