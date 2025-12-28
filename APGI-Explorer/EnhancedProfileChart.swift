import SwiftUI
import Charts
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Shape Extensions

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Square: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        return path
    }
}

// MARK: - Data Models

// MARK: - Data Models

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let parameter: String
    let value: Double
    let profileName: String
}

struct HistoricalDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let epsilon: Double
    let precision: Double
    let threshold: Double
    let somaticBias: Double
}

// MARK: - Main View

struct EnhancedProfileChart: View {
    let profile: APGIProfile
    let comparisonProfiles: [APGIProfile]
    
    @AppStorage("preferredChartStyle") private var defaultChartStyle: ChartStyle = .radar
    
    // Sample historical data (replace with actual data from your data store)
    private var historicalData: [HistoricalDataPoint] {
        // Generate sample data for the last 7 days
        var data: [HistoricalDataPoint] = []
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let variation = Double.random(in: -10...10)
            data.append(HistoricalDataPoint(
                date: date,
                epsilon: max(0, min(100, profile.epsilon + variation)),
                precision: max(0, min(100, profile.precision + variation)),
                threshold: max(0, min(100, profile.threshold + variation)),
                somaticBias: max(0, min(100, profile.somaticBias + variation))
            ))
        }
        return data.sorted { $0.date < $1.date }
    }
    
    private var profileDataPoints: [ChartDataPoint] {
        [
            ChartDataPoint(parameter: "ε (Epsilon)", value: profile.epsilon, profileName: String(describing: profile.epsilonCategory).capitalized),
            ChartDataPoint(parameter: "π (Precision)", value: profile.precision, profileName: String(describing: profile.precisionCategory).capitalized),
            ChartDataPoint(parameter: "θₜ (Threshold)", value: profile.threshold, profileName: String(describing: profile.thresholdCategory).capitalized),
            ChartDataPoint(parameter: "β (Somatic Bias)", value: profile.somaticBias, profileName: String(describing: profile.somaticCategory).capitalized)
        ]
    }
    
    private var comparisonData: [ChartDataPoint] {
        var data: [ChartDataPoint] = []
        
        // Add main profile data
        data.append(contentsOf: [
            ChartDataPoint(parameter: "ε (Epsilon)", value: profile.epsilon, profileName: "Current"),
            ChartDataPoint(parameter: "π (Precision)", value: profile.precision, profileName: "Current"),
            ChartDataPoint(parameter: "θₜ (Threshold)", value: profile.threshold, profileName: "Current"),
            ChartDataPoint(parameter: "β (Somatic Bias)", value: profile.somaticBias, profileName: "Current")
        ])
        
        // Add comparison profiles data
        for compProfile in comparisonProfiles.prefix(3) { // Limit to 3 comparisons for readability
            let profileName = "Comparison \(data.count / 4 + 1)"
            data.append(contentsOf: [
                ChartDataPoint(parameter: "ε (Epsilon)", value: compProfile.epsilon, profileName: profileName),
                ChartDataPoint(parameter: "π (Precision)", value: compProfile.precision, profileName: profileName),
                ChartDataPoint(parameter: "θₜ (Threshold)", value: compProfile.threshold, profileName: profileName),
                ChartDataPoint(parameter: "β (Somatic Bias)", value: compProfile.somaticBias, profileName: profileName)
            ])
        }
        
        return data
    }
    
    var body: some View {
        TabView {
            // Default Chart Style (based on user preference)
            defaultChartView
                .tabItem {
                    Label(defaultChartStyleName, systemImage: defaultChartStyleIcon)
                }
            
            // Radar Chart Tab
            radarChartView
                .tabItem {
                    Label("Radar", systemImage: "circle.hexagonpath")
                }
            
            // 3D Visualization
            chart3DView
                .tabItem {
                    Label("3D View", systemImage: "cube")
                }
            
            // Time Series
            timeSeriesView
                .tabItem {
                    Label("Trends", systemImage: "chart.xyaxis.line")
                }
            
            // Comparison Matrix
            comparisonMatrixView
                .tabItem {
                    Label("Compare", systemImage: "square.grid.2x2")
                }
        }
        .padding()
        .navigationTitle("Profile Analytics")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    }
    
    // MARK: - Default Chart View
    
    private var defaultChartView: some View {
        switch defaultChartStyle {
        case .radar:
            return AnyView(radarChartView)
        case .bar:
            return AnyView(barChartView)
        case .line:
            return AnyView(lineChartView)
        case .area:
            return AnyView(areaChartView)
        }
    }
    
    private var defaultChartStyleName: String {
        switch defaultChartStyle {
        case .radar: return "Radar"
        case .bar: return "Bar"
        case .line: return "Line"
        case .area: return "Area"
        }
    }
    
    private var defaultChartStyleIcon: String {
        switch defaultChartStyle {
        case .radar: return "circle.hexagonpath"
        case .bar: return "chart.bar"
        case .line: return "chart.line.uptrend.xyaxis"
        case .area: return "chart.area.stack"
        }
    }
    
    // MARK: - Tab Views
    
    private var radarChartView: some View {
        VStack {
            Text("Cognitive Profile Radar")
                .font(.headline)
                .padding(.bottom)
            
            // Using the existing StateComparisonRadar if available, or a placeholder
            if let stateComparisonRadar = createStateComparisonRadar() {
                stateComparisonRadar
                    .frame(height: 300)
            } else {
                Text("Radar chart not available")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(profileDataPoints) { point in
                    HStack {
                        Circle()
                            .fill(colorForParameter(point.parameter))
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
    
    private var chart3DView: some View {
        VStack {
            Text("3D Profile Visualization")
                .font(.headline)
                .padding(.bottom)
            
            Chart(profileDataPoints) { point in
                PointMark(
                    x: .value("Parameter", point.parameter),
                    y: .value("Score", point.value)
                )
                .foregroundStyle(by: .value("Profile", "Current"))
                .symbolSize(100)
                .symbol {
                    Circle()
                        .fill(colorForParameter(point.parameter))
                        .frame(width: 10, height: 10)
                        .shadow(radius: 3)
                }
            }
            .chartYScale(domain: 0...100)
            .chartLegend(.hidden)
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
                
                Text("This visualization shows the relative strengths of each cognitive parameter. The higher the point, the stronger that parameter is in your profile.")
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
                // Epsilon Line
                ForEach(historicalData) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Score", point.epsilon)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol {
                        Circle()
                            .strokeBorder(lineWidth: 2)
                            .foregroundStyle(.blue)
                            .frame(width: 6, height: 6)
                    }
                }
                
                // Precision Line
                ForEach(historicalData) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Score", point.precision)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol {
                        Diamond()
                            .stroke(lineWidth: 2)
                            .foregroundStyle(.green)
                            .frame(width: 6, height: 6)
                    }
                }
                
                // Threshold Line
                ForEach(historicalData) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Score", point.threshold)
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol {
                        Square()
                            .stroke(lineWidth: 2)
                            .foregroundStyle(.orange)
                            .frame(width: 6, height: 6)
                    }
                }
                
                // Somatic Bias Line
                ForEach(historicalData) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Score", point.somaticBias)
                    )
                    .foregroundStyle(.purple)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol {
                        Triangle()
                            .stroke(lineWidth: 2)
                            .foregroundStyle(.purple)
                            .frame(width: 6, height: 6)
                    }
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
                        AxisGridLine()
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 300)
            .padding()
            
            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .blue, label: "ε (Epsilon)")
                LegendItem(color: .green, label: "π (Precision)")
                LegendItem(color: .orange, label: "θₜ (Threshold)")
                LegendItem(color: .purple, label: "β (Somatic Bias)")
            }
            .padding()
        }
    }
    
    private var comparisonMatrixView: some View {
        let comparisonHeight = 200 + CGFloat(comparisonProfiles.count) * 40
        
        return VStack {
            Text("Profile Comparison")
                .font(.headline)
                .padding(.bottom)
            
            Chart(comparisonData) { dataPoint in
                RectangleMark(
                    x: .value("Parameter", dataPoint.parameter),
                    y: .value("Profile", dataPoint.profileName),
                    width: .ratio(0.8),
                    height: .ratio(0.8)
                )
                .foregroundStyle(by: .value("Value", dataPoint.value))
                .cornerRadius(4)
                .annotation(position: .overlay) {
                    Text("\(Int(dataPoint.value))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(dataPoint.value > 70 ? .white : .primary)
                }
            }
            .chartXAxis {
                AxisMarks(preset: .aligned, position: .bottom) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(preset: .aligned, position: .leading) { value in
                    AxisValueLabel()
                }
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.red, Color.yellow, Color.green],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(height: comparisonHeight)
            .padding()
            
            Text("Comparison shows your current profile against up to 3 other profiles")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    // MARK: - Additional Chart Views
    
    private var barChartView: some View {
        VStack {
            Text("Parameter Bar Chart")
                .font(.headline)
                .padding(.bottom)
            
            Chart(profileDataPoints) { point in
                BarMark(
                    x: .value("Parameter", point.parameter),
                    y: .value("Score", point.value)
                )
                .foregroundStyle(colorForParameter(point.parameter))
                .opacity(0.8)
            }
            .chartYScale(domain: 0...100)
            .chartLegend(.hidden)
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
                ForEach(profileDataPoints) { point in
                    HStack {
                        Circle()
                            .fill(colorForParameter(point.parameter))
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
    
    private var lineChartView: some View {
        VStack {
            Text("Parameter Line Chart")
                .font(.headline)
                .padding(.bottom)
            
            Chart(profileDataPoints) { point in
                LineMark(
                    x: .value("Parameter", point.parameter),
                    y: .value("Score", point.value)
                )
                .foregroundStyle(colorForParameter(point.parameter))
                .lineStyle(StrokeStyle(lineWidth: 3))
                .symbol {
                    Circle()
                        .fill(colorForParameter(point.parameter))
                        .frame(width: 8, height: 8)
                }
            }
            .chartYScale(domain: 0...100)
            .chartLegend(.hidden)
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
                ForEach(profileDataPoints) { point in
                    HStack {
                        Circle()
                            .fill(colorForParameter(point.parameter))
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
    
    private var areaChartView: some View {
        VStack {
            Text("Parameter Area Chart")
                .font(.headline)
                .padding(.bottom)
            
            Chart(profileDataPoints) { point in
                AreaMark(
                    x: .value("Parameter", point.parameter),
                    y: .value("Score", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [colorForParameter(point.parameter).opacity(0.6), colorForParameter(point.parameter).opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartYScale(domain: 0...100)
            .chartLegend(.hidden)
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
                ForEach(profileDataPoints) { point in
                    HStack {
                        Circle()
                            .fill(colorForParameter(point.parameter))
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
    
    // MARK: - Helper Methods
    
    private func colorForParameter(_ parameter: String) -> Color {
        switch parameter {
        case "ε (Epsilon)": return .blue
        case "π (Precision)": return .green
        case "θₜ (Threshold)": return .orange
        case "β (Somatic Bias)": return .purple
        default: return .gray
        }
    }
    
    private func createStateComparisonRadar() -> StateComparisonRadar? {
        // Check if StateComparisonRadar exists and can be initialized with the current data
        // This is a placeholder - you'll need to adapt this to work with your actual StateComparisonRadar implementation
        return nil
    }
}

// MARK: - Supporting Views

private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
        }
    }
}

// MARK: - Shape Extensions for Chart Symbols

// MARK: - Preview

struct EnhancedProfileChart_Previews: PreviewProvider {
    static var previews: some View {
        let previewProfile = APGIProfile(
            epsilon: 65.0,
            precision: 45.0,
            threshold: 55.0,
            somaticBias: 60.0,
            interactionScore: 70.0,
            temporalStability: 0.7,
            environmentalFit: 0.8
        )
        
        let comparisonProfiles = [
            APGIProfile(
                epsilon: 65.0,
                precision: 70.0,
                threshold: 50.0,
                somaticBias: 60.0,
                interactionScore: 70.0,
                temporalStability: 0.7,
                environmentalFit: 0.8
            )
        ]
        
        return EnhancedProfileChart(profile: previewProfile, comparisonProfiles: comparisonProfiles)
            .preferredColorScheme(.dark)
    }
}
