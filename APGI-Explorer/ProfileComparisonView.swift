import Charts
import SwiftUI

// ComparisonData and data models are in ComparisonDataStructures.swift
// Chart views are in ComparisonChartViews.swift

struct ProfileComparisonView: View {
  @EnvironmentObject private var profileManager: ProfileManager
  @Environment(\.appDependencies) private var dependencies: AppDependencies

  @State private var selectedProfile1: QuizProfile?
  @State private var selectedProfile2: QuizProfile?
  @AppStorage("defaultComparisonMode") private var comparisonModeRaw: String = ComparisonMode.radar.rawValue
  @State private var isLoading = false
  @State private var lastComparedProfiles: [QuizProfile] = []

  private var safeComparisonMode: Binding<ComparisonMode> {
    Binding(
      get: {
        if let mode = ComparisonMode(rawValue: comparisonModeRaw) {
          return mode
        }
        return .radar
      },
      set: { newValue in
        comparisonModeRaw = newValue.rawValue
      }
    )
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

          Picker("Comparison Mode", selection: safeComparisonMode) {
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

        Text((ComparisonMode(rawValue: comparisonModeRaw) ?? .radar).rawValue + " View")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .padding(.horizontal)

      // Lazy load chart content
      let comparisonData = ComparisonData(
        profile1: selectedProfile1,
        profile2: selectedProfile2,
        mode: ComparisonMode(rawValue: comparisonModeRaw) ?? .radar
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
                  .frame(height: 420)
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
              title: ScoreLabels.reactivity,
              value1: Int(apgiProfile1.epsilon),
              value2: Int(apgiProfile2.epsilon),
              isHigherBetter: false
            )

            self.differenceItem(
              title: ScoreLabels.prioritisation,
              value1: Int(apgiProfile1.precision),
              value2: Int(apgiProfile2.precision),
              isHigherBetter: true
            )

            self.differenceItem(
              title: ScoreLabels.threshold,
              value1: Int(apgiProfile1.threshold),
              value2: Int(apgiProfile2.threshold),
              isHigherBetter: true
            )

            self.differenceItem(
              title: ScoreLabels.bodySignal,
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
    -> some View {
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
    guard let profile1 = selectedProfile1, let profile2 = selectedProfile2 else { return }
    let profiles = [profile1, profile2]
    guard profiles != lastComparedProfiles else { return }
    lastComparedProfiles = profiles
    isLoading = false
    error = nil
    let type1 = profileManager.determineProfileType(for: QuizModel.calculateAPGIProfile(from: profile1.results))
    let type2 = profileManager.determineProfileType(for: QuizModel.calculateAPGIProfile(from: profile2.results))
    dependencies.getAnalyticsService().track(event: .comparisonStarted(profileTypes: [type1, type2]))
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
// Chart views moved to ComparisonChartViews.swift
// Data models moved to ComparisonDataStructures.swift
