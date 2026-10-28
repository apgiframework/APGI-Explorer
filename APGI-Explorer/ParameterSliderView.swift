import SwiftUI

struct ParameterSliderView: View {
  let state: PsychologicalState
  let onParameterChange: (String, Double) -> Void

  @State private var predictionError: Double
  @State private var precision: Double
  @State private var threshold: Double
  @State private var somaticBias: Double

  init(state: PsychologicalState, onParameterChange: @escaping (String, Double) -> Void) {
    self.state = state
    self.onParameterChange = onParameterChange

    // Initialize with current state values
    _predictionError = State(initialValue: Double(state.parameters.predictionError.accuracy.min))
    if case .veryHigh(let value) = state.parameters.precision.task {
      _precision = State(initialValue: value)
    } else {
      _precision = State(initialValue: 2.0)
    }
    _threshold = State(initialValue: abs(Double(state.parameters.threshold.adjustment)))
    _somaticBias = State(initialValue: state.parameters.somaticBias.max)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Adjust Parameters")
        .font(.headline)

      ParameterSlider(
        name: "Illustrative reactivity",
        value: self.$predictionError,
        range: 0...100,
        step: 1
      ) { value in
        self.onParameterChange("predictionError", value)
      }

      ParameterSlider(
        name: "Illustrative information prioritisation",
        value: self.$precision,
        range: 0...5,
        step: 0.1
      ) { value in
        self.onParameterChange("precision", value)
      }

      ParameterSlider(
        name: "Illustrative attention",
        value: self.$threshold,
        range: 0...100,
        step: 1
      ) { value in
        self.onParameterChange("threshold", value)
      }

      ParameterSlider(
        name: "Illustrative body-signal attention",
        value: self.$somaticBias,
        range: 0...3,
        step: 0.1
      ) { value in
        self.onParameterChange("somaticBias", value)
      }
    }
    .padding()
    .background(Color(.windowBackgroundColor))
    .cornerRadius(10)
  }
}

struct ParameterSlider: View {
  let name: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double
  let onValueChanged: (Double) -> Void

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(self.name)
          .font(.subheadline)
        Spacer()
        Text(String(format: "%.1f", self.value))
          .font(.caption.monospacedDigit())
          .foregroundColor(.secondary)
      }

      Slider(
        value: self.$value,
        in: self.range,
        step: self.step
      ) {
        Text(self.name)
      } onEditingChanged: { editing in
        if !editing {
          self.onValueChanged(self.value)
        }
      }
    }
  }
}
