import Charts
import SwiftUI

struct StateComparisonRadar: View {
  let primary: PsychologicalState
  let comparisons: [PsychologicalState]

  private var allStates: [PsychologicalState] {
    [self.primary] + self.comparisons
  }

  private func valueForState(_ state: PsychologicalState, parameter: String) -> Double {
    switch parameter {
    case "Illustrative reactivity": return Double(state.parameters.predictionError.accuracy.min) / 100.0
    case "Illustrative information prioritisation":
      if case .veryHigh(let value) = state.parameters.precision.task {
        return value / 5.0
      }
      return 0.5
    case "Illustrative attention": return abs(state.parameters.threshold.adjustment) / 100.0
    case "Illustrative body-signal attention": return state.parameters.somaticBias.max / 3.0
    default: return 0.5
    }
  }

  var body: some View {
    VStack {
      Text("State Comparison")
        .font(.headline)

      Chart {
        ForEach(self.allStates) { state in
          ForEach(
            ["Illustrative reactivity", "Illustrative information prioritisation",
             "Illustrative attention", "Illustrative body-signal attention"],
            id: \.self
          ) { parameter in
            LineMark(
              x: .value("Parameter", parameter),
              y: .value("Value", self.valueForState(state, parameter: parameter))
            )
            .foregroundStyle(
              by: .value(
                "State", state.id == self.primary.id ? "Current" : "Comparison \(state.id)")
            )
            .interpolationMethod(.cardinal)
            .lineStyle(StrokeStyle(lineWidth: state.id == self.primary.id ? 3 : 2))
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
