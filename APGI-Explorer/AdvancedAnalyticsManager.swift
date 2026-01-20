import SwiftUI
import Charts
import Combine

// MARK: - Supporting Data Structures

struct PredictionData {
    let predictedValue: Double
    let confidence: Double
    let factors: [String]
}

// MARK: - Advanced Analytics System

/// Provides trend analysis and predictive insights for APGI profiles
class AdvancedAnalyticsManager: ObservableObject {
    @Published var trendData: [TrendDataPoint] = []
    @Published var predictions: [PredictionResult] = []
    @Published var insights: [AnalyticsInsight] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let dataStore: DataStore
    private var cancellables = Set<AnyCancellable>()

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    // MARK: - Trend Analysis

    func analyzeTrends(for profiles: [QuizProfile]) async {
        isLoading = true
        error = nil

        do {
            let historicalData = try await loadHistoricalData()
            let trendAnalysis = performTrendAnalysis(profiles: profiles, historical: historicalData)

            await MainActor.run {
                self.trendData = trendAnalysis.trends
                self.insights = trendAnalysis.insights
                self.predictions = generatePredictions(from: trendAnalysis.trends)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }

    private func loadHistoricalData() async throws -> [HistoricalProfileData] {
        // For now, return empty historical data to avoid Sendable issues
        // In a real implementation, you would store historical data
        // in a Sendable format
        return []
    }

    private func performTrendAnalysis(
        profiles: [QuizProfile],
        historical: [HistoricalProfileData]
    ) -> TrendAnalysisResult {
        var trends: [TrendDataPoint] = []
        var insights: [AnalyticsInsight] = []

        // Analyze parameter trends over time
        let parameters: [KeyPath<QuizProfile, Double>] = [\.epsilon, \.precision, \.threshold, \.somaticBias]
        let parameterNames = ["Epsilon", "Precision", "Threshold", "Somatic Bias"]

        for (index, parameter) in parameters.enumerated() {
            let trend = calculateTrend(for: parameter, in: profiles, historical: historical)
            trends.append(trend)

            // Generate insights based on trends
            let insight = generateInsight(for: parameterNames[index], trend: trend)
            insights.append(insight)
        }

        return TrendAnalysisResult(trends: trends, insights: insights)
    }

    private func calculateTrend(
        for parameter: KeyPath<QuizProfile, Double>,
        in profiles: [QuizProfile],
        historical: [HistoricalProfileData]
    ) -> TrendDataPoint {
        let profileValues = profiles.map { $0[keyPath: parameter] }
        let historicalValues = historical.map { data in
            switch parameter {
            case \.epsilon: return data.epsilon
            case \.precision: return data.precision
            case \.threshold: return data.threshold
            case \.somaticBias: return data.somaticBias
            default: return 0.0
            }
        }
        let allData = profileValues + historicalValues

        let sortedData = allData.sorted()
        let mean = sortedData.reduce(0, +) / Double(sortedData.count)
        let variance = sortedData.map { pow($0 - mean, 2) }.reduce(0, +) / Double(sortedData.count)
        let standardDeviation = sqrt(variance)

        // Calculate trend direction
        let recentData = Array(allData.suffix(min(10, allData.count)))
        let olderData = Array(allData.prefix(min(10, allData.count)))
        let recentMean = recentData.reduce(0.0, +) / Double(recentData.count)
        let olderMean = olderData.reduce(0.0, +) / Double(olderData.count)

        let trendDirection: TrendDirection
        let trendStrength: Double

        if recentMean > olderMean {
            trendDirection = .increasing
            trendStrength = abs(recentMean - olderMean) / olderMean
        } else if recentMean < olderMean {
            trendDirection = .decreasing
            trendStrength = abs(recentMean - olderMean) / olderMean
        } else {
            trendDirection = .stable
            trendStrength = 0
        }

        return TrendDataPoint(
            parameter: String(describing: parameter).split(separator: ".").last?.description ?? "Unknown",
            currentValue: profiles.last?[keyPath: parameter] ?? 0,
            mean: mean,
            standardDeviation: standardDeviation,
            trendDirection: trendDirection,
            trendStrength: trendStrength,
            dataPoints: allData
        )
    }

    private func generateInsight(for parameterName: String, trend: TrendDataPoint) -> AnalyticsInsight {
        let insightType: InsightType
        let message: String
        let severity: InsightSeverity

        if trend.trendStrength > 0.2 {
            insightType = .significantChange
            severity = .high

            switch trend.trendDirection {
            case .increasing:
                message = "Your \(parameterName) has been significantly increasing over time. " +
                         "This may indicate a shift in your psychological patterns."
            case .decreasing:
                message = "Your \(parameterName) has been significantly decreasing over time. " +
                         "This suggests positive development in this area."
            case .stable:
                message = "Your \(parameterName) has remained stable, indicating consistent psychological patterns."
            }
        } else if trend.trendStrength > 0.1 {
            insightType = .moderateChange
            severity = .medium

            switch trend.trendDirection {
            case .increasing:
                message = "Your \(parameterName) shows moderate increase. Monitor this trend in future assessments."
            case .decreasing:
                message = "Your \(parameterName) shows moderate decrease, suggesting gradual improvement."
            case .stable:
                message = "Your \(parameterName) remains relatively stable with minor fluctuations."
            }
        } else {
            insightType = .minimalChange
            severity = .low
            message = "Your \(parameterName) shows minimal change, indicating consistent patterns."
        }

        return AnalyticsInsight(
            id: UUID(),
            type: insightType,
            parameter: parameterName,
            message: message,
            severity: severity,
            timestamp: Date(),
            trendData: trend
        )
    }

    private func generatePredictions(from trends: [TrendDataPoint]) -> [PredictionResult] {
        return trends.map { trend in
            let prediction = predictFutureValue(for: trend)
            return PredictionResult(
                parameter: trend.parameter,
                currentValue: trend.currentValue,
                predictedValue: prediction.predictedValue,
                confidence: prediction.confidence,
                timeframe: "3 months",
                factors: prediction.factors
            )
        }
    }

    private func predictFutureValue(
        for trend: TrendDataPoint
    ) -> PredictionData {
        // Simple linear regression for prediction
        let dataPoints = trend.dataPoints.suffix(20)
        let count = Double(dataPoints.count)

        let xValues = Array(0..<dataPoints.count).map(Double.init)
        let yValues = Array(dataPoints)

        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map(*).reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)

        let slope = (count * sumXY - sumX * sumY) / (count * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / count

        // Predict future value (10 time units ahead)
        let futureX = Double(dataPoints.count) + 10
        let predictedValue = slope * futureX + intercept

        // Calculate confidence based on trend strength and data consistency
        let confidence = max(0.3, min(0.95, 1.0 - (trend.standardDeviation / trend.mean) * 0.5))

        // Identify influencing factors
        var factors: [String] = []

        if trend.trendStrength > 0.15 {
            factors.append("Strong historical trend")
        }

        if trend.standardDeviation < trend.mean * 0.1 {
            factors.append("Consistent patterns")
        } else {
            factors.append("High variability in data")
        }

        if dataPoints.count > 15 {
            factors.append("Sufficient historical data")
        } else {
            factors.append("Limited historical data")
        }

        return PredictionData(
            predictedValue: predictedValue,
            confidence: confidence,
            factors: factors
        )
    }
}

// MARK: - Data Models

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let parameter: String
    let currentValue: Double
    let mean: Double
    let standardDeviation: Double
    let trendDirection: TrendDirection
    let trendStrength: Double
    let dataPoints: [Double]
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable

    var displayName: String {
        switch self {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .stable: return "Stable"
        }
    }

    var color: Color {
        switch self {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .blue
        }
    }
}

struct AnalyticsInsight: Identifiable {
    let id: UUID
    let type: InsightType
    let parameter: String
    let message: String
    let severity: InsightSeverity
    let timestamp: Date
    let trendData: TrendDataPoint
}

enum InsightType {
    case significantChange
    case moderateChange
    case minimalChange
    case anomaly
    case improvement

    var displayName: String {
        switch self {
        case .significantChange: return "Significant Change"
        case .moderateChange: return "Moderate Change"
        case .minimalChange: return "Minimal Change"
        case .anomaly: return "Anomaly Detected"
        case .improvement: return "Improvement"
        }
    }

    var icon: String {
        switch self {
        case .significantChange: return "exclamationmark.triangle"
        case .moderateChange: return "info.circle"
        case .minimalChange: return "minus.circle"
        case .anomaly: return "xmark.octagon"
        case .improvement: return "arrow.up.circle"
        }
    }
}

enum InsightSeverity {
    case high
    case medium
    case low

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    var priority: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

struct PredictionResult: Identifiable {
    let id = UUID()
    let parameter: String
    let currentValue: Double
    let predictedValue: Double
    let confidence: Double
    let timeframe: String
    let factors: [String]

    var changePercentage: Double {
        guard currentValue != 0 else { return 0 }
        return ((predictedValue - currentValue) / currentValue) * 100
    }

    var changeDirection: TrendDirection {
        if changePercentage > 5 {
            return .increasing
        } else if changePercentage < -5 {
            return .decreasing
        } else {
            return .stable
        }
    }
}

struct HistoricalProfileData {
    let id: UUID
    let dateCreated: Date
    let epsilon: Double
    let precision: Double
    let threshold: Double
    let somaticBias: Double
}

struct TrendAnalysisResult {
    let trends: [TrendDataPoint]
    let insights: [AnalyticsInsight]
}

// MARK: - Advanced Analytics View

struct AdvancedAnalyticsView: View {
    @StateObject private var analyticsManager: AdvancedAnalyticsManager
    @EnvironmentObject private var profileManager: ProfileManager

    @State private var selectedTimeframe: Timeframe = .all
    @State private var selectedParameter: String?

    init(profileManager: ProfileManager) {
        let dataStore = FileSystemDataStore(errorRecoveryManager: ErrorRecoveryManager())
        self._analyticsManager = StateObject(wrappedValue: AdvancedAnalyticsManager(dataStore: dataStore))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Timeframe Selector
                    timeframeSelector

                    // Trend Overview
                    trendOverviewSection

                    // Predictions Section
                    predictionsSection

                    // Insights Section
                    insightsSection

                    // Detailed Parameter Analysis
                    if let selectedParameter = selectedParameter {
                        detailedParameterAnalysis(parameter: selectedParameter)
                    }
                }
                .padding()
            }
            .navigationTitle("Advanced Analytics")
            .onAppear {
                loadAnalytics()
            }
        }
    }

    private var timeframeSelector: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases) { timeframe in
                Text(timeframe.displayName).tag(timeframe)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedTimeframe) { _, _ in
            loadAnalytics()
        }
    }

    private var trendOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trend Overview")
                .font(.headline)

            if analyticsManager.isLoading {
                ProgressView("Analyzing trends...")
            } else if let error = analyticsManager.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(analyticsManager.trendData) { trend in
                        TrendCard(trend: trend)
                            .onTapGesture {
                                selectedParameter = trend.parameter
                            }
                    }
                }
            }
        }
    }

    private var predictionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Predictions")
                .font(.headline)

            if !analyticsManager.predictions.isEmpty {
                ForEach(analyticsManager.predictions) { prediction in
                    PredictionCard(prediction: prediction)
                }
            }
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)

            let sortedInsights = analyticsManager.insights.sorted { $0.severity.priority > $1.severity.priority }

            ForEach(sortedInsights) { insight in
                InsightCard(insight: insight)
            }
        }
    }

    private func detailedParameterAnalysis(parameter: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Detailed Analysis: \(parameter)")
                    .font(.headline)
                Spacer()
                Button("Close") {
                    selectedParameter = nil
                }
            }

            if let trend = analyticsManager.trendData.first(where: { $0.parameter == parameter }) {
                ParameterDetailView(trend: trend)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private func loadAnalytics() {
        Task {
            await analyticsManager.analyzeTrends(for: profileManager.profiles)
        }
    }
}

// MARK: - Supporting Views

struct TrendCard: View {
    let trend: TrendDataPoint

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trend.parameter)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Current: \(String(format: "%.1f", trend.currentValue))")
                .font(.caption)

            HStack {
                Image(systemName: trend.trendDirection == .increasing ? "arrow.up" :
                               trend.trendDirection == .decreasing ? "arrow.down" : "arrow.right")
                    .foregroundColor(trend.trendDirection.color)

                Text("\(trend.trendDirection.displayName)")
                    .font(.caption)
                    .foregroundColor(trend.trendDirection.color)
            }

            ProgressView(value: trend.trendStrength, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: trend.trendDirection.color))
        }
        .padding()
        .background(Color.clear)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PredictionCard: View {
    let prediction: PredictionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(prediction.parameter)
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack {
                Text("Current:")
                Text(String(format: "%.1f", prediction.currentValue))
                Spacer()
                Text("Predicted:")
                Text(String(format: "%.1f", prediction.predictedValue))
            }
            .font(.caption)

            HStack {
                Text("Confidence:")
                Text(String(format: "%.0f%%", prediction.confidence * 100))
                    .foregroundColor(prediction.confidence > 0.7 ? .green : .orange)
                Spacer()
                Text("\(prediction.timeframe)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Change: \(String(format: "%.1f%%", prediction.changePercentage))")
                .font(.caption)
                .foregroundColor(prediction.changeDirection.color)
        }
        .padding()
        .background(Color.clear)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct InsightCard: View {
    let insight: AnalyticsInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insight.type.icon)
                    .foregroundColor(insight.severity.color)
                Text(insight.type.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Circle()
                    .fill(insight.severity.color)
                    .frame(width: 8, height: 8)
            }

            Text(insight.message)
                .font(.body)
                .multilineTextAlignment(.leading)

            Text(insight.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.clear)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ParameterDetailView: View {
    let trend: TrendDataPoint

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart showing trend over time
            Chart {
                ForEach(Array(trend.dataPoints.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(Color.blue)
                }
            }
            .frame(height: 200)

            // Statistics
            VStack(alignment: .leading, spacing: 8) {
                Text("Statistics")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Mean: \(String(format: "%.2f", trend.mean))")
                Text("Standard Deviation: \(String(format: "%.2f", trend.standardDeviation))")
                Text("Trend Strength: \(String(format: "%.2f", trend.trendStrength))")
            }
            .font(.caption)
        }
    }
}

// MARK: - Timeframe

enum Timeframe: CaseIterable, Identifiable {
    case week
    case month
    case quarter
    case year
    case all

    var id: String {
        switch self {
        case .week: return "week"
        case .month: return "month"
        case .quarter: return "quarter"
        case .year: return "year"
        case .all: return "all"
        }
    }

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        case .all: return "All Time"
        }
    }
}
