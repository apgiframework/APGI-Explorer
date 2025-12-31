import SwiftUI
import Charts

struct ProfileComparisonView: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @Environment(\.appDependencies) private var dependencies
    @State private var selectedProfile1: QuizProfile?
    @State private var selectedProfile2: QuizProfile?
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
                } else if selectedProfile1 != nil && selectedProfile2 != nil {
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
                .disabled(selectedProfile1 == nil || selectedProfile2 == nil)
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
                Text("Comparison: \(selectedProfile1?.name ?? "Unknown") vs \(selectedProfile2?.name ?? "Unknown")")
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
                        if let profile1 = selectedProfile1, let profile2 = selectedProfile2 {
                            RadarComparisonChart(profile1: profile1, profile2: profile2)
                                .frame(height: 350)
                                .padding()
                        }
                    case .bar:
                        if let profile1 = selectedProfile1, let profile2 = selectedProfile2 {
                            BarComparisonChart(profile1: profile1, profile2: profile2)
                                .frame(height: 350)
                                .padding()
                        }
                    case .line:
                        if let profile1 = selectedProfile1, let profile2 = selectedProfile2 {
                            LineComparisonChart(profile1: profile1, profile2: profile2)
                                .frame(height: 350)
                                .padding()
                        }
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
                    if let profile1 = selectedProfile1, let profile2 = selectedProfile2 {
                        let apgiProfile1 = QuizModel.calculateAPGIProfile(from: profile1.results)
                        let apgiProfile2 = QuizModel.calculateAPGIProfile(from: profile2.results)
                        
                        differenceItem(
                            title: "Epsilon (Prediction Error)",
                            value1: Int(apgiProfile1.epsilon),
                            value2: Int(apgiProfile2.epsilon),
                            isHigherBetter: false
                        )
                        
                        differenceItem(
                            title: "Precision",
                            value1: Int(apgiProfile1.precision),
                            value2: Int(apgiProfile2.precision),
                            isHigherBetter: true
                        )
                        
                        differenceItem(
                            title: "Threshold",
                            value1: Int(apgiProfile1.threshold),
                            value2: Int(apgiProfile2.threshold),
                            isHigherBetter: true
                        )
                        
                        differenceItem(
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
    
    @ViewBuilder
    private func profileSelectionCard(profile: Binding<QuizProfile?>, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Menu {
                Button(action: { profile.wrappedValue = nil }) {
                    Label("Select Profile...", systemImage: "person.crop.circle")
                }
                
                Divider()
                
                ForEach(getAvailableProfiles(), id: \.id) { quizProfile in
                    Button(action: { profile.wrappedValue = quizProfile }) {
                        HStack {
                            Text(quizProfile.name)
                            if profile.wrappedValue?.id == quizProfile.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
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
                Text(selectedProfile1?.name ?? "Profile 1")
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
                Text(selectedProfile2?.name ?? "Profile 2")
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
    
    private func getAvailableProfiles() -> [QuizProfile] {
        return profileManager.profiles.sorted { $0.name < $1.name }
    }
    
    private func performComparison() {
        // Reset state
        isLoading = true
        error = nil
        
        // Simulate network/database call
        let workItem = DispatchWorkItem {
            self.isLoading = false
            
            // Log analytics if profiles are selected
            if let profile1 = self.selectedProfile1, let profile2 = self.selectedProfile2 {
                let profileType1 = APGIProfileType(rawValue: profile1.name) ?? .openExplorer
                let profileType2 = APGIProfileType(rawValue: profile2.name) ?? .openExplorer
                
                self.dependencies.getAnalyticsService().track(event: .comparisonStarted(profileTypes: [profileType1, profileType2]))
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
        await profileManager.loadProfiles()
    }
}

// MARK: - Comparison Chart Views
struct RadarComparisonChart: View {
    let profile1: QuizProfile
    let profile2: QuizProfile
    
    private var apgiProfile1: APGIProfile {
        QuizModel.calculateAPGIProfile(from: profile1.results)
    }
    
    private var apgiProfile2: APGIProfile {
        QuizModel.calculateAPGIProfile(from: profile2.results)
    }
    
    // Real data from profiles
    private var data: [RadarData] {
        let categories = ["Epsilon", "Precision", "Threshold", "Somatic Bias"]
        
        return categories.enumerated().map { index, category in
            let value1: Double
            let value2: Double
            
            switch index {
            case 0: // Epsilon
                value1 = apgiProfile1.epsilon
                value2 = apgiProfile2.epsilon
            case 1: // Precision
                value1 = apgiProfile1.precision
                value2 = apgiProfile2.precision
            case 2: // Threshold
                value1 = apgiProfile1.threshold
                value2 = apgiProfile2.threshold
            case 3: // Somatic Bias
                value1 = apgiProfile1.somaticBias
                value2 = apgiProfile2.somaticBias
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
                backgroundGrid
                axisLines
                dataPolygons
                dataPoints
                categoryLabels
            }
            .frame(width: 420, height: 420)
            
            // Legend with improved styling
            legendView
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundGrid: some View {
        ForEach(1...5, id: \.self) { i in
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                .frame(width: CGFloat(i) * 60, height: CGFloat(i) * 60)
        }
    }
    
    private var axisLines: some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, item in
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
            filledProfilePolygon(for: data.map(\.value1), color: Color.blue.opacity(0.15))
            
            // Profile 2 filled area
            filledProfilePolygon(for: data.map(\.value2), color: Color.orange.opacity(0.15))
            
            // Profile 1 outline
            outlinedProfilePolygon(for: data.map(\.value1), color: Color.blue, lineWidth: 2.5, opacity: 0.8)
            
            // Profile 2 outline
            outlinedProfilePolygon(for: data.map(\.value2), color: Color.orange, lineWidth: 2.5, opacity: 0.8)
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
    
    private func outlinedProfilePolygon(for values: [Double], color: Color, lineWidth: CGFloat, opacity: Double) -> some View {
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
        ForEach(Array(data.enumerated()), id: \.offset) { index, item in
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
        ForEach(Array(data.enumerated()), id: \.offset) { index, item in
            categoryLabelForItem(index: index, item: item)
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
            legendItem(color: .blue, label: profile1.name)
            legendItem(color: .orange, label: profile2.name)
        }
        .padding(.top, 15)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
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
        QuizModel.calculateAPGIProfile(from: profile1.results)
    }
    
    private var apgiProfile2: APGIProfile {
        QuizModel.calculateAPGIProfile(from: profile2.results)
    }
    
    // Real data from profiles
    private var data: [BarData] {
        [
            ("Epsilon", Int(apgiProfile1.epsilon), Int(apgiProfile2.epsilon)),
            ("Precision", Int(apgiProfile1.precision), Int(apgiProfile2.precision)),
            ("Threshold", Int(apgiProfile1.threshold), Int(apgiProfile2.threshold)),
            ("Somatic Bias", Int(apgiProfile1.somaticBias), Int(apgiProfile2.somaticBias))
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
                    .position(by: .value("Profile", profile1.name))
                    .cornerRadius(4)
                    
                    // Profile 2 bars
                    BarMark(
                        x: .value("Category", item.category),
                        y: .value("Value", item.value2)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .position(by: .value("Profile", profile2.name))
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
                    ForEach([(Color.blue, profile1.name), (Color.orange, profile2.name)], id: \.1) { color, label in
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
        QuizModel.calculateAPGIProfile(from: profile1.results)
    }
    
    private var apgiProfile2: APGIProfile {
        QuizModel.calculateAPGIProfile(from: profile2.results)
    }
    
    // Real data from profiles - showing parameter progression
    private var data: [LineData] {
        let parameters = ["Epsilon", "Precision", "Threshold", "Somatic Bias"]
        let values1 = [apgiProfile1.epsilon, apgiProfile1.precision, apgiProfile1.threshold, apgiProfile1.somaticBias]
        let values2 = [apgiProfile2.epsilon, apgiProfile2.precision, apgiProfile2.threshold, apgiProfile2.somaticBias]
        
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
                ForEach(data) { item in
                    LineMark(
                        x: .value("Period", item.period),
                        y: .value("Score", item.value1)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .symbol(Circle().strokeBorder(lineWidth: 1))
                    .interpolationMethod(.catmullRom)
                }
                .foregroundStyle(by: .value("Profile", profile1.name))
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
                .foregroundStyle(by: .value("Profile", profile2.name))
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
                    ForEach([(Color.blue, profile1.name), (Color.orange, profile2.name)], id: \.1) { color, label in
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
