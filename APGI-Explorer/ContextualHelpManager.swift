import SwiftUI
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Contextual Help System

class ContextualHelpManager: ObservableObject {
    static let shared = ContextualHelpManager()

    @Published var currentHelpContext: HelpContext?
    @Published var isHelpVisible = false
    @Published var completedTutorials: Set<String> = []
    @Published var availableTutorials: [Tutorial] = []

    private init() {
        loadCompletedTutorials()
        setupAvailableTutorials()
    }

    func showHelp(for context: HelpContext) {
        currentHelpContext = context
        isHelpVisible = true
        HapticFeedback.shared.lightImpact()
    }

    func dismissHelp() {
        isHelpVisible = false
        currentHelpContext = nil
    }

    func markTutorialCompleted(_ tutorialId: String) {
        completedTutorials.insert(tutorialId)
        saveCompletedTutorials()
    }

    func isTutorialCompleted(_ tutorialId: String) -> Bool {
        completedTutorials.contains(tutorialId)
    }

    func getTutorial(for context: HelpContext) -> Tutorial? {
        return availableTutorials.first { $0.contexts.contains(context) }
    }

    private func loadCompletedTutorials() {
        if let data = UserDefaults.standard.data(forKey: "completedTutorials"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedTutorials = decoded
        }
    }

    private func saveCompletedTutorials() {
        if let encoded = try? JSONEncoder().encode(completedTutorials) {
            UserDefaults.standard.set(encoded, forKey: "completedTutorials")
        }
    }

    private func setupAvailableTutorials() {
        availableTutorials = [
            createProfileCreationTutorial(),
            createProfileComparisonTutorial(),
            createDataExportTutorial(),
            createAppSettingsTutorial(),
            createAdvancedFeaturesTutorial()
        ]
    }

    private func createProfileCreationTutorial() -> Tutorial {
        Tutorial(
            id: "profile_creation",
            title: "Creating Profiles",
            description: "Learn how to create and manage psychological profiles",
            contexts: [.profileCreation, .profileManagement],
            steps: [
                TutorialStep(
                    title: "Start the Quiz",
                    content: "Tap the 'Start Quiz' button to begin your psychological assessment.",
                    highlightElement: "start_quiz_button"
                ),
                TutorialStep(
                    title: "Answer Questions",
                    content: "Answer each question honestly. Your responses help generate accurate profiles.",
                    highlightElement: "quiz_options"
                ),
                TutorialStep(
                    title: "Review Results",
                    content: "After completing the quiz, review your generated profile and insights.",
                    highlightElement: "results_view"
                ),
                TutorialStep(
                    title: "Save Your Profile",
                    content: "Give your profile a name and save it for future reference.",
                    highlightElement: "save_profile_button"
                )
            ]
        )
    }

    private func createProfileComparisonTutorial() -> Tutorial {
        Tutorial(
            id: "profile_comparison",
            title: "Comparing Profiles",
            description: "Learn how to compare different psychological profiles",
            contexts: [.profileComparison, .profileAnalysis],
            steps: [
                TutorialStep(
                    title: "Select Profiles",
                    content: "Choose two or more profiles to compare from your profile list.",
                    highlightElement: "profile_selection"
                ),
                TutorialStep(
                    title: "View Comparison",
                    content: "See the similarities and differences between selected profiles.",
                    highlightElement: "comparison_chart"
                ),
                TutorialStep(
                    title: "Analyze Insights",
                    content: "Review the detailed analysis and psychological insights.",
                    highlightElement: "insights_panel"
                )
            ]
        )
    }

    private func createDataExportTutorial() -> Tutorial {
        Tutorial(
            id: "data_export",
            title: "Exporting Data",
            description: "Learn how to export your profiles and data",
            contexts: [.dataExport, .dataManagement],
            steps: [
                TutorialStep(
                    title: "Choose Export Format",
                    content: "Select the format you want to export your data in.",
                    highlightElement: "format_picker"
                ),
                TutorialStep(
                    title: "Configure Options",
                    content: "Choose what data to include and export quality settings.",
                    highlightElement: "export_options"
                ),
                TutorialStep(
                    title: "Export File",
                    content: "Generate and save your export file to your device.",
                    highlightElement: "export_button"
                )
            ]
        )
    }

    private func createAppSettingsTutorial() -> Tutorial {
        Tutorial(
            id: "app_settings",
            title: "App Settings",
            description: "Learn about the various settings and customization options",
            contexts: [.settings, .privacy],
            steps: [
                TutorialStep(
                    title: "Profile Settings",
                    content: "Configure default profile names and auto-save options.",
                    highlightElement: "profile_settings"
                ),
                TutorialStep(
                    title: "Data Management",
                    content: "Manage data retention, backups, and privacy settings.",
                    highlightElement: "data_management"
                ),
                TutorialStep(
                    title: "Appearance",
                    content: "Customize themes, colors, and display preferences.",
                    highlightElement: "appearance_settings"
                )
            ]
        )
    }

    private func createAdvancedFeaturesTutorial() -> Tutorial {
        Tutorial(
            id: "advanced_features",
            title: "Advanced Features",
            description: "Explore advanced features and power user tools",
            contexts: [.advancedFeatures, .charts, .analytics],
            steps: [
                TutorialStep(
                    title: "Interactive Charts",
                    content: "Learn how to interact with and customize psychological charts.",
                    highlightElement: "interactive_charts"
                ),
                TutorialStep(
                    title: "Data Analysis",
                    content: "Use advanced analysis tools to gain deeper insights.",
                    highlightElement: "analysis_tools"
                ),
                TutorialStep(
                    title: "Keyboard Shortcuts",
                    content: "Master keyboard shortcuts for faster navigation.",
                    highlightElement: "keyboard_help"
                )
            ]
        )
    }
}

// MARK: - Help Models

enum HelpContext: String, CaseIterable, Codable {
    case profileCreation = "profile_creation"
    case profileManagement = "profile_management"
    case profileComparison = "profile_comparison"
    case profileAnalysis = "profile_analysis"
    case dataExport = "data_export"
    case dataImport = "data_import"
    case dataManagement = "data_management"
    case settings = "settings"
    case privacy = "privacy"
    case charts = "charts"
    case analytics = "analytics"
    case advancedFeatures = "advanced_features"
    case quiz = "quiz"
    case results = "results"

    var title: String {
        switch self {
        case .profileCreation: return "Profile Creation"
        case .profileManagement: return "Profile Management"
        case .profileComparison: return "Profile Comparison"
        case .profileAnalysis: return "Profile Analysis"
        case .dataExport: return "Data Export"
        case .dataImport: return "Data Import"
        case .dataManagement: return "Data Management"
        case .settings: return "Settings"
        case .privacy: return "Privacy"
        case .charts: return "Charts"
        case .analytics: return "Analytics"
        case .advancedFeatures: return "Advanced Features"
        case .quiz: return "Quiz"
        case .results: return "Results"
        }
    }

    var description: String {
        switch self {
        case .profileCreation: return "Help with creating new psychological profiles"
        case .profileManagement: return "Managing and organizing your profiles"
        case .profileComparison: return "Comparing multiple profiles"
        case .profileAnalysis: return "Analyzing profile data and insights"
        case .dataExport: return "Exporting profiles and data"
        case .dataImport: return "Importing data from other sources"
        case .dataManagement: return "Managing app data and storage"
        case .settings: return "App configuration and preferences"
        case .privacy: return "Privacy settings and data protection"
        case .charts: return "Understanding and using charts"
        case .analytics: return "Analytics and insights"
        case .advancedFeatures: return "Advanced features and tools"
        case .quiz: return "Taking psychological assessments"
        case .results: return "Understanding quiz results"
        }
    }
}

struct Tutorial: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let contexts: [HelpContext]
    let steps: [TutorialStep]

    var estimatedDuration: String {
        let minutes = steps.count * 2
        return "\(minutes) minutes"
    }

    var isCompleted: Bool {
        ContextualHelpManager.shared.isTutorialCompleted(id)
    }
}

struct TutorialStep: Identifiable, Codable {
    let id = UUID()
    let title: String
    let content: String
    let highlightElement: String?

    enum CodingKeys: String, CodingKey {
        case title, content, highlightElement
    }
}

// MARK: - Contextual Help Views

struct ContextualHelpButton: View {
    let context: HelpContext
    @StateObject private var helpManager = ContextualHelpManager.shared

    var body: some View {
        Button(action: {
            helpManager.showHelp(for: context)
        }) {
            Image(systemName: "questionmark.circle")
                .font(.title3)
                .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Get help for \(context.title)")
        .accessibilityHint("Show contextual help and tutorials")
    }
}

struct ContextualHelpOverlay: View {
    @StateObject private var helpManager = ContextualHelpManager.shared
    @State private var currentStepIndex = 0
    @State private var isAnimating = false

    var body: some View {
        if helpManager.isHelpVisible, let context = helpManager.currentHelpContext,
           let tutorial = helpManager.getTutorial(for: context) {

            ZStack {
                // Dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        helpManager.dismissHelp()
                    }

                // Help content
                VStack(spacing: 0) {
                    // Header
                    helpHeader

                    // Content
                    helpContent(tutorial: tutorial)

                    // Navigation
                    helpNavigation(tutorial: tutorial)
                }
                .background(
                    Group {
                        #if os(iOS)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                        #elseif os(macOS)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                        #endif
                    }
                )
                .padding(.horizontal, 20)
            }
            .transition(.opacity.combined(with: .scale))
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }

    @ViewBuilder
    private var helpHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(helpManager.currentHelpContext?.title ?? "")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Interactive Tutorial")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                helpManager.dismissHelp()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close help")
        }
        .padding()
        .background(
            Group {
                #if os(iOS)
                Color(UIColor.systemBackground)
                #elseif os(macOS)
                Color(NSColor.windowBackgroundColor)
                #endif
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func helpContent(tutorial: Tutorial) -> some View {
        if currentStepIndex < tutorial.steps.count {
            let step = tutorial.steps[currentStepIndex]

            VStack(spacing: 20) {
                // Progress indicator
                ProgressView(value: Double(currentStepIndex + 1), total: Double(tutorial.steps.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))

                // Step content
                VStack(spacing: 16) {
                    Text("Step \(currentStepIndex + 1) of \(tutorial.steps.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(step.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text(step.content)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private func helpNavigation(tutorial: Tutorial) -> some View {
        HStack(spacing: 16) {
            // Previous button
            Button(action: {
                if currentStepIndex > 0 {
                    currentStepIndex -= 1
                    HapticFeedback.shared.selectionChanged()
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
            }
            .disabled(currentStepIndex == 0)
            .buttonStyle(SecondaryButtonStyle())

            // Skip button
            Button("Skip Tutorial") {
                helpManager.dismissHelp()
                HapticFeedback.shared.lightImpact()
            }
            .buttonStyle(SecondaryButtonStyle())

            // Next/Complete button
            Button(action: {
                if currentStepIndex < tutorial.steps.count - 1 {
                    currentStepIndex += 1
                    HapticFeedback.shared.selectionChanged()
                } else {
                    completeTutorial(tutorial)
                }
            }) {
                HStack {
                    Text(currentStepIndex < tutorial.steps.count - 1 ? "Next" : "Complete")
                    if currentStepIndex < tutorial.steps.count - 1 {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(
            Group {
                #if os(iOS)
                Color(UIColor.systemBackground)
                #elseif os(macOS)
                Color(NSColor.windowBackgroundColor)
                #endif
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func completeTutorial(_ tutorial: Tutorial) {
        helpManager.markTutorialCompleted(tutorial.id)
        helpManager.dismissHelp()
        #if os(iOS)
        HapticFeedback.shared.notification(.success)
        #endif
    }
}

struct HelpCenterView: View {
    @StateObject private var helpManager = ContextualHelpManager.shared
    @State private var selectedCategory: HelpCategory?

    enum HelpCategory: String, CaseIterable {
        case gettingStarted = "getting_started"
        case profiles = "profiles"
        case comparison = "comparison"
        case data = "data"
        case settings = "settings"
        case advanced = "advanced"

        var title: String {
            switch self {
            case .gettingStarted: return "Getting Started"
            case .profiles: return "Profiles"
            case .comparison: return "Comparison"
            case .data: return "Data Management"
            case .settings: return "Settings"
            case .advanced: return "Advanced Features"
            }
        }

        var description: String {
            switch self {
            case .gettingStarted: return "Learn the basics of APGI Explorer"
            case .profiles: return "Creating and managing psychological profiles"
            case .comparison: return "Comparing profiles and analyzing differences"
            case .data: return "Import, export, and manage your data"
            case .settings: return "Configure the app to your preferences"
            case .advanced: return "Power user features and tools"
            }
        }

        var icon: String {
            switch self {
            case .gettingStarted: return "play.circle.fill"
            case .profiles: return "person.crop.circle.fill"
            case .comparison: return "person.2.fill"
            case .data: return "doc.text.fill"
            case .settings: return "gearshape.fill"
            case .advanced: return "star.fill"
            }
        }

        var contexts: [HelpContext] {
            switch self {
            case .gettingStarted: return [.profileCreation, .quiz, .results]
            case .profiles: return [.profileManagement, .profileAnalysis]
            case .comparison: return [.profileComparison]
            case .data: return [.dataExport, .dataImport, .dataManagement]
            case .settings: return [.settings, .privacy]
            case .advanced: return [.advancedFeatures, .charts, .analytics]
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Quick Help
                    quickHelpSection

                    // Tutorial Categories
                    tutorialCategoriesSection

                    // Completed Tutorials
                    completedTutorialsSection
                }
                .padding()
            }
            .navigationTitle("Help Center")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }

    @ViewBuilder
    private var quickHelpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Help")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(HelpContext.allCases, id: \.self) { context in
                    QuickHelpCard(context: context)
                }
            }
        }
    }

    @ViewBuilder
    private var tutorialCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interactive Tutorials")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(HelpCategory.allCases, id: \.self) { category in
                CategoryCard(category: category)
            }
        }
    }

    @ViewBuilder
    private var completedTutorialsSection: some View {
        if !helpManager.completedTutorials.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Completed Tutorials")
                    .font(.title2)
                    .fontWeight(.bold)

                let completedTutorials = helpManager.availableTutorials.filter {
                    helpManager.completedTutorials.contains($0.id)
                }

                ForEach(completedTutorials) { tutorial in
                    CompletedTutorialCard(tutorial: tutorial)
                }
            }
        }
    }
}

struct QuickHelpCard: View {
    let context: HelpContext
    @StateObject private var helpManager = ContextualHelpManager.shared

    var body: some View {
        Button(action: {
            helpManager.showHelp(for: context)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(context.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

struct CategoryCard: View {
    let category: HelpCenterView.HelpCategory
    @StateObject private var helpManager = ContextualHelpManager.shared

    private var tutorialsInCategory: [Tutorial] {
        helpManager.availableTutorials.filter { tutorial in
            tutorial.contexts.contains { category.contexts.contains($0) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(category.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)

                    Text("\(tutorialsInCategory.count) tutorials")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }

                Spacer()
            }

            if !tutorialsInCategory.isEmpty {
                ForEach(tutorialsInCategory.prefix(3)) { tutorial in
                    TutorialRow(tutorial: tutorial)
                }

                if tutorialsInCategory.count > 3 {
                    Button("View All (\(tutorialsInCategory.count))") {
                        // Show all tutorials in category
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(
            Group {
                #if os(iOS)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                #elseif os(macOS)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                #endif
            }
        )
    }
}

struct TutorialRow: View {
    let tutorial: Tutorial
    @StateObject private var helpManager = ContextualHelpManager.shared

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tutorial.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack {
                    Text(tutorial.estimatedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if tutorial.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            Button(tutorial.isCompleted ? "Review" : "Start") {
                if let firstContext = tutorial.contexts.first {
                    helpManager.showHelp(for: firstContext)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

struct CompletedTutorialCard: View {
    let tutorial: Tutorial

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(tutorial.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("Completed on \(Date(), style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Review") {
                // Review tutorial
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
}

#Preview {
    HelpCenterView()
}
