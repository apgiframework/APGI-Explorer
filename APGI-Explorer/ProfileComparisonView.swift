import Charts
import SwiftUI

// MARK: - Supporting Data Structures

struct ComparisonData: Hashable {
  let profile1: QuizProfile?
  let profile2: QuizProfile?
  let mode: ComparisonMode

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.profile1?.id)
    hasher.combine(self.profile2?.id)
    hasher.combine(self.mode)
  }

  static func == (lhs: ComparisonData, rhs: ComparisonData) -> Bool {
    lhs.profile1?.id == rhs.profile1?.id && lhs.profile2?.id == rhs.profile2?.id
      && lhs.mode == rhs.mode
  }
}

struct ProfileComparisonView: View {
  @EnvironmentObject private var profileManager: ProfileManager
  @Environment(\.appDependencies) private var dependencies: AppDependencies
  @StateObject private var performanceManager = PerformanceManager.shared

  @State private var selectedProfile1: QuizProfile?
  @State private var selectedProfile2: QuizProfile?
  @AppStorage("defaultComparisonMode") private var comparisonModeRaw: String = ComparisonMode.radar
    .rawValue
  @State private var isLoading = false

  private var comparisonMode: ComparisonMode {
    get { ComparisonMode(rawValue: comparisonModeRaw) ?? .radar }
    nonmutating set { comparisonModeRaw = newValue.rawValue }
  }
  @State private var error: Error?
  @State private var showExportSheet = false
  @State private var exportData: Data?
  @State private var chartData: [ChartDataPoint]?

  /// Performance optimization: Lazy loading for chart data
  @State private var isChartVisible = false

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 20) {
        // Header
        VStack(spacing: 8) {
          Text("Profile Comparison")
            .font(.largeTitle.bold())
            .foregroundColor(.primary)

          Text("Compare psychological profiles side by side")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
        .memoryEfficient()

        // Profile Selection Cards
        HStack(spacing: 20) {
          self.profileSelectionCard(profile: self.$selectedProfile1, title: "Profile 1")
            .onChange(of: self.selectedProfile1) { _, _ in
              if self.selectedProfile1 != nil, self.selectedProfile2 != nil {
                self.performComparison()
              }
            }
          self.profileSelectionCard(profile: self.$selectedProfile2, title: "Profile 2")
            .onChange(of: self.selectedProfile2) { _, _ in
              if self.selectedProfile1 != nil, self.selectedProfile2 != nil {
                self.performComparison()
              }
            }
        }
        .padding(.horizontal)
        .memoryEfficient()

        // Comparison Mode Picker with Icons
        VStack(alignment: .leading, spacing: 8) {
          Text("Visualization")
            .font(.headline)
            .padding(.horizontal)

          Picker(
            "Comparison Mode",
            selection: Binding(
              get: {
                // Defensive: ensure we never return an invalid mode
                let validValue =
                  comparisonModeRaw.isEmpty ? ComparisonMode.radar.rawValue : comparisonModeRaw
                return ComparisonMode(rawValue: validValue) ?? .radar
              },
              set: { comparisonModeRaw = $0.rawValue }
            )
          ) {
            ForEach(ComparisonMode.allCases) { mode in
              Label {
                Text(mode.rawValue)
              } icon: {
                Image(systemName: mode.icon)
              }
              .tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .padding(.horizontal)
        }
        .padding(.vertical, 10)

        // Main Content Area
        if self.isLoading {
          self.loadingView
        } else if let error {
          self.errorView(error: error)
        } else if self.selectedProfile1 != nil, self.selectedProfile2 != nil {
          self.comparisonChart
            .transition(.opacity.combined(with: .scale(scale: 0.95)))

          self.comparisonSummary
            .padding(.top, 10)
        } else {
          self.emptyStateView
        }

        Spacer()
      }
      .padding()
    }
    .background(Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all))
    .onAppear {
      // Fix invalid UserDefaults values that cause Picker crashes
      if comparisonModeRaw.isEmpty || ComparisonMode(rawValue: comparisonModeRaw) == nil {
        comparisonModeRaw = ComparisonMode.radar.rawValue
      }
      // Trigger comparison if both profiles are already selected
      if self.selectedProfile1 != nil, self.selectedProfile2 != nil {
        self.performComparison()
      }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Menu {
          Button(
            action: self.exportComparison,
            label: {
              Label("Export as Image", systemImage: "square.and.arrow.up")
            })

          Button(
            action: { self.showExportSheet = true },
            label: {
              Label("Export as PDF", systemImage: "doc.text")
            })
        } label: {
          Label("Export", systemImage: "square.and.arrow.up")
        }
        .disabled(self.selectedProfile1 == nil || self.selectedProfile2 == nil)
      }
    }
    .sheet(isPresented: self.$showExportSheet) {
      if let exportData {
        ShareSheet(items: [exportData])
      }
    }
  }

  private var comparisonChart: some View {
    // Performance optimization: Lazy load chart only when visible
    LazyVStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(
          "Comparison: \(self.selectedProfile1?.name ?? "Unknown") vs \(self.selectedProfile2?.name ?? "Unknown")"
        )
        .font(.headline)

        Spacer()

        Text(self.comparisonMode.rawValue + " View")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .padding(.horizontal)

      // Lazy load chart content
      let comparisonData = ComparisonData(
        profile1: selectedProfile1,
        profile2: selectedProfile2,
        mode: comparisonMode
      )
      lazyLoad(data: comparisonData) { data in
        if let profile1 = data.profile1, let profile2 = data.profile2 {
          ZStack {
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.white)
              .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)

            VStack {
              switch data.mode {
              case .radar:
                RadarComparisonChart(profile1: profile1, profile2: profile2)
                  .frame(height: 350)
              case .bar:
                BarComparisonChart(profile1: profile1, profile2: profile2)
                  .frame(height: 350)
              case .table:
                ComparisonTableView(profile1: profile1, profile2: profile2)
              case .line:
                LineComparisonChart(profile1: profile1, profile2: profile2)
                  .frame(height: 350)
                  .padding()
                  .id("line-chart-\(profile1.id)-\(profile2.id)")
              }
            }
          }
          .padding(.horizontal)
          .memoryEfficient()
        }
      }
    }
    .onAppear {
      self.isChartVisible = true
    }
    .onDisappear {
      self.isChartVisible = false
      // Clear chart data when not visible to save memory
      self.chartData = nil
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "chart.bar.doc.horizontal")
        .font(.system(size: 60))
        .foregroundColor(.secondary)
        .opacity(0.6)

      VStack(spacing: 8) {
        Text("No Profiles Selected")
          .font(.title2.bold())
          .foregroundColor(.primary)

        Text(
          "Select two profiles to begin comparing their psychological parameters and gain insights into their differences and similarities."
        )
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
        .lineSpacing(4)
      }
      .padding(.vertical, 30)
      .frame(maxWidth: 500)
    }
    .frame(maxWidth: .infinity, minHeight: 400)
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
    .padding(.horizontal)
    .padding(.vertical, 40)
  }

  private var loadingView: some View {
    VStack(spacing: 20) {
      LoadingIndicator(message: "Loading comparison...", size: .large)
        .padding()

      Text("Analyzing Profiles...")
        .font(.headline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, minHeight: 300)
  }

  private func errorView(error: Error) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 40))
        .foregroundColor(.orange)

      VStack(spacing: 8) {
        Text("Error Loading Data")
          .font(.headline)

        Text(error.localizedDescription)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }

      Button("Try Again") {
        Task {
          await self.loadProfiles()
        }
      }
      .buttonStyle(SecondaryButtonStyle())
      .padding(.top, 10)
    }
    .padding()
    .frame(maxWidth: .infinity, minHeight: 200)
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
    .padding()
  }

  private var comparisonSummary: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Key Differences")
        .font(.headline)
        .padding(.horizontal)

      ZStack {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.white)
          .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)

        VStack(spacing: 16) {
          if let profile1 = selectedProfile1, let profile2 = selectedProfile2 {
            let apgiProfile1 = QuizModel.calculateAPGIProfile(from: profile1.results)
            let apgiProfile2 = QuizModel.calculateAPGIProfile(from: profile2.results)

            self.differenceItem(
              title: "Epsilon (Prediction Error)",
              value1: Int(apgiProfile1.epsilon),
              value2: Int(apgiProfile2.epsilon),
              isHigherBetter: false
            )

            self.differenceItem(
              title: "Precision",
              value1: Int(apgiProfile1.precision),
              value2: Int(apgiProfile2.precision),
              isHigherBetter: true
            )

            self.differenceItem(
              title: "Threshold",
              value1: Int(apgiProfile1.threshold),
              value2: Int(apgiProfile2.threshold),
              isHigherBetter: true
            )

            self.differenceItem(
              title: "Somatic Bias",
              value1: Int(apgiProfile1.somaticBias),
              value2: Int(apgiProfile2.somaticBias),
              isHigherBetter: false
            )
          }
        }
        .padding()
      }
      .padding(.horizontal)
    }
  }

  private func profileSelectionCard(profile: Binding<QuizProfile?>, title: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .foregroundColor(.secondary)

      Menu {
        Button(
          action: { profile.wrappedValue = nil },
          label: {
            Label("Select Profile...", systemImage: "person.crop.circle")
          })

        Divider()

        ForEach(self.getAvailableProfiles(), id: \.id) { quizProfile in
          Button(
            action: { profile.wrappedValue = quizProfile },
            label: {
              HStack {
                Text(quizProfile.name)
                if profile.wrappedValue?.id == quizProfile.id {
                  Image(systemName: "checkmark")
                }
              }
            })
        }
      } label: {
        HStack {
          Text(profile.wrappedValue?.name ?? "Select Profile...")
            .foregroundColor(profile.wrappedValue == nil ? .secondary : .primary)

          Spacer()

          Image(systemName: "chevron.down.circle.fill")
            .foregroundColor(.accentColor)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
      }
      .buttonStyle(AppPlainButtonStyle())
    }
  }

  @ViewBuilder
  private func differenceItem(title: String, value1: Int, value2: Int, isHigherBetter: Bool)
    -> some View
  {
    let diff = value1 - value2
    let isPositive = isHigherBetter ? (diff > 0) : (diff < 0)
    let difference = abs(diff)

    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(title)
          .font(.subheadline.bold())

        Spacer()

        if diff != 0 {
          HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
              .foregroundColor(isPositive ? .green : .red)

            Text("\(difference)%")
              .font(.caption.bold())
              .foregroundColor(isPositive ? .green : .red)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background((isPositive ? Color.green : Color.red).opacity(0.1))
          .cornerRadius(8)
        }
      }

      HStack(spacing: 16) {
        Text(self.selectedProfile1?.name ?? "Profile 1")
          .font(.caption)
          .frame(width: 80, alignment: .leading)

        GeometryReader { geometry in
          HStack(spacing: 0) {
            Rectangle()
              .fill(Color.blue.opacity(0.7))
              .frame(
                width: max(
                  0,
                  min(
                    geometry.size.width - 60,
                    (geometry.size.width - 60) * CGFloat(max(0, min(100, value1))) / 100)),
                height: 8
              )
              .cornerRadius(4)

            Spacer(minLength: 0)
          }
        }
        .frame(height: 8)

        Text("\(value1)%")
          .font(.caption.monospacedDigit())
          .frame(width: 40, alignment: .trailing)
      }

      HStack(spacing: 16) {
        Text(self.selectedProfile2?.name ?? "Profile 2")
          .font(.caption)
          .frame(width: 80, alignment: .leading)

        GeometryReader { geometry in
          HStack(spacing: 0) {
            Rectangle()
              .fill(Color.orange.opacity(0.7))
              .frame(
                width: max(
                  0,
                  min(
                    geometry.size.width - 60,
                    (geometry.size.width - 60) * CGFloat(max(0, min(100, value2))) / 100)),
                height: 8
              )
              .cornerRadius(4)

            Spacer(minLength: 0)
          }
        }
        .frame(height: 8)

        Text("\(value2)%")
          .font(.caption.monospacedDigit())
          .frame(width: 40, alignment: .trailing)
      }
    }
  }

  private func getAvailableProfiles() -> [QuizProfile] {
    self.profileManager.profiles.sorted { $0.name < $1.name }
  }

  private func performComparison() {
    // Reset state
    self.isLoading = true
    self.error = nil

    // Simulate network/database call
    let workItem = DispatchWorkItem {
      self.isLoading = false

      // Log analytics if profiles are selected
      if let profile1 = self.selectedProfile1, let profile2 = self.selectedProfile2 {
        let profileType1 = APGIProfileType(rawValue: profile1.name) ?? .openExplorer
        let profileType2 = APGIProfileType(rawValue: profile2.name) ?? .openExplorer

        self.dependencies.getAnalyticsService().track(
          event: .comparisonStarted(profileTypes: [profileType1, profileType2]))
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
  }

  private func exportComparison() {
    // In a real app, this would generate a PDF or image of the comparison
    // For now, we'll just show a preview of what would be exported

    let renderer = ImageRenderer(content: comparisonChart)

    #if canImport(UIKit)
      if let uiImage = renderer.uiImage {
        if let data = uiImage.pngData() {
          self.exportData = data
          self.showExportSheet = true
        }
      }
    #elseif canImport(AppKit)
      if let nsImage = renderer.nsImage {
        if let data = nsImage.tiffRepresentation {
          self.exportData = data
          self.showExportSheet = true
        }
      }
    #endif
  }

  private func loadProfiles() async {
    await self.profileManager.loadProfiles()
  }
}

// MARK: - Comparison Chart Views

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
      ("Somatic Bias", Int(self.apgiProfile1.somaticBias), Int(self.apgiProfile2.somaticBias)),
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
          .cornerRadius(4)

          // Profile 2 bars
          BarMark(
            x: .value("Category", item.category),
            y: .value("Value", item.value2)
          )
          .foregroundStyle(Color.orange.gradient)
          .position(by: .value("Profile", self.profile2.name))
          .cornerRadius(4)
        }
      }
      .chartXAxis {
        AxisMarks { _ in
          AxisValueLabel()
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading) { _ in
          AxisGridLine()
          AxisTick()
          AxisValueLabel()
        }
      }
      .chartLegend(position: .top, alignment: .center) {
        HStack(spacing: 20) {
          ForEach([(Color.blue, self.profile1.name), (Color.orange, self.profile2.name)], id: \.1) {
            color, label in
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
      self.apgiProfile1.somaticBias,
    ]
    let values2 = [
      apgiProfile2.epsilon, self.apgiProfile2.precision, self.apgiProfile2.threshold,
      self.apgiProfile2.somaticBias,
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
        AxisMarks { _ in
          AxisGridLine()
          AxisTick()
          AxisValueLabel()
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading) { _ in
          AxisGridLine()
          AxisTick()
          AxisValueLabel()
        }
      }
      .chartLegend(position: .top, alignment: .center) {
        HStack(spacing: 20) {
          ForEach([(Color.blue, self.profile1.name), (Color.orange, self.profile2.name)], id: \.1) {
            color, label in
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
        String(format: "%.2f", self.apgiProfile2.epsilon),
      ],
      [
        "Precision", String(format: "%.2f", self.apgiProfile1.precision),
        String(format: "%.2f", self.apgiProfile2.precision),
      ],
      [
        "Threshold", String(format: "%.2f", self.apgiProfile1.threshold),
        String(format: "%.2f", self.apgiProfile2.threshold),
      ],
      [
        "Somatic Bias", String(format: "%.2f", self.apgiProfile1.somaticBias),
        String(format: "%.2f", self.apgiProfile2.somaticBias),
      ],
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
          ForEach(row, id: \.self) { value in
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

// MARK: - Data Models

private struct RadarData: Identifiable {
  let id = UUID()
  let category: String
  let value1: Double
  let value2: Double
}

private struct BarData: Identifiable {
  let id = UUID()
  let category: String
  let value1: Int
  let value2: Int
}

private struct LineData: Identifiable {
  let id = UUID()
  let period: String
  let value1: Int
  let value2: Int
}

// MARK: - Share Sheet

// ShareSheet implementation moved to ShareSheet.swift
