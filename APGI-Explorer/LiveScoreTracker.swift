import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

struct TrackedParameter {
  let key: String
  let label: String
  let description: String
}

struct LiveScoreTracker: View {
  @ObservedObject var quizModel: QuizModel

  private let trackedParameters: [TrackedParameter] = [
    TrackedParameter(key: "epsilon", label: "ε", description: "Prediction Error"),
    TrackedParameter(key: "precision", label: "π", description: "Precision"),
    TrackedParameter(key: "threshold", label: "θₜ", description: "Threshold"),
    TrackedParameter(key: "somatic", label: "β", description: "Somatic Bias"),
  ]

  var body: some View {
    VStack(spacing: 12) {
      Text("Your Emerging Profile")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)

      SmallRadarChart(profile: self.quizModel.calculatePartialScore())
        .frame(height: 140)
        .padding(.horizontal, 20)

      VStack(spacing: 10) {
        ForEach(self.trackedParameters, id: \.key) { parameter in
          ConfidenceBar(
            parameter: parameter.label,
            confidence: self.quizModel.confidenceLevel(for: parameter.key),
            title: parameter.description
          )
        }
      }

      if let remaining = quizModel.questionsNeededForConfidence() {
        Text("Answer \(remaining) more question\(remaining == 1 ? "" : "s") for high confidence")
          .font(.caption2)
          .foregroundColor(.secondary)
      } else {
        Text("Confidence target reached")
          .font(.caption2)
          .foregroundColor(.green)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(self.panelBackground)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    )
  }

  private var panelBackground: Color {
    #if os(macOS)
      Color(NSColor.windowBackgroundColor)
    #else
      Color(uiColor: .secondarySystemBackground)
    #endif
  }
}

struct ConfidenceBar: View {
  let parameter: String
  let confidence: Double
  let title: String

  private var barColor: Color {
    switch self.parameter {
    case "ε": .orange
    case "π": .green
    case "θₜ": .purple
    case "β": .blue
    default: .gray
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text("\(self.parameter) • \(self.title)")
          .font(.caption)
          .foregroundColor(.secondary)
        Spacer()
        Text("\(Int(self.confidence * 100))%")
          .font(.caption2)
          .fontWeight(.semibold)
      }

      GeometryReader { geometry in
        let width = max(0, min(confidence, 1)) * geometry.size.width
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.gray.opacity(0.2))
          .frame(height: 6)
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .fill(self.barColor)
              .frame(width: width, height: 6),
            alignment: .leading
          )
      }
      .frame(height: 6)
    }
  }
}

struct SmallRadarChart: View {
  let profile: APGIProfile

  private var values: [Double] {
    [
      self.profile.epsilon, self.profile.precision, self.profile.threshold,
      self.profile.somaticBias,
    ]
    .map { max(0, min($0 / 100, 1)) }
  }

  private func makeAngles(count: Int) -> [Double] {
    guard count > 0 else { return [] }
    let step = (2 * .pi) / Double(count)
    return (0..<count).map { Double($0) * step - .pi / 2 }
  }

  private func radarPoints(in rect: CGRect) -> [CGPoint] {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2
    let angles = self.makeAngles(count: self.values.count)

    return zip(angles, self.values).map { angle, value in
      let normalizedValue = max(0, min(value, 1))
      let coordX = center.x + cos(angle) * radius * normalizedValue
      let coordY = center.y + sin(angle) * radius * normalizedValue
      return CGPoint(x: coordX, y: coordY)
    }
  }

  private var panelBackground: Color {
    #if os(macOS)
      Color(NSColor.windowBackgroundColor)
    #else
      Color(uiColor: .secondarySystemBackground)
    #endif
  }

  private func radarPath(in rect: CGRect) -> Path {
    var path = Path()
    let points = self.radarPoints(in: rect)
    for (index, point) in points.enumerated() {
      if index == 0 {
        path.move(to: point)
      } else {
        path.addLine(to: point)
      }
    }
    path.closeSubpath()
    return path
  }

  var body: some View {
    GeometryReader { geometry in
      let rect = CGRect(origin: .zero, size: geometry.size)
      let center = CGPoint(x: rect.midX, y: rect.midY)

      ZStack {
        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
          Circle()
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            .frame(width: rect.width * scale, height: rect.height * scale)
            .position(center)
        }

        self.radarPath(in: rect)
          .fill(Color.blue.opacity(0.3))

        self.radarPath(in: rect)
          .stroke(Color.blue, lineWidth: 1.5)
      }
    }
    .aspectRatio(1, contentMode: .fit)
  }
}
