import CloudKit
import SwiftUI

@main
struct APGI_Explorer_iOSApp: App {
    @StateObject private var cloudSyncManager = CloudSyncManager.shared
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.cloudSyncManager)
                .environmentObject(self.storeManager)
                .environmentObject(self.localizationManager)
                .onAppear {
                    self.setupApp()
                }
        }
    }

    private func setupApp() {
        // Load products
        Task {
            await self.storeManager.loadProducts()
            await self.cloudSyncManager.checkAccountStatus()
        }

        // Configure appearance
        self.configureAppearance()

        // Setup notifications
        self.setupNotifications()
    }

    private func configureAppearance() {
        // Configure navigation bar appearance for iOS
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
        ]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
        ]
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
        ]

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().compactAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                os_log("Notification permission granted")
            }
            else if let error {
                os_log("Notification permission error: %@", error.localizedDescription)
            }
        }
    }
}

// MARK: - iOS-Specific Extensions

extension View {
    func iOSNavigationStyle() -> some View {
        self.modifier(iOSNavigationModifier())
    }
}

struct iOSNavigationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Settings action
                        }) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
        else {
            content
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

// MARK: - iOS-Specific Components

struct iOSMainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: self.$selectedTab) {
            ProfilesView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Profiles")
                }
                .tag(0)

            QuizNavigationView()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Quiz")
                }
                .tag(1)

            ResultsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Results")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

// MARK: - iOS-Specific Profile Card

struct iOSProfileCard: View {
    let profile: ProfileEntity
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.profile.name ?? "Unknown Profile")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Created: \(self.profile.createdAt ?? Date(), style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let apgiType = profile.apgiType {
                        Text(apgiType)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }

                    ChevronRightIcon()
                        .foregroundColor(.secondary)
                }
            }

            if let overallScore = profile.overallScore {
                HStack {
                    Text("Overall Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(overallScore))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            self.onTap()
        }
    }
}

// MARK: - iOS-Specific Quiz Interface

struct iOSQuizView: View {
    @StateObject private var quizModel = QuizModel()
    @State private var showingResults = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress header
                QuizProgressHeader(
                    currentQuestion: self.quizModel.currentQuestionIndex + 1,
                    totalQuestions: self.quizModel.totalQuestions,
                    progress: self.quizModel.progress
                )
                .padding()
                .background(Color(.systemGroupedBackground))

                // Question content
                ScrollView {
                    VStack(spacing: 24) {
                        if let question = quizModel.currentQuestion {
                            QuestionCard(question: question) { answer in
                                self.quizModel.recordAnswer(answer)

                                if self.quizModel.isComplete {
                                    self.showingResults = true
                                }
                                else {
                                    self.quizModel.nextQuestion()
                                }
                            }
                        }
                    }
                    .padding()
                }

                Spacer()

                // Navigation buttons
                QuizNavigationButtons(
                    canGoBack: self.quizModel.canGoBack,
                    canGoNext: self.quizModel.canGoNext,
                    onBack: self.quizModel.previousQuestion,
                    onNext: self.quizModel.nextQuestion
                )
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("APGI Assessment")
            .navigationBarTitleDisplayMode(.large)
            .iOSNavigationStyle()
        }
        .fullScreenCover(isPresented: self.$showingResults) {
            ResultsView()
        }
    }
}

// MARK: - iOS-Specific Results View

struct iOSResultsView: View {
    @State private var selectedChart: ChartType = .radar

    enum ChartType: String, CaseIterable {
        case radar = "Radar"
        case bar = "Bar"
        case line = "Line"

        var systemImage: String {
            switch self {
            case .radar: "radar"
            case .bar: "chart.bar"
            case .line: "chart.line.uptrend.xyaxis"
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Chart type selector
                    Picker("Chart Type", selection: self.$selectedChart) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // Chart display
                    ChartContainer(chartType: self.selectedChart)
                        .frame(height: 300)
                        .padding(.horizontal)

                    // Score breakdown
                    ScoreBreakdownCard()
                        .padding(.horizontal)

                    // Export options
                    ExportOptionsCard()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.large)
            .iOSNavigationStyle()
        }
    }
}

// MARK: - Helper Views

struct ChartContainer: View {
    let chartType: iOSResultsView.ChartType

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .overlay(
                VStack {
                    Text("Chart: \(self.chartType.rawValue)")
                        .font(.headline)
                        .padding()

                    // Placeholder for chart implementation
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Text("Chart View")
                                .foregroundColor(.secondary)
                        )
                }
            )
    }
}

struct ScoreBreakdownCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Breakdown")
                .font(.headline)

            VStack(spacing: 12) {
                ScoreRow(title: "Autonomy", score: 75, color: .blue)
                ScoreRow(title: "Purposefulness", score: 82, color: .green)
                ScoreRow(title: "Self-Acceptance", score: 68, color: .orange)
                ScoreRow(title: "Personal Growth", score: 79, color: .purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ScoreRow: View {
    let title: String
    let score: Int
    let color: Color

    var body: some View {
        HStack {
            Text(self.title)
                .font(.subheadline)

            Spacer()

            Text("\(self.score)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(self.color)
        }
    }
}

struct ExportOptionsCard: View {
    @State private var selectedCategory: ExportCategory = .data
    @State private var selectedFormat: ExportFormat = .json
    @State private var showingExportSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Options")
                .font(.headline)

            // Category selector
            Picker("Category", selection: self.$selectedCategory) {
                ForEach(ExportCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            // Format selector for selected category
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(self.selectedCategory.formats, id: \.self) { format in
                    ExportButton(
                        title: format.rawValue,
                        icon: self.formatIcon(for: format),
                        color: self.formatColor(for: format),
                        format: format
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: self.$showingExportSheet) {
            // Export sheet will be implemented here
        }
    }

    private func formatIcon(for format: ExportFormat) -> String {
        switch format {
        case .pdf: "doc.pdf"
        case .json: "doc.plaintext"
        case .csv: "doc.text"
        case .png: "photo"
        case .excel: "spreadsheet"
        case .xml: "doc.text"
        case .spss: "chart.bar"
        case .stata: "chart.bar"
        case .rData: "chart.bar"
        case .bibTeX: "book"
        case .endNote: "book"
        case .apa, .mla: "doc.text"
        }
    }

    private func formatColor(for format: ExportFormat) -> Color {
        switch format {
        case .pdf: .red
        case .json: .blue
        case .csv: .green
        case .png: .purple
        case .excel: .green
        case .xml: .orange
        case .spss, .stata, .rData: .blue
        case .bibTeX, .endNote: .brown
        case .apa, .mla: .indigo
        }
    }
}

struct ExportButton: View {
    let title: String
    let icon: String
    let color: Color
    let format: ExportFormat

    var body: some View {
        Button(action: {
            self.exportProfile()
        }) {
            VStack(spacing: 8) {
                Image(systemName: self.icon)
                    .font(.title2)
                    .foregroundColor(self.color)

                Text(self.title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func exportProfile() {
        // Implement export functionality using ResearchExportManager
        Task {
            do {
                // This would need to be connected to the actual profile data
                // For now, showing a placeholder implementation
                os_log("Exporting profile as %@", self.format.rawValue)
            }
            catch {
                os_log("Export failed: %@", error.localizedDescription)
            }
        }
    }
}

struct ChevronRightIcon: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .fontWeight(.semibold)
    }
}
