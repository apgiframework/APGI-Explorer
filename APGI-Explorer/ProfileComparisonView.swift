import SwiftUI
import Charts

struct ProfileComparisonView: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @Environment(\.appDependencies) private var dependencies
    @State private var selectedProfile1: String = ""
    @State private var selectedProfile2: String = ""
    @AppStorage("defaultComparisonMode") private var comparisonMode: ComparisonMode = .radar
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showExportSheet = false
    @State private var exportData: Data?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
                
                // Profile Selection Cards
                HStack(spacing: 20) {
                    profileSelectionCard(profile: $selectedProfile1, title: "Profile 1")
                    profileSelectionCard(profile: $selectedProfile2, title: "Profile 2")
                }
                .padding(.horizontal)
                
                // Comparison Mode Picker with Icons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Visualization")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("Comparison Mode", selection: $comparisonMode) {
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
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error: error)
                } else if !selectedProfile1.isEmpty && !selectedProfile2.isEmpty {
                    comparisonChart
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    
                    comparisonSummary
                        .padding(.top, 10)
                } else {
                    emptyStateView
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: exportComparison) {
                        Label("Export as Image", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { showExportSheet = true }) {
                        Label("Export as PDF", systemImage: "doc.text")
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(selectedProfile1.isEmpty || selectedProfile2.isEmpty)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let exportData = exportData {
                ShareSheet(items: [exportData])
            }
        }
    }
    
    @ViewBuilder
    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Comparison: \(selectedProfile1) vs \(selectedProfile2)")
                    .font(.headline)
                
                Spacer()
                
                Text(comparisonMode.rawValue + " View")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                
                VStack {
                    switch comparisonMode {
                    case .radar:
                        RadarComparisonChart(profile1: selectedProfile1, profile2: selectedProfile2)
                            .frame(height: 350)
                            .padding()
                    case .bar:
                        BarComparisonChart(profile1: selectedProfile1, profile2: selectedProfile2)
                            .frame(height: 350)
                            .padding()
                    case .line:
                        LineComparisonChart(profile1: selectedProfile1, profile2: selectedProfile2)
                            .frame(height: 350)
                            .padding()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
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
                
                Text("Select two profiles to begin comparing their psychological parameters and gain insights into their differences and similarities.")
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
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Analyzing Profiles...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    @ViewBuilder
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
                    await loadProfiles()
                }
            }
            .buttonStyle(.bordered)
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding()
    }
    
    @ViewBuilder
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
                    // Example key differences - replace with real data
                    differenceItem(
                        title: "Emotional Stability",
                        value1: 75,
                        value2: 45,
                        isHigherBetter: true
                    )
                    
                    differenceItem(
                        title: "Openness to Experience",
                        value1: 60,
                        value2: 80,
                        isHigherBetter: true
                    )
                    
                    differenceItem(
                        title: "Anxiety Level",
                        value1: 30,
                        value2: 65,
                        isHigherBetter: false
                    )
                }
                .padding()
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func profileSelectionCard(profile: Binding<String>, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Menu {
                Button(action: { profile.wrappedValue = "" }) {
                    Label("Select Profile...", systemImage: "person.crop.circle")
                }
                
                Divider()
                
                ForEach(getAvailableProfiles(), id: \.self) { profileName in
                    Button(action: { profile.wrappedValue = profileName }) {
                        HStack {
                            Text(profileName)
                            if profile.wrappedValue == profileName {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(profile.wrappedValue.isEmpty ? "Select Profile..." : profile.wrappedValue)
                        .foregroundColor(profile.wrappedValue.isEmpty ? .secondary : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private func differenceItem(title: String, value1: Int, value2: Int, isHigherBetter: Bool) -> some View {
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
                Text(selectedProfile1)
                    .font(.caption)
                    .frame(width: 80, alignment: .leading)
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: max(0, min(geometry.size.width - 60, (geometry.size.width - 60) * CGFloat(max(0, min(100, value1))) / 100)), height: 8)
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
                Text(selectedProfile2)
                    .font(.caption)
                    .frame(width: 80, alignment: .leading)
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.orange.opacity(0.7))
                            .frame(width: max(0, min(geometry.size.width - 60, (geometry.size.width - 60) * CGFloat(max(0, min(100, value2))) / 100)), height: 8)
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
    
    private func getAvailableProfiles() -> [String] {
        return profileManager.profiles.map { $0.name }.sorted()
    }
    
    private func performComparison() {
        // Reset state
        isLoading = true
        error = nil
        
        // Simulate network/database call
        let workItem = DispatchWorkItem {
            self.isLoading = false
            
            // Log analytics
            dependencies.getAnalyticsService().track(event: .comparisonStarted(profileTypes: [
                APGIProfileType(rawValue: self.selectedProfile1) ?? .openExplorer,
                APGIProfileType(rawValue: self.selectedProfile2) ?? .openExplorer
            ]))
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
        await profileManager.loadProfiles()
    }
}

// MARK: - Comparison Chart Views
struct RadarComparisonChart: View {
    let profile1: String
    let profile2: String
    
    // Sample data - replace with real profile data
    private var data: [RadarData] {
        let categories = ["Openness", "Conscientiousness", "Extraversion", "Agreeableness", "Neuroticism"]
        
        // Generate random data for demo
        return categories.map { category in
            RadarData(
                category: category,
                value1: Double.random(in: 30...100),
                value2: Double.random(in: 30...100)
            )
        }
    }
    
    var body: some View {
        VStack {
            // Simple radar chart implementation
            ZStack {
                // Background grid
                ForEach(0..<5) { i in
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        .frame(width: CGFloat(i + 1) * 50, height: CGFloat(i + 1) * 50)
                }
                
                // Axis lines
                ForEach(0..<5) { i in
                    let angle = Double(i) * (2 * .pi / 5)
                    Path { path in
                        path.move(to: .zero)
                        path.addLine(to: CGPoint(x: 150 * cos(angle), y: 150 * sin(angle)))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
                
                // Data points and lines
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    let angle = Double(index) * (2 * .pi / 5) - .pi / 2
                    let radius1 = item.value1 * 1.2
                    let radius2 = item.value2 * 1.2
                    
                    // Profile 1 line
                    Path { path in
                        path.move(to: .zero)
                        path.addLine(to: CGPoint(
                            x: radius1 * cos(angle),
                            y: radius1 * sin(angle)
                        ))
                    }
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    
                    // Profile 2 line
                    Path { path in
                        path.move(to: .zero)
                        path.addLine(to: CGPoint(
                            x: radius2 * cos(angle),
                            y: radius2 * sin(angle)
                        ))
                    }
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    
                    // Data points
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .position(x: radius1 * cos(angle), y: radius1 * sin(angle))
                    
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .position(x: radius2 * cos(angle), y: radius2 * sin(angle))
                    
                    // Category labels
                    Text(item.category)
                        .font(.caption2)
                        .position(
                            x: 170 * cos(angle),
                            y: 170 * sin(angle)
                        )
                }
                
                // Connect the dots for profile 1
                Path { path in
                    for (index, item) in data.enumerated() {
                        let angle = Double(index) * (2 * .pi / 5) - .pi / 2
                        let radius = item.value1 * 1.2
                        let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
                        
                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .stroke(Color.blue, lineWidth: 2)
                .opacity(0.7)
                
                // Connect the dots for profile 2
                Path { path in
                    for (index, item) in data.enumerated() {
                        let angle = Double(index) * (2 * .pi / 5) - .pi / 2
                        let radius = item.value2 * 1.2
                        let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
                        
                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .stroke(Color.orange, lineWidth: 2)
                .opacity(0.7)
            }
            .frame(width: 400, height: 400)
            
            // Legend
            HStack(spacing: 20) {
                legendItem(color: .blue, label: profile1)
                legendItem(color: .orange, label: profile2)
            }
            .padding(.top, 10)
        }
    }
    
    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

struct BarComparisonChart: View {
    let profile1: String
    let profile2: String
    
    // Sample data - replace with real profile data
    private var data: [BarData] {
        [
            ("Openness", 75, 60),
            ("Conscientiousness", 65, 80),
            ("Extraversion", 50, 70),
            ("Agreeableness", 80, 65),
            ("Neuroticism", 40, 55)
        ].map { BarData(category: $0.0, value1: $0.1, value2: $0.2) }
    }
    
    var body: some View {
        VStack {
            Chart {
                ForEach(data) { item in
                    // Profile 1 bars
                    BarMark(
                        x: .value("Category", item.category),
                        y: .value("Value", item.value1)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .position(by: .value("Profile", profile1))
                    .cornerRadius(4)
                    
                    // Profile 2 bars
                    BarMark(
                        x: .value("Category", item.category),
                        y: .value("Value", item.value2)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .position(by: .value("Profile", profile2))
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
                    ForEach([(Color.blue, profile1), (Color.orange, profile2)], id: \.1) { color, label in
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
    let profile1: String
    let profile2: String
    
    // Sample data - replace with real profile data
    private var data: [LineData] {
        [
            ("Week 1", 60, 40),
            ("Week 2", 55, 45),
            ("Week 3", 70, 50),
            ("Week 4", 65, 60),
            ("Week 5", 75, 55),
            ("Week 6", 80, 70)
        ].map { LineData(period: $0.0, value1: $0.1, value2: $0.2) }
    }
    
    var body: some View {
        VStack {
            Chart {
                // Profile 1 line
                ForEach(data) { item in
                    LineMark(
                        x: .value("Period", item.period),
                        y: .value("Score", item.value1)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .symbol(Circle().strokeBorder(lineWidth: 1))
                    .interpolationMethod(.catmullRom)
                }
                .foregroundStyle(by: .value("Profile", profile1))
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                // Profile 2 line
                ForEach(data) { item in
                    LineMark(
                        x: .value("Period", item.period),
                        y: .value("Score", item.value2)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .symbol(Circle().strokeBorder(lineWidth: 1))
                    .interpolationMethod(.catmullRom)
                }
                .foregroundStyle(by: .value("Profile", profile2))
                .lineStyle(StrokeStyle(lineWidth: 3))
            }
            .chartXAxis {
                AxisMarks { value in
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
                    ForEach([(Color.blue, profile1), (Color.orange, profile2)], id: \.1) { color, label in
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
