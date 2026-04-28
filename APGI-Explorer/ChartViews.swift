import Charts
import SwiftUI

// MARK: - Chart Views

extension EnhancedProfileChart {
  var radarChartView: some View {
    VStack {
      Text("Parameter Radar Chart")
        .font(.headline)
        .padding(.bottom)

      Chart(self.profileDataPoints) { point in
        AreaMark(
          x: .value("Parameter", point.parameter),
          y: .value("Score", self.normalizeValues ? point.value / 100.0 : point.value)
        )
        .foregroundStyle(
          LinearGradient(
            colors: [self.colorForParameter(point.parameter).opacity(0.3), self.colorForParameter(point.parameter)],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        LineMark(
          x: .value("Parameter", point.parameter),
          y: .value("Score", self.normalizeValues ? point.value / 100.0 : point.value)
        )
        .foregroundStyle(self.colorForParameter(point.parameter))
        PointMark(
          x: .value("Parameter", point.parameter),
          y: .value("Score", self.normalizeValues ? point.value / 100.0 : point.value)
        )
        .foregroundStyle(self.colorForParameter(point.parameter))
        .annotation(position: .top) {
          if self.showDataPoints {
            Text("\(Int(point.value))")
              .font(.caption)
              .foregroundColor(.primary)
          }
        }
      }
      .chartYScale(domain: self.normalizeValues ? 0...1 : 0...100)
      .chartXAxis(.hidden)
      .chartYAxis(.hidden)
      .chartLegend(.hidden)
      .frame(height: 300)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(NSColor.controlBackgroundColor).opacity(0.2))
          .shadow(radius: 5)
      )
      .padding()
      .animation(self.chartAnimation, value: self.profileDataPoints)

      Spacer()

      VStack(alignment: .leading) {
        ForEach(self.profileDataPoints) { point in
          HStack {
            Circle()
              .fill(self.colorForParameter(point.parameter))
              .frame(width: 12, height: 12)
            Text(point.parameter)
            Spacer()
            Text("\(Int(point.value))")
              .font(.system(.body, design: .monospaced))
          }
        }
      }
      .padding()
    }
  }

  var lineChartView: some View {
    VStack {
      Text("Parameter Line Chart")
        .font(.headline)
        .padding(.bottom)

      Chart(self.profileDataPoints) { point in
        LineMark(
          x: .value("Parameter", point.parameter),
          y: .value("Score", self.normalizeValues ? point.value / 100.0 : point.value)
        )
        .foregroundStyle(self.colorForParameter(point.parameter))
        .lineStyle(StrokeStyle(lineWidth: 3))
        PointMark(
          x: .value("Parameter", point.parameter),
          y: .value("Score", self.normalizeValues ? point.value / 100.0 : point.value)
        )
        .foregroundStyle(self.colorForParameter(point.parameter))
        .annotation(position: .top) {
          if self.showDataPoints {
            Text("\(Int(point.value))")
              .font(.caption)
              .foregroundColor(.primary)
          }
        }
      }
      .chartYScale(domain: self.normalizeValues ? 0...1 : 0...100)
      .chartXAxis {
        AxisMarks(position: .bottom) { _ in
          AxisValueLabel()
          if self.showChartGrid {
            AxisGridLine()
          }
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading) { _ in
          AxisValueLabel()
          if self.showChartGrid {
            AxisGridLine()
          }
        }
      }
      .chartLegend(.hidden)
      .frame(height: 300)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(NSColor.controlBackgroundColor).opacity(0.2))
          .shadow(radius: 5)
      )
      .padding()
      .animation(self.chartAnimation, value: self.profileDataPoints)

      Spacer()

      VStack(alignment: .leading) {
        ForEach(self.profileDataPoints) { point in
          HStack {
            Circle()
              .fill(self.colorForParameter(point.parameter))
              .frame(width: 12, height: 12)
            Text(point.parameter)
            Spacer()
            Text("\(Int(point.value))")
              .font(.system(.body, design: .monospaced))
          }
        }
      }
      .padding()
    }
  }

  var barChartView: some View {
    VStack {
      Text("Parameter Bar Chart")
        .font(.headline)
        .padding(.bottom)

      Chart(self.profileDataPoints) { point in
        BarMark(
          x: .value("Parameter", point.parameter),
          y: .value("Score", self.normalizeValues ? point.value / 100.0 : point.value)
        )
        .foregroundStyle(self.colorForParameter(point.parameter))
        .cornerRadius(5)
        .annotation(position: .top) {
          if self.showValuesOnBars {
            Text("\(Int(point.value))")
              .font(.caption)
              .foregroundColor(.primary)
          }
        }
      }
      .chartYScale(domain: self.normalizeValues ? 0...1 : 0...100)
      .chartXAxis {
        AxisMarks(position: .bottom) { _ in
          AxisValueLabel()
          if self.showChartGrid {
            AxisGridLine()
          }
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading) { _ in
          AxisValueLabel()
          if self.showChartGrid {
            AxisGridLine()
          }
        }
      }
      .chartLegend(.hidden)
      .frame(height: 300)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(NSColor.controlBackgroundColor).opacity(0.2))
          .shadow(radius: 5)
      )
      .padding()
      .animation(self.chartAnimation, value: self.profileDataPoints)

      Spacer()

      VStack(alignment: .leading) {
        ForEach(self.profileDataPoints) { point in
          HStack {
            Circle()
              .fill(self.colorForParameter(point.parameter))
              .frame(width: 12, height: 12)
            Text(point.parameter)
            Spacer()
            Text("\(Int(point.value))")
              .font(.system(.body, design: .monospaced))
          }
        }
      }
      .padding()
    }
  }

  var areaChartView: some View {
    VStack {
      Text("Parameter Area Chart")
        .font(.headline)
        .padding(.bottom)

      Chart(self.profileDataPoints) { point in
        AreaMark(
          x: .value("Parameter", point.parameter),
          y: .value("Score", self.normalizeValues ? point.value / 100.0 : point.value)
        )
        .foregroundStyle(
          LinearGradient(
            colors: [Color.red, Color.yellow, Color.green],
            startPoint: .bottom,
            endPoint: .top
          )
        )
      }
      .chartYScale(domain: self.normalizeValues ? 0...1 : 0...100)
      .chartXAxis {
        AxisMarks(position: .bottom) { _ in
          AxisValueLabel()
          if self.showChartGrid {
            AxisGridLine()
          }
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading) { _ in
          AxisValueLabel()
          if self.showChartGrid {
            AxisGridLine()
          }
        }
      }
      .chartLegend(.hidden)
      .frame(height: 300)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(NSColor.controlBackgroundColor).opacity(0.2))
          .shadow(radius: 5)
      )
      .padding()
      .animation(self.chartAnimation, value: self.profileDataPoints)

      Spacer()

      VStack(alignment: .leading) {
        ForEach(self.profileDataPoints) { point in
          HStack {
            Circle()
              .fill(self.colorForParameter(point.parameter))
              .frame(width: 12, height: 12)
            Text(point.parameter)
            Spacer()
            Text("\(Int(point.value))")
              .font(.system(.body, design: .monospaced))
          }
        }
      }
      .padding()
    }
  }
}
