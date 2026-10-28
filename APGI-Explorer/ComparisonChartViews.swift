import Charts
import SwiftUI

// MARK: - Radar Comparison Chart

/// Shared canvas coordinates keep grid, axes, data and labels aligned.
nonisolated struct RadarComparisonGeometry {
  let size: CGSize
  let center: CGPoint
  let radius: CGFloat
  let sideLabelWidth: CGFloat

  init(size: CGSize) {
    self.size = size
    center = CGPoint(x: size.width / 2, y: size.height / 2)
    sideLabelWidth = min(160, size.width * 0.22)
    radius = max(0, min((size.width - sideLabelWidth * 2 - 48) / 2, (size.height - 100) / 2))
  }

  func point(axis: Int, score: Double) -> CGPoint {
    let angle = Double(axis) * .pi / 2 - .pi / 2
    let distance = radius * CGFloat(score.isFinite ? min(max(score, 0), 100) / 100 : 0)
    return CGPoint(x: center.x + distance * cos(angle), y: center.y + distance * sin(angle))
  }

  func labelFrame(axis: Int) -> CGRect {
    let verticalWidth = min(260, size.width - 32)
    switch axis {
    case 0:
      return CGRect(x: center.x - verticalWidth / 2, y: center.y - radius - 50, width: verticalWidth, height: 44)
    case 1:
      return CGRect(x: center.x + radius + 16, y: center.y - 24, width: sideLabelWidth, height: 48)
    case 2:
      return CGRect(x: center.x - verticalWidth / 2, y: center.y + radius + 6, width: verticalWidth, height: 44)
    default:
      return CGRect(x: center.x - radius - 16 - sideLabelWidth, y: center.y - 24, width: sideLabelWidth, height: 48)
    }
  }
}

struct RadarComparisonChart: View {
  let profile1: QuizProfile
  let profile2: QuizProfile

  private var apgiProfile1: APGIProfile {
    QuizModel.calculateAPGIProfile(from: self.profile1.results)
  }

  private var apgiProfile2: APGIProfile {
    QuizModel.calculateAPGIProfile(from: self.profile2.results)
  }

  /// Real data from profiles
  private var data: [RadarData] {
    let categories = [
      "Reported reactivity to the unexpected",
      "Reported information prioritisation",
      "Reported attentional threshold",
      "Reported body-signal attention"
    ]

    return categories.enumerated().map { index, category in
      let value1: Double
      let value2: Double

      switch index {
      case 0:  // Epsilon
        value1 = self.apgiProfile1.epsilon
        value2 = self.apgiProfile2.epsilon
      case 1:  // Precision
        value1 = self.apgiProfile1.precision
        value2 = self.apgiProfile2.precision
      case 2:  // Threshold
        value1 = self.apgiProfile1.threshold
        value2 = self.apgiProfile2.threshold
      case 3:  // Reported body-signal attention
        value1 = self.apgiProfile1.somaticBias
        value2 = self.apgiProfile2.somaticBias
      default:
        value1 = 50
        value2 = 50
      }

      return RadarData(
        category: category,
        value1: value1,
        value2: value2
      )
    }
  }

  var body: some View {
    VStack(spacing: 16) {
      GeometryReader { proxy in
        let geometry = RadarComparisonGeometry(size: proxy.size)
        ZStack {
          ForEach(1...5, id: \.self) { level in
            Circle()
              .stroke(Color.gray.opacity(0.15), lineWidth: 1)
              .frame(width: geometry.radius * CGFloat(level) * 0.4,
                     height: geometry.radius * CGFloat(level) * 0.4)
              .position(geometry.center)
          }

          ForEach(0..<4, id: \.self) { axis in
            Path { path in
              path.move(to: geometry.center)
              path.addLine(to: geometry.point(axis: axis, score: 100))
            }
            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
          }

          profilePolygon(values: data.map(\.value1), geometry: geometry, color: .blue)
          profilePolygon(values: data.map(\.value2), geometry: geometry, color: .orange)

          ForEach(Array(data.enumerated()), id: \.offset) { axis, item in
            Circle().fill(Color.blue).frame(width: 8, height: 8)
              .position(geometry.point(axis: axis, score: item.value1))
            Circle().fill(Color.orange).frame(width: 8, height: 8)
              .position(geometry.point(axis: axis, score: item.value2))

            let labelFrame = geometry.labelFrame(axis: axis)
            Text(item.category)
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(.primary)
              .multilineTextAlignment(axis == 1 ? .leading : axis == 3 ? .trailing : .center)
              .frame(width: labelFrame.width, height: labelFrame.height)
              .position(x: labelFrame.midX, y: labelFrame.midY)
          }
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
      }

      HStack(spacing: 30) {
        legendItem(color: .blue, label: profile1.name)
        legendItem(color: .orange, label: profile2.name)
      }
    }
    .padding(20)
  }

  private func profilePolygon(values: [Double], geometry: RadarComparisonGeometry, color: Color) -> some View {
    let polygon = Path { path in
      for (axis, value) in values.enumerated() {
        let point = geometry.point(axis: axis, score: value)
        if axis == 0 { path.move(to: point) } else { path.addLine(to: point) }
      }
      path.closeSubpath()
    }
    return polygon.fill(color.opacity(0.15))
      .overlay(polygon.stroke(color.opacity(0.8), lineWidth: 2.5))
  }

  private func legendItem(color: Color, label: String) -> some View {
    HStack(spacing: 8) {
      Circle().fill(color).frame(width: 12, height: 12)
      Text(label)
        .font(.system(size: 13, weight: .medium))
        .lineLimit(1)
        .foregroundStyle(.primary)
    }
  }
}

// MARK: - Bar Comparison Chart

struct BarComparisonChart: View {
  let profile1: QuizProfile
  let profile2: QuizProfile

  private var apgiProfile1: APGIProfile {
    QuizModel.calculateAPGIProfile(from: self.profile1.results)
  }

  private var apgiProfile2: APGIProfile {
    QuizModel.calculateAPGIProfile(from: self.profile2.results)
  }

  /// Real data from profiles
  private var data: [BarData] {
    [
      ("Reported reactivity to the unexpected", Int(self.apgiProfile1.epsilon), Int(self.apgiProfile2.epsilon)),
      ("Reported information prioritisation", Int(self.apgiProfile1.precision), Int(self.apgiProfile2.precision)),
      ("Reported attentional threshold", Int(self.apgiProfile1.threshold), Int(self.apgiProfile2.threshold)),
      ("Reported body-signal attention", Int(self.apgiProfile1.somaticBias), Int(self.apgiProfile2.somaticBias))
    ].map { BarData(category: $0.0, value1: $0.1, value2: $0.2) }
  }

  var body: some View {
    VStack {
      Chart {
        ForEach(self.data) { item in
          // Profile 1 bars
          BarMark(
            x: .value("Category", item.category),
            y: .value("Value", item.value1)
          )
          .foregroundStyle(Color.blue.gradient)
          .position(by: .value("Profile", self.profile1.name))

          // Profile 2 bars
          BarMark(
            x: .value("Category", item.category),
            y: .value("Value", item.value2)
          )
          .foregroundStyle(Color.orange.gradient)
          .position(by: .value("Profile", self.profile2.name))
        }
      }
      .chartXAxis {
        AxisMarks(position: .bottom) { _ in
          AxisValueLabel()
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading) { _ in
          AxisTick()
          AxisValueLabel()
        }
      }
      .chartLegend(position: .top, alignment: .center) {
        HStack(spacing: 20) {
          ForEach([(Color.blue, self.profile1.name), (Color.orange, self.profile2.name)], id: \.1) { color, label in
            HStack(spacing: 6) {
              Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)

              Text(label)
                .font(.caption)
            }
          }
        }
        .padding(.top, 8)
      }
      .chartYScale(domain: 0...100)
      .frame(height: 300)
      .padding()
    }
  }
}

// MARK: - Line Comparison Chart

struct LineComparisonChart: View {
  let profile1: QuizProfile
  let profile2: QuizProfile

  private var apgiProfile1: APGIProfile {
    QuizModel.calculateAPGIProfile(from: self.profile1.results)
  }

  private var apgiProfile2: APGIProfile {
    QuizModel.calculateAPGIProfile(from: self.profile2.results)
  }

  /// Real data from profiles - showing parameter progression
  private var data: [LineData] {
    let parameters = [
      "Reported reactivity to the unexpected",
      "Reported information prioritisation",
      "Reported attentional threshold",
      "Reported body-signal attention"
    ]
    let values1 = [
      apgiProfile1.epsilon, self.apgiProfile1.precision, self.apgiProfile1.threshold,
      self.apgiProfile1.somaticBias
    ]
    let values2 = [
      apgiProfile2.epsilon, self.apgiProfile2.precision, self.apgiProfile2.threshold,
      self.apgiProfile2.somaticBias
    ]

    return parameters.enumerated().map { index, parameter in
      LineData(
        period: parameter,
        value1: Int(values1[index]),
        value2: Int(values2[index])
      )
    }
  }

  var body: some View {
    VStack {
      Chart {
        // Profile 1 line
        ForEach(self.data) { item in
          LineMark(
            x: .value("Period", item.period),
            y: .value("Score", item.value1)
          )
          .foregroundStyle(Color.blue.gradient)
          .symbol(Circle().strokeBorder(lineWidth: 1))
          .interpolationMethod(.catmullRom)
        }
        .foregroundStyle(by: .value("Profile", self.profile1.name))
        .lineStyle(StrokeStyle(lineWidth: 3))

        // Profile 2 line
        ForEach(self.data) { item in
          LineMark(
            x: .value("Period", item.period),
            y: .value("Score", item.value2)
          )
          .foregroundStyle(Color.orange.gradient)
          .symbol(Circle().strokeBorder(lineWidth: 1))
          .interpolationMethod(.catmullRom)
        }
        .foregroundStyle(by: .value("Profile", self.profile2.name))
        .lineStyle(StrokeStyle(lineWidth: 3))
      }
      .chartXAxis {
        AxisMarks(position: .bottom) { _ in
          AxisValueLabel()
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading) { _ in
          AxisTick()
          AxisValueLabel()
        }
      }
      .chartLegend(position: .top, alignment: .center) {
        HStack(spacing: 20) {
          ForEach([(Color.blue, self.profile1.name), (Color.orange, self.profile2.name)], id: \.1) { color, label in
            HStack(spacing: 6) {
              Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)

              Text(label)
                .font(.caption)
            }
          }
        }
        .padding(.top, 8)
      }
      .chartYScale(domain: 0...100)
      .frame(height: 300)
      .padding()
    }
  }
}

// MARK: - Comparison Table View

struct ComparisonTableView: View {
  let profile1: QuizProfile
  let profile2: QuizProfile

  private var apgiProfile1: APGIProfile {
    QuizModel.calculateAPGIProfile(from: self.profile1.results)
  }

  private var apgiProfile2: APGIProfile {
    QuizModel.calculateAPGIProfile(from: self.profile2.results)
  }

  private var tableData: [[String]] {
    [
      ["Parameter", self.profile1.name, self.profile2.name],
      [
        "Reported reactivity to the unexpected", String(format: "%.2f", self.apgiProfile1.epsilon),
        String(format: "%.2f", self.apgiProfile2.epsilon)
      ],
      [
        "Reported information prioritisation", String(format: "%.2f", self.apgiProfile1.precision),
        String(format: "%.2f", self.apgiProfile2.precision)
      ],
      [
        "Reported attentional threshold", String(format: "%.2f", self.apgiProfile1.threshold),
        String(format: "%.2f", self.apgiProfile2.threshold)
      ],
      [
        "Reported body-signal attention", String(format: "%.2f", self.apgiProfile1.somaticBias),
        String(format: "%.2f", self.apgiProfile2.somaticBias)
      ]
    ]
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack(spacing: 0) {
        ForEach(self.tableData[0], id: \.self) { header in
          Text(header)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
        }
      }
      .cornerRadius(8)

      // Data rows
      ForEach(Array(self.tableData.dropFirst().enumerated()), id: \.offset) { index, row in
        HStack(spacing: 0) {
          ForEach(Array(row.enumerated()), id: \.offset) { _, value in
            Text(value)
              .font(.body)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 10)
              .background(index % 2 == 0 ? Color.gray.opacity(0.1) : Color.clear)
          }
        }
      }
    }
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    )
    .padding()
  }
}
