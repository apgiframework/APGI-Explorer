import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

struct ResultsView: View {
    @StateObject private var profileManager = ProfileManager()
    @ObservedObject var quizModel: QuizModel
    @State private var profileName = ""
    @State private var showSavedAlert = false
    @State private var selectedTab = 0
    @StateObject private var stateModel = StateModel()
    @Environment(\.appDependencies) private var dependencies

    private var analytics: AnalyticsService {
        dependencies.getAnalyticsService()
    }

    private var apgiProfile: APGIProfile {
        quizModel.calculateScore().profile
    }

    private var profileType: APGIProfileType {
        profileManager.determineProfileType(for: apgiProfile)
    }

    private var profileColor: Color {
        switch profileType {
        case .sensitiveIntegrator: return .orange
        case .analyticalGuard: return .blue
        case .adaptiveBalancer: return .green
        case .openExplorer: return .pink
        case .contemplativeAnchor: return .teal
        case .somaticNavigator: return .purple
        case .cognitiveArchitect: return .mint
        case .dynamicResponder: return .red
        }
    }

    @State private var showingExportSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeaderView

                Picker("View", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Details").tag(1)
                    Text("States").tag(2)
                    Text("Strategies").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Group {
                    switch selectedTab {
                    case 0: overviewTab
                    case 1: detailsTab
                    case 2: statesTab
                    case 3: strategiesTab
                    default: overviewTab
                    }
                }

                saveProfileSection
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
                Button(action: { showingExportSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                }
            }
            #else
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingExportSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                }
            }
            #endif
        }
        .sheet(isPresented: $showingExportSheet) {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    ExportView(profileManager: profileManager, profile: createTemporaryProfile())
                }
            } else {
                NavigationView {
                    ExportView(profileManager: profileManager, profile: createTemporaryProfile())
                }
            }
        }
        .alert("Profile Saved!", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your results have been saved to '\(profileName)'.")
        }
        .onAppear {
            analytics.track(event: .quizCompleted(profileType: profileType, score: quizModel.calculatePartialScore().epsilon, duration: 0))
            analytics.setUserProperty(profileType.rawValue, forKey: "recentProfileType")
        }
    }

    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            Text(profileType.rawValue)
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(profileColor.opacity(0.2))
                )

            Text(profileType.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            APGIRadarChart(profile: apgiProfile)
                .frame(height: 250)
        }
    }

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            ParameterCardView(
                name: "Prediction Error Sensitivity (ε)",
                value: apgiProfile.epsilon,
                interpretation: interpretEpsilon(apgiProfile.epsilon),
                color: .orange
            )

            ParameterCardView(
                name: "Precision Allocation (π)",
                value: apgiProfile.precision,
                interpretation: interpretPrecision(apgiProfile.precision),
                color: .green
            )

            ParameterCardView(
                name: "Ignition Threshold (θₜ)",
                value: apgiProfile.threshold,
                interpretation: interpretThreshold(apgiProfile.threshold),
                color: .purple
            )

            ParameterCardView(
                name: "Somatic Bias (β)",
                value: apgiProfile.somaticBias,
                interpretation: interpretSomaticBias(apgiProfile.somaticBias),
                color: .blue
            )
        }
    }

    private var detailsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Derived Metrics")
                .font(.headline)

            InfoRow(title: "Interaction Score", value: "\(Int(apgiProfile.interactionScore)) / 100")
            InfoRow(title: "Temporal Stability", value: "\(Int(apgiProfile.temporalStability)) / 100")
            InfoRow(title: "Environmental Fit", value: "\(Int(apgiProfile.environmentalFit)) / 100")
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
    }

    private var statesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Psychological States for Your Profile")
                .font(.headline)

            Text("Based on your APGI parameters, here are the states you're most likely to experience:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(profileType.likelyStates, id: \.stateId) { match in
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
            StrengthsSection(strengths: profileType.strengths)
            ChallengesSection(challenges: profileType.challenges)
            StrategiesSection(strategies: profileType.strategies)
        }
    }

    private var saveProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save Your Results")
                .font(.headline)

            TextField("Profile Name", text: $profileName)
                .textFieldStyle(.roundedBorder)

            Button(action: saveProfile) {
                Text("Save to Profile")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(profileName.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(profileName.isEmpty)
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
    }

    private var cardBackground: Color {
        #if os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    private func interpretEpsilon(_ value: Double) -> String {
        apgiProfile.epsilonCategory.rawValue
    }

    private func interpretPrecision(_ value: Double) -> String {
        apgiProfile.precisionCategory.rawValue
    }

    private func interpretThreshold(_ value: Double) -> String {
        apgiProfile.thresholdCategory.rawValue
    }

    private func interpretSomaticBias(_ value: Double) -> String {
        apgiProfile.somaticCategory.rawValue
    }

    private func findState(id: Int) -> PsychologicalState? {
        stateModel.states.first { $0.id == id }
    }

    private func saveProfile() {
        Task {
            do {
                _ = try await profileManager.createProfile(
                    name: profileName,
                    results: quizModel.calculateRawScore()
                )
                analytics.track(event: .profileCreated(profileType: profileType))
                await MainActor.run {
                    showSavedAlert = true
                    profileName = ""
                }
            } catch {
                await MainActor.run {
                    // Handle error appropriately
                    print("Failed to save profile: \(error)")
                }
            }
        }
    }
    
    private func createTemporaryProfile() -> QuizProfile {
        QuizProfile(
            id: UUID(),
            name: profileName.isEmpty ? "My Profile" : profileName,
            dateCreated: Date(),
            dateModified: Date(),
            results: quizModel.calculateRawScore()
        )
    }

    private var resultStateId: Int {
        profileType.likelyStates.first?.stateId ?? stateModel.states.first?.id ?? 0
    }
}

private struct ParameterCardView: View {
    let name: String
    let value: Double
    let interpretation: String
    let color: Color

    private var progress: Double {
        max(0, min(value / 100, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.headline)
                Spacer()
                Text("\(Int(value))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            ProgressView(value: progress)
                .tint(color)

            Text(interpretation)
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
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .foregroundColor(.primary)
    }
}

private struct StrengthsSection: View {
    let strengths: [String]

    var body: some View {
        InsightSection(title: "Strengths", items: strengths, accentColor: .green)
    }
}

private struct ChallengesSection: View {
    let challenges: [String]

    var body: some View {
        InsightSection(title: "Challenges", items: challenges, accentColor: .orange)
    }
}

private struct StrategiesSection: View {
    let strategies: [String]

    var body: some View {
        InsightSection(title: "Strategies", items: strategies, accentColor: .blue)
    }
}

private struct InsightSection: View {
    let title: String
    let items: [String]
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(accentColor)
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
        switch likelihood {
        case .veryHigh: return .red
        case .high: return .orange
        case .moderate: return .yellow
        case .low: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(state.name)
                    .font(.headline)
                Spacer()
                Text(likelihood.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(6)
                    .background(
                        Capsule()
                            .fill(badgeColor.opacity(0.2))
                    )
                    .foregroundColor(badgeColor)
            }

            Text(reason)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(state.description)
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
        [profile.epsilon, profile.precision, profile.threshold, profile.somaticBias]
            .map { max(0, min($0 / 100, 1)) }
    }

    private func makeAxisAngles(count: Int) -> [Double] {
        guard count > 0 else { return [] }
        let step = (2 * .pi) / Double(count)
        return (0..<count).map { Double($0) * step - .pi / 2 }
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
            let axisAngles = makeAxisAngles(count: normalizedValues.count)
            let radarPoints = makeRadarPoints(
                center: center,
                radius: radius,
                angles: axisAngles,
                values: normalizedValues
            )
            let radarShape = makeRadarPath(from: radarPoints)

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

private extension Color {
    static var adaptiveBackground: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
}
