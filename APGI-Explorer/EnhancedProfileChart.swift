import Charts
import SwiftUI

struct EnhancedProfileChart: View {
  let profile: APGIProfile
  let comparisonProfiles: [APGIProfile]

  @ObservedObject private var performanceManager = PerformanceManager.shared
  @StateObject private var performanceTracker = PerformanceTracker()

  @Environment(\.animationSpeed) private var animationSpeed

  @AppStorage("preferredChartStyle") private var defaultChartStyle: ChartStyle = .radar
  @AppStorage("showChartGrid") internal var showChartGrid: Bool = true
  @AppStorage("animateCharts") var animateCharts: Bool = true
  @AppStorage("chartColorScheme") var chartColorScheme: String = "default"

  /// Color scheme based on setting
  var chartColors: [Color] {
    switch chartColorScheme {
    case "colorful":
      return [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    case "monochrome":
      return [.gray, .gray.opacity(0.7), .gray.opacity(0.5), .gray.opacity(0.3)]
    default:
      return [.blue, .green, .orange, .purple]
    }
  }

  /// Grid visibility modifier
  var gridVisibility: Visibility {
    showChartGrid ? .automatic : .hidden
  }

  /// Computed animation duration based on both animateCharts setting and animationSpeed
  internal var chartAnimation: Animation? {
    guard animateCharts else { return nil }
    let baseDuration = 0.3
    let adjustedDuration = baseDuration.adjustedForAnimationSpeed(animationSpeed)
    return .easeInOut(duration: adjustedDuration)
  }
  @AppStorage("showDataPoints") internal var showDataPoints: Bool = true
  @AppStorage("showValuesOnBars") internal var showValuesOnBars: Bool = true
  @AppStorage("allowZooming") internal var allowZooming: Bool = true
  @AppStorage("normalizeValues") internal var normalizeValues: Bool = true
  @AppStorage("showAverageProfile") var showAverageProfile: Bool = false
  @AppStorage("showDifferencesOnly") var showDifferencesOnly: Bool = false

  // Performance optimization: Cache computed properties
  @State private var cachedHistoricalData: [HistoricalDataPoint]?
  @State private var cachedProfileDataPoints: [ChartDataPoint]?
  @State private var cachedComparisonData: [ChartDataPoint]?

  /// Memory management: Track view visibility
  @State private var isVisible = false

  /// Performance optimization: Lazy load and cache historical data
  private var historicalData: [HistoricalDataPoint] {
    if let cached = cachedHistoricalData {
      return cached
    }

    let data = self.performanceTracker.track("historicalDataGeneration") {
      // Generate sample data for last 7 days
      var data: [HistoricalDataPoint] = []
      for dayIndex in 0..<7 {
        guard let date = Calendar.current.date(byAdding: .day, value: -dayIndex, to: Date()) else {
          continue
        }
        let variation = Double.random(in: -10...10)
        data.append(
          HistoricalDataPoint(
            date: date,
            epsilon: max(0, min(100, self.profile.epsilon + variation)),
            precision: max(0, min(100, self.profile.precision + variation)),
            threshold: max(0, min(100, self.profile.threshold + variation)),
            somaticBias: max(0, min(100, self.profile.somaticBias + variation))
          ))
      }
      return data.sorted { $0.date < $1.date }
    }

    self.cachedHistoricalData = data
    return data
  }

  /// Performance optimization: Cache profile data points
  internal var profileDataPoints: [ChartDataPoint] {
    if let cached = cachedProfileDataPoints {
      return cached
    }

    let data = [
      ChartDataPoint(
        parameter: "Reported reactivity to the unexpected", value: profile.epsilon,
        profileName: String(describing: self.profile.epsilonCategory).capitalized),
      ChartDataPoint(
        parameter: "Reported information prioritisation", value: self.profile.precision,
        profileName: String(describing: self.profile.precisionCategory).capitalized),
      ChartDataPoint(
        parameter: "Reported attentional threshold", value: self.profile.threshold,
        profileName: String(describing: self.profile.thresholdCategory).capitalized),
      ChartDataPoint(
        parameter: "Reported body-signal attention", value: self.profile.somaticBias,
        profileName: String(describing: self.profile.somaticCategory).capitalized)
    ]

    self.cachedProfileDataPoints = data
    return data
  }

  /// Performance optimization: Cache comparison data and limit comparisons
  var comparisonData: [ChartDataPoint] {
    if let cached = cachedComparisonData {
      return cached
    }

    let data = self.performanceTracker.track("comparisonDataGeneration") {
      var data: [ChartDataPoint] = []

      // Add main profile data
      data.append(contentsOf: [
        ChartDataPoint(
          parameter: "Reported reactivity to the unexpected", value: self.profile.epsilon, profileName: "Current"),
        ChartDataPoint(
          parameter: "Reported information prioritisation", value: self.profile.precision, profileName: "Current"),
        ChartDataPoint(
          parameter: "Reported attentional threshold", value: self.profile.threshold, profileName: "Current"),
        ChartDataPoint(
          parameter: "Reported body-signal attention", value: self.profile.somaticBias, profileName: "Current")
      ])

      // Limit comparisons based on performance mode
      let maxComparisons = self.performanceManager.performanceMode == .memory ? 1 : 3

      // Add comparison profiles data
      for (index, compProfile) in self.comparisonProfiles.prefix(maxComparisons).enumerated() {
        let profileName = "Comparison \(index + 1)"
        data.append(contentsOf: [
          ChartDataPoint(
            parameter: "Reported reactivity to the unexpected", value: compProfile.epsilon, profileName: profileName),
          ChartDataPoint(
            parameter: "Reported information prioritisation", value: compProfile.precision, profileName: profileName),
          ChartDataPoint(
            parameter: "Reported attentional threshold", value: compProfile.threshold, profileName: profileName),
          ChartDataPoint(
            parameter: "Reported body-signal attention", value: compProfile.somaticBias, profileName: profileName)
        ])
      }

      return data
    }

    self.cachedComparisonData = data
    return data
  }

  var body: some View {
    VStack(spacing: 0) {
      // Customization Toolbar
      self.customizationToolbar
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .memoryEfficient()

      // Performance optimization: Use TabView with lazy loading
      TabView {
        // Default Chart Style (based on user preference)
        lazyLoad(data: self.defaultChartStyle) { _ in
          self.defaultChartView
            .tabItem {
              Label(self.defaultChartStyleName, systemImage: self.defaultChartStyleIcon)
            }
        }

        // Radar Chart Tab
        lazyLoad(data: "radar") { _ in
          self.radarChartView
            .tabItem {
              Label("Radar", systemImage: "circle.hexagonpath")
            }
        }

        // 3D Visualization
        self.chart3DView
          .tabItem {
            Label("3D View", systemImage: "cube")
          }

        // Time Series
        self.timeSeriesView
          .tabItem {
            Label("Trends", systemImage: "chart.xyaxis.line")
          }

        // Comparison Matrix
        self.comparisonMatrixView
          .tabItem {
            Label("Compare", systemImage: "square.grid.2x2")
          }
      }
      .padding()
    }
    .platformNavigationTitle("Profile Analytics")
  }

  // MARK: - Customization Toolbar

  private var customizationToolbar: some View {
    VStack(spacing: 12) {
      // Chart Style Selector
      HStack {
        Text("Chart Style:")
          .font(.caption)
          .foregroundColor(.secondary)

        Picker("Style", selection: self.$defaultChartStyle) {
          ForEach(ChartStyle.allCases, id: \.self) { style in
            Text(style.rawValue.capitalized).tag(style)
          }
        }
        .pickerStyle(.segmented)
      }

      // Options Row
      HStack(spacing: 20) {
        // Show Data Points Toggle
        Toggle("Data Points", isOn: self.$showDataPoints)
          .toggleStyle(.switch)

        // Show Values on Bars Toggle
        Toggle("Values", isOn: self.$showValuesOnBars)
          .toggleStyle(.switch)

        // Allow Zooming Toggle
        Toggle("Zoom", isOn: self.$allowZooming)
          .toggleStyle(.switch)
      }
      .font(.caption)

      // Advanced Options Row
      HStack(spacing: 20) {
        // Normalize Values Toggle
        Toggle("Normalize", isOn: self.$normalizeValues)
          .toggleStyle(.switch)

        // Show Average Profile Toggle
        Toggle("Average", isOn: self.$showAverageProfile)
          .toggleStyle(.switch)

        // Show Differences Only Toggle
        Toggle("Differences", isOn: self.$showDifferencesOnly)
          .toggleStyle(.switch)
      }
      .font(.caption)
    }
  }

  private var defaultChartView: some View {
    switch self.defaultChartStyle {
    case .radar:
      AnyView(self.radarChartView)
    case .bar:
      AnyView(self.barChartView)
    case .line:
      AnyView(self.lineChartView)
    case .area:
      AnyView(self.areaChartView)
    }
  }

  private var defaultChartStyleName: String {
    switch self.defaultChartStyle {
    case .radar: "Radar"
    case .bar: "Bar"
    case .line: "Line"
    case .area: "Area"
    }
  }

  private var defaultChartStyleIcon: String {
    switch self.defaultChartStyle {
    case .radar: "circle.hexagonpath"
    case .bar: "chart.bar"
    case .line: "chart.line.uptrend.xyaxis"
    case .area: "chart.area.stack"
    }
  }

  // MARK: - Additional Chart Views

  private var chart3DView: some View {
    VStack {
      Text("3D Profile Visualization")
        .font(.headline)
        .padding(.bottom)

      Chart(self.profileDataPoints) { point in
        PointMark(
          x: .value("Parameter", point.parameter),
          y: .value("Score", point.value)
        )
        .foregroundStyle(chartColors.first ?? .blue)
        .symbolSize(100)
        .symbol {
          Circle()
            .fill(self.colorForParameter(point.parameter))
            .frame(width: 10, height: 10)
            .shadow(radius: 3)
        }
      }
      .chartYScale(domain: 0...100)
      .chartLegend(.hidden)
      .chartXAxis {
        AxisMarks(preset: .aligned) { _ in
          AxisValueLabel()
          if showChartGrid {
            AxisGridLine()
          }
        }
      }
      .chartYAxis {
        AxisMarks(preset: .aligned) { _ in
          AxisValueLabel()
          if showChartGrid {
            AxisGridLine()
          }
        }
      }
      .animation(chartAnimation, value: profile)
      .frame(height: 300)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(NSColor.controlBackgroundColor).opacity(0.2))
          .shadow(radius: 5)
      )
      .padding()

      Spacer()

      VStack(alignment: .leading) {
        Text("3D Visualization")
          .font(.headline)
          .padding(.bottom, 4)

        Text(
          "This visualization shows the relative strengths of each cognitive parameter. " +
          "The higher the point, the stronger that parameter is in your profile."
        )
        .font(.caption)
        .foregroundColor(.secondary)
      }
      .padding()
    }
  }

  private var timeSeriesView: some View {
    VStack {
      Text("Parameter Trends Over Time")
        .font(.headline)
        .padding(.bottom)

      Chart {
        ForEach(self.historicalData) { point in
          LineMark(
            x: .value("Date", point.date, unit: .day),
            y: .value("Score", point.epsilon)
          )
          .foregroundStyle(.blue)
          .interpolationMethod(.catmullRom)
          .lineStyle(StrokeStyle(lineWidth: 2))
        }

        ForEach(self.historicalData) { point in
          LineMark(
            x: .value("Date", point.date, unit: .day),
            y: .value("Score", point.precision)
          )
          .foregroundStyle(.green)
          .interpolationMethod(.catmullRom)
          .lineStyle(StrokeStyle(lineWidth: 2))
        }
      }
      .chartXAxis {
        AxisMarks(values: .automatic(desiredCount: 7)) { value in
          if let date = value.as(Date.self) {
            AxisValueLabel {
              Text(date, style: .date)
                .font(.caption2)
            }
            AxisTick()
            if self.showChartGrid {
              AxisGridLine()
            }
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
      .chartYScale(domain: 0...100)
      .animation(chartAnimation, value: historicalData)
      .frame(height: 300)
      .padding()

      HStack(spacing: 20) {
        LegendItem(color: .blue, label: "Reported reactivity to the unexpected")
        LegendItem(color: .green, label: "Reported information prioritisation")
      }
      .padding()
    }
  }

  private var comparisonMatrixView: some View {
    let comparisonHeight = 200 + CGFloat(self.comparisonProfiles.count) * 40
    let effectiveComparisonData =
      self.showDifferencesOnly
      ? self.filterDifferencesOnly(self.comparisonData) : self.comparisonData

    return VStack {
      Text("Profile Comparison")
        .font(.headline)
        .padding(.bottom)

      Chart(effectiveComparisonData) { dataPoint in
        RectangleMark(
          x: .value("Parameter", dataPoint.parameter),
          y: .value("Profile", dataPoint.profileName),
          width: .ratio(0.8),
          height: .ratio(0.8)
        )
        .foregroundStyle(
          by: .value("Value", self.normalizeValues ? dataPoint.value / 100.0 : dataPoint.value)
        )
        .cornerRadius(4)
      }
      .chartXAxis {
        AxisMarks(position: .bottom) { _ in
          AxisValueLabel()
          if self.showChartGrid {
            AxisGridLine()
          }
        }
      }
      .chartYAxis {
        AxisMarks(preset: .aligned, position: .leading) { _ in
          AxisValueLabel()
        }
      }
      .foregroundStyle(
        LinearGradient(
          colors: self.chartColorScheme == "monochrome"
            ? [Color.gray, Color.gray.opacity(0.5)]
            : [Color.red, Color.yellow, Color.green],
          startPoint: .bottom,
          endPoint: .top
        )
      )
      .animation(chartAnimation, value: effectiveComparisonData)
      .frame(height: comparisonHeight)
      .padding()

      Text("Comparison shows your current profile against up to 3 other profiles")
        .font(.caption)
        .foregroundColor(.secondary)
        .padding()
    }
  }

  // MARK: - Helper Methods

  private func filterDifferencesOnly(_ data: [ChartDataPoint]) -> [ChartDataPoint] {
    guard !data.isEmpty else { return data }

    // Group data by parameter
    let groupedData = Dictionary(grouping: data) { $0.parameter }
    var filteredData: [ChartDataPoint] = []

    for (_, points) in groupedData {
      guard points.count >= 2 else {
        filteredData.append(contentsOf: points)
        continue
      }

      let values = points.map(\.value)
      guard let maxValue = values.max(), let minValue = values.min() else { continue }
      let range = maxValue - minValue

      // Only include parameters with significant differences (> 20% difference)
      if range > 20.0 {
        filteredData.append(contentsOf: points)
      }
    }

    return filteredData
  }

  internal func colorForParameter(_ parameter: String) -> Color {
    let baseColor = Color.baseColorForParameter(parameter)
    return Color.applyColorScheme(to: baseColor, scheme: self.chartColorScheme)
  }

  private func createStateComparisonRadar() -> StateComparisonRadar? {
    // Create a primary psychological state from the current profile
    let primaryState = self.createPsychologicalState(from: self.profile)

    // Create comparison states from other profiles
    let comparisonStates = self.comparisonProfiles.prefix(3).map { otherProfile in
      self.createPsychologicalState(from: otherProfile)
    }

    return StateComparisonRadar(primary: primaryState, comparisons: comparisonStates)
  }

  private func createPsychologicalState(from profile: APGIProfile) -> PsychologicalState {
    // Map APGIProfile to PsychologicalState parameters
    PsychologicalState(
      id: Int(abs(profile.epsilon.hashValue)),  // Convert to positive Int
      name: "APGI Profile",
      description: "Profile created from APGI parameters",
      parameters: APGIParameters(
        predictionError: PredictionErrorSpec(
          accuracy: ParameterRange(
            min: Double(100 - profile.epsilon),
            max: Double(100 - profile.epsilon + 10),
            unit: .percentage,
            description: "Prediction accuracy range"
          ),
          context: .taskAligned,
          description: "Prediction error based on epsilon parameter"
        ),
        precision: PrecisionProfile(
          task: .veryHigh(Double(profile.precision) / 20.0),
          distractor: .low(0.2),
          description: "Precision level from APGI profile"
        ),
        threshold: ThresholdRange(
          adjustment: Double(profile.threshold - 50) / 50.0,
          variance: 0.1,
          unit: .sigma,
          stability: .normal,
          description: "Threshold based on APGI parameter"
        ),
        somaticBias: BiasRange(
          min: Double(profile.somaticBias) * 0.8,
          max: Double(profile.somaticBias) * 1.2,
          description: "Somatic bias from APGI profile",
          dominance: .balanced
        )
      ),
      metadata: StateMetadata(
        duration: .medium,
        metabolicCost: .moderate,
        neurologicalBasis: ["cortical", "subcortical"],
        adaptiveValue: .adaptive
      )
    )
  }
}
