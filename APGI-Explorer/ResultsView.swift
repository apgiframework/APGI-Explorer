import StoreKit
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

struct ResultsView: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @ObservedObject var quizModel: QuizModel
    @State private var profileName = ""
    @State private var showSavedAlert = false
    @State private var toast: ToastMessage?
    @State private var selectedTab = 0
    @StateObject private var stateModel = StateModel()
    @Environment(\.appDependencies) private var dependencies

    private var analytics: AnalyticsService {
        self.dependencies.getAnalyticsService()
    }

    private var apgiProfile: APGIProfile {
        self.quizModel.calculateScore().profile
    }

    private var profileType: APGIProfileType {
        self.profileManager.determineProfileType(for: self.apgiProfile)
    }

    private var profileColor: Color {
        switch self.profileType {
        case .sensitiveIntegrator: .orange
        case .analyticalGuard: .blue
        case .adaptiveBalancer: .green
        case .openExplorer: .pink
        case .contemplativeAnchor: .teal
        case .somaticNavigator: .purple
        case .cognitiveArchitect: .mint
        case .dynamicResponder: .red
        }
    }

    @State private var showingExportSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                self.profileHeaderView

                Picker("View", selection: self.$selectedTab) {
                    Text("Overview").tag(0)
                    Text("Details").tag(1)
                    Text("States").tag(2)
                    Text("Strategies").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Group {
                    switch self.selectedTab {
                    case 0: self.overviewTab
                    case 1: self.detailsTab
                    case 2: self.statesTab
                    case 3: self.strategiesTab
                    default: self.overviewTab
                    }
                }

                self.saveProfileSection
            }
            .padding()
        }
        .navigationTitle("Your APGI Profile")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                #if os(macOS)
                    ToolbarItem(placement: .automatic) {
                        Button(action: { self.showingExportSheet = true }, label: {
                            Image(systemName: "square.and.arrow.up")
                                .imageScale(.large)
                        })
                    }
                #else
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { self.showingExportSheet = true }, label: {
                            Image(systemName: "square.and.arrow.up")
                                .imageScale(.large)
                        })
                    }
                #endif
            }
            .sheet(isPresented: self.$showingExportSheet) {
                if #available(iOS 16.0, *) {
                    NavigationStack {
                        ExportView(profileManager: self.profileManager, profile: self.createTemporaryProfile())
                    }
                } else {
                    NavigationView {
                        ExportView(profileManager: self.profileManager, profile: self.createTemporaryProfile())
                    }
                }
            }
            .alert("Profile Saved!", isPresented: self.$showSavedAlert) {
                Button("OK", role: .cancel) {
                }
            } message: {
                Text("Your results have been saved to '\(self.profileName)'.")
            }
            .toast(self.$toast)
            .onAppear {
                self.analytics.track(event: .quizCompleted(profileType: self.profileType, score: self.quizModel.calculatePartialScore().epsilon, duration: 0))
                self.analytics.setUserProperty(self.profileType.rawValue, forKey: "recentProfileType")
            }
    }

    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            Text(self.profileType.rawValue)
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(self.profileColor.opacity(0.2))
                )

            Text(self.profileType.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            APGIRadarChart(profile: self.apgiProfile)
                .frame(height: 250)
        }
    }

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            ParameterCardView(
                name: "Prediction Error Sensitivity (ε)",
                value: self.apgiProfile.epsilon,
                interpretation: self.interpretEpsilon(self.apgiProfile.epsilon),
                color: .orange
            )

            ParameterCardView(
                name: "Precision Allocation (π)",
                value: self.apgiProfile.precision,
                interpretation: self.interpretPrecision(self.apgiProfile.precision),
                color: .green
            )

            ParameterCardView(
                name: "Ignition Threshold (θₜ)",
                value: self.apgiProfile.threshold,
                interpretation: self.interpretThreshold(self.apgiProfile.threshold),
                color: .purple
            )

            ParameterCardView(
                name: "Somatic Bias (β)",
                value: self.apgiProfile.somaticBias,
                interpretation: self.interpretSomaticBias(self.apgiProfile.somaticBias),
                color: .blue
            )
        }
    }

    private var detailsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Derived Metrics")
                .font(.headline)

            InfoRow(title: "Interaction Score", value: "\(Int(self.apgiProfile.interactionScore)) / 100")
            InfoRow(title: "Temporal Stability", value: "\(Int(self.apgiProfile.temporalStability)) / 100")
            InfoRow(title: "Environmental Fit", value: "\(Int(self.apgiProfile.environmentalFit)) / 100")
        }
        .padding()
        .background(self.cardBackground)
        .cornerRadius(16)
    }

    private var statesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Psychological States for Your Profile")
                .font(.headline)

            Text("Based on your APGI parameters, here are the states you're most likely to experience:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(self.profileType.likelyStates, id: \.stateId) { match in
                if let state = findState(id: match.stateId) {
                    StateLikelihoodCard(
                        state: state,
                        likelihood: match.likelihood,
                        reason: match.reason
                    )
                }
            }
        }
    }

    private var strategiesTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            StrengthsSection(strengths: self.profileType.strengths)
            ChallengesSection(challenges: self.profileType.challenges)
            StrategiesSection(strategies: self.profileType.strategies)
        }
    }

    private var saveProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save Your Results")
                .font(.headline)

            TextField("Profile Name", text: self.$profileName)
                .textFieldStyle(.roundedBorder)

            LoadingButton(
                title: "Save to Profile",
                isLoading: false,
                style: self.profileName.isEmpty ? SecondaryButtonStyle() : PrimaryButtonStyle(),
                action: self.saveProfile
            )
            .disabled(self.profileName.isEmpty)
        }
        .padding()
        .background(self.cardBackground)
        .cornerRadius(16)
    }

    private var cardBackground: Color {
        #if os(macOS)
            Color(NSColor.controlBackgroundColor)
        #else
            Color(.secondarySystemBackground)
        #endif
    }

    private func interpretEpsilon(_: Double) -> String {
        self.apgiProfile.epsilonCategory.rawValue
    }

    private func interpretPrecision(_: Double) -> String {
        self.apgiProfile.precisionCategory.rawValue
    }

    private func interpretThreshold(_: Double) -> String {
        self.apgiProfile.thresholdCategory.rawValue
    }

    private func interpretSomaticBias(_: Double) -> String {
        self.apgiProfile.somaticCategory.rawValue
    }

    private func findState(id: Int) -> PsychologicalState? {
        self.stateModel.states.first { $0.id == id }
    }

    private func saveProfile() {
        Task {
            do {
                // MED-003 Fix: Check for duplicate profile names
                let trimmedProfileName = self.profileName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedProfileName.isEmpty else {
                    throw AppError.invalidParameters
                }

                // Check for existing profile with same name
                let existingProfiles = try await PersistenceController.shared.fetchProfiles()
                let duplicateExists = existingProfiles.contains { $0.name.lowercased() == trimmedProfileName.lowercased() }

                if duplicateExists {
                    throw AppError.profileGenerationFailed
                }

                _ = try await self.profileManager.createProfile(
                    name: trimmedProfileName,
                    results: self.quizModel.calculateRawScore()
                )
                self.analytics.track(event: .profileCreated(profileType: self.profileType))
                #if os(iOS)
                    StoreKit.requestReview()
                #endif
                await MainActor.run {
                    self.showSavedAlert = true
                    self.profileName = ""
                }
            } catch {
                await MainActor.run {
                    self.toast = .error("Failed to save profile: \(error.localizedDescription)")
                }
            }
        }
    }

    private func createTemporaryProfile() -> QuizProfile {
        QuizProfile(
            id: UUID(),
            name: self.profileName.isEmpty ? "My Profile" : self.profileName,
            dateCreated: Date(),
            dateModified: Date(),
            results: self.quizModel.calculateRawScore()
        )
    }

    private var resultStateId: Int {
        self.profileType.likelyStates.first?.stateId ?? self.stateModel.states.first?.id ?? 0
    }
}

private struct ParameterCardView: View {
    let name: String
    let value: Double
    let interpretation: String
    let color: Color

    private var progress: Double {
        max(0, min(self.value / 100, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(self.name)
                    .font(.headline)
                Spacer()
                Text("\(Int(self.value))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(self.color)
            }

            ProgressView(value: self.progress)
                .tint(self.color)

            Text(self.interpretation)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(self.title)
            Spacer()
            Text(self.value)
                .fontWeight(.semibold)
        }
        .foregroundColor(.primary)
    }
}

private struct StrengthsSection: View {
    let strengths: [String]

    var body: some View {
        InsightSection(title: "Strengths", items: self.strengths, accentColor: .green)
    }
}

private struct ChallengesSection: View {
    let challenges: [String]

    var body: some View {
        InsightSection(title: "Challenges", items: self.challenges, accentColor: .orange)
    }
}

private struct StrategiesSection: View {
    let strategies: [String]

    var body: some View {
        InsightSection(title: "Strategies", items: self.strategies, accentColor: .blue)
    }
}

private struct InsightSection: View {
    let title: String
    let items: [String]
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(self.title)
                .font(.headline)

            ForEach(self.items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(self.accentColor)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    Text(item)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

private struct StateLikelihoodCard: View {
    let state: PsychologicalState
    let likelihood: PsychologicalStateMatch.Likelihood
    let reason: String

    private var badgeColor: Color {
        switch self.likelihood {
        case .veryHigh: .red
        case .high: .orange
        case .moderate: .yellow
        case .low: .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(self.state.name)
                    .font(.headline)
                Spacer()
                Text(self.likelihood.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(6)
                    .background(
                        Capsule()
                            .fill(self.badgeColor.opacity(0.2))
                    )
                    .foregroundColor(self.badgeColor)
            }

            Text(self.reason)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(self.state.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct APGIRadarChart: View {
    let profile: APGIProfile

    private var normalizedValues: [Double] {
        [self.profile.epsilon, self.profile.precision, self.profile.threshold, self.profile.somaticBias]
            .map { max(0, min($0 / 100, 1)) }
    }

    private func makeAxisAngles(count: Int) -> [Double] {
        guard count > 0 else { return [] }
        let step = (2 * .pi) / Double(count)
        return (0 ..< count).map { Double($0) * step - .pi / 2 }
    }

    private func makeRadarPoints(center: CGPoint, radius: Double, angles: [Double], values: [Double]) -> [CGPoint] {
        zip(angles, values).map { angle, value in
            CGPoint(
                x: center.x + cos(angle) * radius * value,
                y: center.y + sin(angle) * radius * value
            )
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
            let axisAngles = self.makeAxisAngles(count: self.normalizedValues.count)
            let radarPoints = self.makeRadarPoints(
                center: center,
                radius: radius,
                angles: axisAngles,
                values: self.normalizedValues
            )
            let radarShape = self.makeRadarPath(from: radarPoints)

            ZStack {
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        .frame(width: radius * 2 * scale, height: radius * 2 * scale)
                        .position(center)
                }

                ForEach(axisAngles.indices, id: \.self) { index in
                    let angle = axisAngles[index]
                    Path { path in
                        path.move(to: center)
                        let endpoint = CGPoint(
                            x: center.x + cos(angle) * radius,
                            y: center.y + sin(angle) * radius
                        )
                        path.addLine(to: endpoint)
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }

                radarShape
                    .fill(Color.blue.opacity(0.3))
                radarShape
                    .stroke(Color.blue, lineWidth: 2)

                Text("ε").position(x: center.x, y: 15)
                Text("π").position(x: geometry.size.width - 15, y: center.y)
                Text("θₜ").position(x: center.x, y: geometry.size.height - 15)
                Text("β").position(x: 15, y: center.y)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func makeRadarPath(from points: [CGPoint]) -> Path {
        var path = Path()
        for (index, point) in points.enumerated() {
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
