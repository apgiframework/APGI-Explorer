// ParameterSliderView.swift
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
        if case let .veryHigh(value) = state.parameters.precision.task {
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
                name: "Prediction Error",
                value: $predictionError,
                range: 0...100,
                step: 1
            ) { value in
                onParameterChange("predictionError", value)
            }

            ParameterSlider(
                name: "Precision",
                value: $precision,
                range: 0...5,
                step: 0.1
            ) { value in
                onParameterChange("precision", value)
            }

            ParameterSlider(
                name: "Threshold",
                value: $threshold,
                range: 0...100,
                step: 1
            ) { value in
                onParameterChange("threshold", value)
            }

            ParameterSlider(
                name: "Somatic Bias",
                value: $somaticBias,
                range: 0...3,
                step: 0.1
            ) { value in
                onParameterChange("somaticBias", value)
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
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f", value))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            Slider(
                value: $value,
                in: range,
                step: step
            ) {
                Text(name)
            } onEditingChanged: { editing in
                if !editing {
                    onValueChanged(value)
                }
            }
        }
    }
}
