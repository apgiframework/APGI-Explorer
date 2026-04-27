import Charts
import SwiftUI

// MARK: - Radar Comparison Chart

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
    let categories = ["Epsilon", "Precision", "Threshold", "Somatic Bias"]

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
      case 3:  // Somatic Bias
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
    VStack {
      // Improved radar chart implementation
      ZStack {
        self.backgroundGrid
        self.axisLines
        self.dataPolygons
        self.dataPoints
        self.categoryLabels
      }
      .frame(width: 420, height: 420)

      // Legend with improved styling
      self.legendView
    }
  }

  // MARK: - Computed Properties

  private var backgroundGrid: some View {
    ForEach(1...5, id: \.self) { index in
      Circle()
        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        .frame(width: CGFloat(index) * 60, height: CGFloat(index) * 60)
    }
  }

  private var axisLines: some View {
    ForEach(Array(self.data.enumerated()), id: \.offset) { index, _ in
      let angle = Double(index) * (2 * .pi / 4) - .pi / 2
      Path { path in
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 150 * cos(angle), y: 150 * sin(angle)))
      }
      .stroke(Color.gray.opacity(0.25), lineWidth: 1)
    }
  }

  private var dataPolygons: some View {
    ZStack {
      // Profile 1 filled area
      self.filledProfilePolygon(for: self.data.map(\.value1), color: Color.blue.opacity(0.15))

      // Profile 2 filled area
      self.filledProfilePolygon(for: self.data.map(\.value2), color: Color.orange.opacity(0.15))

      // Profile 1 outline
      self.outlinedProfilePolygon(
        for: self.data.map(\.value1), color: Color.blue, lineWidth: 2.5, opacity: 0.8)

      // Profile 2 outline
      self.outlinedProfilePolygon(
        for: self.data.map(\.value2), color: Color.orange, lineWidth: 2.5, opacity: 0.8)
    }
  }

  private func filledProfilePolygon(for values: [Double], color: Color) -> some View {
    Path { path in
      for (index, value) in values.enumerated() {
        let angle = Double(index) * (2 * .pi / 4) - .pi / 2
        let radius = value * 1.2
        let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))

        if index == 0 {
          path.move(to: point)
        } else {
          path.addLine(to: point)
        }
      }
      path.closeSubpath()
    }
    .fill(color)
  }

  private func outlinedProfilePolygon(
    for values: [Double], color: Color, lineWidth: CGFloat, opacity: Double
  ) -> some View {
    Path { path in
      for (index, value) in values.enumerated() {
        let angle = Double(index) * (2 * .pi / 4) - .pi / 2
        let radius = value * 1.2
        let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))

        if index == 0 {
          path.move(to: point)
        } else {
          path.addLine(to: point)
        }
      }
      path.closeSubpath()
    }
    .stroke(color, lineWidth: lineWidth)
    .opacity(opacity)
  }

  private var dataPoints: some View {
    ForEach(Array(self.data.enumerated()), id: \.offset) { index, item in
      let angle = Double(index) * (2 * .pi / 4) - .pi / 2
      let radius1 = item.value1 * 1.2
      let radius2 = item.value2 * 1.2

      // Data points for profile 1
      Circle()
        .fill(Color.blue)
        .frame(width: 8, height: 8)
        .position(x: radius1 * cos(angle), y: radius1 * sin(angle))
        .shadow(color: .blue.opacity(0.3), radius: 2)

      // Data points for profile 2
      Circle()
        .fill(Color.orange)
        .frame(width: 8, height: 8)
        .position(x: radius2 * cos(angle), y: radius2 * sin(angle))
        .shadow(color: .orange.opacity(0.3), radius: 2)
    }
  }

  private var categoryLabels: some View {
    ForEach(Array(self.data.enumerated()), id: \.offset) { index, item in
      self.categoryLabelForItem(index: index, item: item)
    }
  }

  @ViewBuilder
  private func categoryLabelForItem(index: Int, item: RadarData) -> some View {
    let angle = Double(index) * (2 * .pi / 4) - .pi / 2
    let labelRadius: CGFloat = 180

    let textWidth = CGFloat(item.category.count * 8 + 8)
    let offsetX: CGFloat = labelRadius * cos(angle) > 0 ? 20 : -20
    let offsetY: CGFloat = labelRadius * sin(angle) > 0 ? 10 : -10

    Text(item.category)
      .font(.system(size: 11, weight: .medium))
      .foregroundColor(.primary)
      .position(
        x: labelRadius * cos(angle),
        y: labelRadius * sin(angle)
      )
      .background(
        RoundedRectangle(cornerRadius: 4)
          .fill(Color.white.opacity(0.9))
          .frame(width: textWidth, height: 20)
      )
      .offset(x: offsetX, y: offsetY)
  }

  private var legendView: some View {
    HStack(spacing: 30) {
      self.legendItem(color: .blue, label: self.profile1.name)
      self.legendItem(color: .orange, label: self.profile2.name)
    }
    .padding(.top, 15)
    .padding(.horizontal, 20)
  }

  private func legendItem(color: Color, label: String) -> some View {
    HStack(spacing: 8) {
      Circle()
        .fill(color)
        .frame(width: 12, height: 12)
        .shadow(color: color.opacity(0.3), radius: 1)

      Text(label)
        .font(.system(size: 13, weight: .medium))
        .lineLimit(1)
        .foregroundColor(.primary)
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
      ("Epsilon", Int(self.apgiProfile1.epsilon), Int(self.apgiProfile2.epsilon)),
      ("Precision", Int(self.apgiProfile1.precision), Int(self.apgiProfile2.precision)),
      ("Threshold", Int(self.apgiProfile1.threshold), Int(self.apgiProfile2.threshold)),
      ("Somatic Bias", Int(self.apgiProfile1.somaticBias), Int(self.apgiProfile2.somaticBias))
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
    let parameters = ["Epsilon", "Precision", "Threshold", "Somatic Bias"]
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
        "Epsilon", String(format: "%.2f", self.apgiProfile1.epsilon),
        String(format: "%.2f", self.apgiProfile2.epsilon)
      ],
      [
        "Precision", String(format: "%.2f", self.apgiProfile1.precision),
        String(format: "%.2f", self.apgiProfile2.precision)
      ],
      [
        "Threshold", String(format: "%.2f", self.apgiProfile1.threshold),
        String(format: "%.2f", self.apgiProfile2.threshold)
      ],
      [
        "Somatic Bias", String(format: "%.2f", self.apgiProfile1.somaticBias),
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
