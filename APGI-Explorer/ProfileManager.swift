import Combine
import Foundation
import os.log
import os.signpost
import PDFKit
import SwiftUI

@MainActor
class ProfileManager: ObservableObject {
    @Published var profiles: [QuizProfile] = []
    @Published var currentProfile: QuizProfile?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var sortOption: ProfileSortOption = .dateModified
    @Published var sortAscending = false

    // Settings integration
    @AppStorage("lazyLoading") private var lazyLoading: Bool = true
    @AppStorage("showAverageProfile") private var showAverageProfile: Bool = false
    @AppStorage("showDifferencesOnly") private var showDifferencesOnly: Bool = false
    @AppStorage("normalizeValues") private var normalizeValues: Bool = true

    let persistence = PersistenceController.shared
    private let userDefaults = UserDefaultsManager.shared
    private let fileStorage = FileStorageManager.shared
    private let scorer = APGIScorer()
    private let log = OSLog(subsystem: "com.lesoto.APGI-Explorer", category: "ProfileManager")

    private var cancellables = Set<AnyCancellable>()

    enum ProfileError: Error {
        case invalidData
    }

    init() {
        Task {
            await self.loadProfiles()
            await self.restoreLastActiveProfile()
        }
    }

    // MARK: - Loading

    func loadProfiles() async {
        self.isLoading = true
        self.error = nil

        do {
            self.profiles = try await self.persistence.fetchProfiles(
                sortBy: self.sortOption, ascending: self.sortAscending
            )
        } catch {
            self.error = error
        }

        self.isLoading = false
    }

    func restoreLastActiveProfile() async {
        guard let lastID = userDefaults.lastActiveProfileID else { return }

        do {
            self.currentProfile = try await self.persistence.fetchProfile(id: lastID)
        } catch {
            os_log(
                "Failed to restore last profile: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
        }
    }

    // MARK: - CRUD Operations

    func createProfile(name: String, results: [String: Int]) async throws -> QuizProfile {
        // CRIT-001 Fix: Validate input parameters
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.invalidParameters
        }

        guard !results.isEmpty else {
            throw AppError.invalidParameters
        }

        // Validate results values are within expected range
        for (key, value) in results {
            guard value >= 0, value <= 100 else {
                os_log(
                    "Invalid parameter value for %{public}@: %{public}@. Expected 0-100 range.",
                    log: self.log, type: .error, key, String(value)
                )
                throw AppError.invalidParameters
            }
        }

        let profile = QuizProfile(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            dateCreated: Date(),
            dateModified: Date(),
            results: results
        )

        do {
            try await self.persistence.saveProfile(profile)
            await self.loadProfiles()

            self.currentProfile = profile
            self.userDefaults.lastActiveProfileID = profile.id
            self.userDefaults.totalQuizzesCompleted += 1
            self.userDefaults.lastQuizDate = Date()

            Task {
                let apgiProfile = await self.enhancedProfile(from: profile.results)
                let profileType = self.determineProfileType(for: apgiProfile)
                await SpotlightManager.shared.indexProfile(
                    profile, apgiProfile: apgiProfile, profileType: profileType
                )
            }

            return profile
        } catch {
            // CRIT-001 Fix: Provide better error handling
            throw AppError.profileGenerationFailed
        }
    }

    func updateProfile(_ profile: QuizProfile) async throws {
        var updatedProfile = profile
        updatedProfile.dateModified = Date()

        try await self.persistence.saveProfile(updatedProfile)
        await self.loadProfiles()

        if self.currentProfile?.id == profile.id {
            self.currentProfile = updatedProfile
        }
    }

    func deleteProfile(_ profile: QuizProfile) async throws {
        try await self.persistence.deleteProfile(profile)
        await self.loadProfiles()

        if self.currentProfile?.id == profile.id {
            self.currentProfile = self.profiles.first
            self.userDefaults.lastActiveProfileID = self.currentProfile?.id
        }
    }

    func duplicateProfile(_ profile: QuizProfile) async throws -> QuizProfile {
        let newProfile = QuizProfile(
            id: UUID(),
            name: "\(profile.name) (Copy)",
            dateCreated: Date(),
            dateModified: Date(),
            results: profile.results
        )

        try await self.persistence.saveProfile(newProfile)
        await self.loadProfiles()

        return newProfile
    }

    // MARK: - Search and Filter

    func searchProfiles(query: String) async throws -> [QuizProfile] {
        if query.isEmpty {
            return self.profiles
        }
        return try await self.persistence.searchProfiles(query: query)
    }

    func filterProfiles(by predicate: (QuizProfile) -> Bool) -> [QuizProfile] {
        self.profiles.filter(predicate)
    }

    // MARK: - Export/Import

    func exportProfile(_ profile: QuizProfile) throws -> URL {
        try self.fileStorage.exportProfile(profile)
    }

    func importProfile(from url: URL) async throws {
        let profile = try fileStorage.importProfile(from: url)
        try await self.persistence.saveProfile(profile)
        await self.loadProfiles()
    }

    func exportAllProfiles() async throws -> URL {
        try await self.fileStorage.createBackup()
    }

    func exportAllUserData() async throws -> URL {
        let userData = UserDataExport(
            profiles: profiles,
            exportDate: Date(),
            appVersion: getAppVersion(),
            deviceInfo: collectDeviceInfo()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(userData)

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "APGI_UserData_\(Date().timeIntervalSince1970).json"
        let fileURL = documentsPath.appendingPathComponent(fileName)

        try data.write(to: fileURL)
        return fileURL
    }

    func deleteAllUserData() async throws {
        // Delete all profiles
        for profile in self.profiles {
            try await self.deleteProfile(profile)
        }

        // Clear user defaults
        UserDefaults.standard.removeObject(forKey: "lastActiveProfileID")
        UserDefaults.standard.removeObject(forKey: "totalQuizzesCompleted")
        UserDefaults.standard.removeObject(forKey: "lastQuizDate")

        // Clear other user data
        self.currentProfile = nil
        self.profiles.removeAll()
    }

    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private func collectDeviceInfo() -> [String: String] {
        var deviceInfo: [String: String] = [:]

        #if os(iOS)
            deviceInfo["platform"] = "iOS"
            deviceInfo["deviceModel"] = UIDevice.current.model
            deviceInfo["systemVersion"] = UIDevice.current.systemVersion
        #elseif os(macOS)
            deviceInfo["platform"] = "macOS"
            deviceInfo["systemVersion"] = ProcessInfo.processInfo.operatingSystemVersionString
        #endif

        return deviceInfo
    }

    func importFromBackup(url: URL) async throws {
        try await self.fileStorage.restoreBackup(from: url)
        await self.loadProfiles()
    }

    // MARK: - Auto-save

    func enableAutoSave(for profile: QuizProfile, results: [String: Int]) {
        Task {
            var updatedProfile = profile
            updatedProfile.results = results
            updatedProfile.dateModified = Date()

            if self.userDefaults.autoSaveEnabled {
                try? await self.persistence.saveProfile(updatedProfile)
            }
        }
    }

    // MARK: - Sort

    func changeSortOption(_ option: ProfileSortOption, ascending: Bool = false) async {
        self.sortOption = option
        self.sortAscending = ascending
        await self.loadProfiles()
    }

    // MARK: - Profile Analysis

    /// Determines the APGI profile type based on the stored integer results.
    func determineProfileType(for results: [String: Int]) async -> APGIProfileType {
        let normalizedProfile = await self.enhancedProfile(from: results)
        return self.determineProfileType(for: normalizedProfile)
    }

    /// Calculates how close a value is to an ideal value within a tolerance range
    private func closeness(value: Double, ideal: Double, tolerance: Double) -> Double {
        let difference = abs(value - ideal)
        if difference <= tolerance {
            return 1.0 - (difference / tolerance)
        } else {
            return max(0.0, 1.0 - (difference - tolerance) / (100.0 - tolerance))
        }
    }

    /// Determines the APGI profile type based on the derived APGIProfile.
    func determineProfileType(for profile: APGIProfile) -> APGIProfileType {
        let patterns: [(APGIProfileType, (APGIProfile) -> Double)] = [
            (
                .sensitiveIntegrator,
                { profile in
                    let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 80, tolerance: 25)
                    let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 80, tolerance: 25)
                    let thresholdMatch = self.closeness(value: profile.threshold, ideal: 20, tolerance: 20)
                    let precisionMatch = self.closeness(value: profile.precision, ideal: 55, tolerance: 30)
                    return (epsilonMatch + somaticMatch + thresholdMatch + precisionMatch) / 4
                }
            ),

            (
                .analyticalGuard,
                { profile in
                    let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 20, tolerance: 20)
                    let precisionMatch = self.closeness(value: profile.precision, ideal: 85, tolerance: 20)
                    let thresholdMatch = self.closeness(value: profile.threshold, ideal: 80, tolerance: 20)
                    return (epsilonMatch + precisionMatch + thresholdMatch) / 3
                }
            ),

            (
                .adaptiveBalancer,
                { profile in
                    let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 50, tolerance: 25)
                    let precisionMatch = self.closeness(value: profile.precision, ideal: 50, tolerance: 25)
                    let thresholdMatch = self.closeness(value: profile.threshold, ideal: 50, tolerance: 25)
                    let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 50, tolerance: 25)
                    return (epsilonMatch + precisionMatch + thresholdMatch + somaticMatch) / 4
                }
            ),

            (
                .openExplorer,
                { profile in
                    let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 85, tolerance: 20)
                    let precisionMatch = self.closeness(value: profile.precision, ideal: 30, tolerance: 20)
                    let thresholdMatch = self.closeness(value: profile.threshold, ideal: 30, tolerance: 20)
                    return (epsilonMatch + precisionMatch + thresholdMatch) / 3
                }
            ),

            (
                .contemplativeAnchor,
                { profile in
                    let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 25, tolerance: 25)
                    let precisionMatch = self.closeness(value: profile.precision, ideal: 70, tolerance: 25)
                    let thresholdMatch = self.closeness(value: profile.threshold, ideal: 80, tolerance: 20)
                    let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 55, tolerance: 30)
                    return (epsilonMatch + precisionMatch + thresholdMatch + somaticMatch) / 4
                }
            ),

            (
                .somaticNavigator,
                { profile in
                    let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 45, tolerance: 25)
                    let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 85, tolerance: 20)
                    let thresholdMatch = self.closeness(value: profile.threshold, ideal: 55, tolerance: 25)
                    let precisionMatch = self.closeness(value: profile.precision, ideal: 55, tolerance: 25)
                    return (epsilonMatch + somaticMatch + thresholdMatch + precisionMatch) / 4
                }
            ),

            (
                .cognitiveArchitect,
                { profile in
                    let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 55, tolerance: 25)
                    let precisionMatch = self.closeness(value: profile.precision, ideal: 90, tolerance: 15)
                    let thresholdMatch = self.closeness(value: profile.threshold, ideal: 75, tolerance: 20)
                    let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 40, tolerance: 20)
                    return (epsilonMatch + precisionMatch + thresholdMatch + somaticMatch) / 4
                }
            ),

            (
                .dynamicResponder,
                { profile in
                    let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 85, tolerance: 20)
                    let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 70, tolerance: 25)
                    let interactionMatch = self.closeness(
                        value: profile.interactionScore, ideal: 80, tolerance: 25
                    )
                    let thresholdMatch = self.closeness(value: profile.threshold, ideal: 60, tolerance: 20)
                    return (epsilonMatch + somaticMatch + interactionMatch + thresholdMatch) / 4
                }
            )
        ]

        let matches = patterns.map { ($0.0, $0.1(profile)) }
        guard let bestMatch = matches.max(by: { $0.1 < $1.1 }) else {
            return .adaptiveBalancer
        }

        return bestMatch.1 > 0.6 ? bestMatch.0 : .adaptiveBalancer
    }

    /// Returns a formatted summary of the profile's results.
    func summary(for profile: QuizProfile) async -> String {
        let profileType = await self.determineProfileType(for: profile.results)
        let epsilon = profile.results["epsilon"] ?? 0
        let precision = profile.results["precision"] ?? 0
        let threshold = profile.results["threshold"] ?? 0
        let somatic = profile.results["somatic"] ?? 0

        return """
        **Profile Type:** \(profileType.rawValue)
        **Prediction Error (ε):** \(epsilon)
        **Precision (π):** \(precision)
        **Threshold (θₜ):** \(threshold)
        **Somatic Bias (β):** \(somatic)
        **Last Modified:** \(profile.dateModified.formatted())
        """
    }

    /// Enhanced profile calculation using APGIScorer
    func enhancedProfile(from results: [String: Int]) async -> APGIProfile {
        // Validate input results
        guard !results.isEmpty else {
            os_log("Empty results dictionary provided to enhancedProfile", type: .error)
            return APGIProfile(
                epsilon: 50.0,
                precision: 50.0,
                threshold: 50.0,
                somaticBias: 50.0,
                interactionScore: 0,
                temporalStability: 0,
                environmentalFit: 0
            )
        }

        // Convert [String: Int] results to [Int: Int] for the scorer
        let answerMapping: [String: Int] = [
            "epsilon": 1, "precision": 2, "threshold": 3, "somatic": 4,
            "interactions": 5, "temporal": 6, "environment": 7
        ]

        var answers: [Int: Int] = [:]
        for (parameter, value) in results {
            guard answerMapping[parameter] != nil,
                  value >= 0, value <= 100
            else {
                os_log("Invalid parameter '%s' or value '%d' in results", type: .error, parameter, value)
                continue
            }

            // Map the parameter value to question IDs
            let questionIds = self.getQuestionIdsForParameter(parameter)
            for questionId in questionIds {
                // Distribute the parameter value across related questions
                // This is a simplified approach - in practice, you'd want actual individual answers
                answers[questionId] = value
            }
        }

        // Ensure we have enough data for scoring
        guard !answers.isEmpty else {
            os_log("No valid answers could be mapped from results", type: .error)
            return APGIProfile(
                epsilon: 50.0,
                precision: 50.0,
                threshold: 50.0,
                somaticBias: 50.0,
                interactionScore: 0,
                temporalStability: 0,
                environmentalFit: 0
            )
        }

        return self.scorer.calculateRobustScore(answers: answers)
    }

    private func getQuestionIdsForParameter(_ parameter: String) -> [Int] {
        switch parameter {
        case "epsilon":
            [1, 2, 3, 4, 5]
        case "precision":
            [6, 7, 8, 9, 10]
        case "threshold":
            [11, 12, 13, 14, 15]
        case "somatic":
            [16, 17, 18, 19, 20]
        case "interactions":
            [21, 22, 23, 24, 25]
        case "temporal":
            [26, 27, 28, 29, 30]
        case "environment":
            [31, 32, 33, 34, 35]
        default:
            []
        }
    }

    /// Generates a PDF report for the profile
    private func generatePDFReport(for profile: QuizProfile) async -> URL? {
        let filename = ExportUtilities.generateExportFilename(profile: profile, format: .pdf)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent(filename)

        let apgiProfile = await self.enhancedProfile(from: profile.results)
        let profileType = self.determineProfileType(for: apgiProfile)

        let pdfContent = """
        APGI Profile Report
        =================

        Profile Name: \(profile.name)
        Created: \(profile.dateCreated.formatted())
        Modified: \(profile.dateModified.formatted())
        Profile Type: \(profileType.rawValue)

        APGI Scores:
        - Epsilon (Prediction Error): \(String(format: "%.2f", apgiProfile.epsilon))
        - Precision: \(String(format: "%.2f", apgiProfile.precision))
        - Threshold: \(String(format: "%.2f", apgiProfile.threshold))
        - Somatic Bias: \(String(format: "%.2f", apgiProfile.somaticBias))
        - Interaction Score: \(String(format: "%.2f", apgiProfile.interactionScore))
        - Temporal Stability: \(String(format: "%.2f", apgiProfile.temporalStability))
        - Environmental Fit: \(String(format: "%.2f", apgiProfile.environmentalFit))

        Generated by APGI Explorer
        """

        do {
            try pdfContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            os_log(
                "Failed to write PDF report: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
            return nil
        }
    }

    /// Exports profile to JSON format
    private func exportToJSON(profile: QuizProfile) async -> Data? {
        let apgiProfile = await self.enhancedProfile(from: profile.results)
        let profileType = self.determineProfileType(for: apgiProfile)

        let exportData: [String: Any] = [
            "profile": [
                "id": profile.id.uuidString,
                "name": profile.name,
                "dateCreated": ISO8601DateFormatter().string(from: profile.dateCreated),
                "dateModified": ISO8601DateFormatter().string(from: profile.dateModified),
                "results": profile.results
            ],
            "apgiScores": [
                "epsilon": apgiProfile.epsilon,
                "precision": apgiProfile.precision,
                "threshold": apgiProfile.threshold,
                "somaticBias": apgiProfile.somaticBias,
                "interactionScore": apgiProfile.interactionScore,
                "temporalStability": apgiProfile.temporalStability,
                "environmentalFit": apgiProfile.environmentalFit
            ],
            "profileType": profileType.rawValue
        ]

        do {
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            os_log(
                "Failed to serialize profile to JSON: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
            return nil
        }
    }

    /// Exports profile to CSV format
    private func exportToCSV(profile: QuizProfile) async -> Data? {
        let apgiProfile = await self.enhancedProfile(from: profile.results)
        let profileType = self.determineProfileType(for: apgiProfile)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let header = "Name,Created,Profile Type,Epsilon,Precision,Threshold,Somatic Bias,Interaction Score,Temporal Stability,Environmental Fit"
        let dataRow = [
            "\"\(profile.name)\"",
            "\"\(formatter.string(from: profile.dateCreated))\"",
            "\"\(profileType.rawValue)\"",
            String(format: "%.2f", apgiProfile.epsilon),
            String(format: "%.2f", apgiProfile.precision),
            String(format: "%.2f", apgiProfile.threshold),
            String(format: "%.2f", apgiProfile.somaticBias),
            String(format: "%.2f", apgiProfile.interactionScore),
            String(format: "%.2f", apgiProfile.temporalStability),
            String(format: "%.2f", apgiProfile.environmentalFit)
        ].joined(separator: ",")

        let csvContent = header + "\n" + dataRow
        return csvContent.data(using: .utf8)
    }

    /// Returns a URL for the exported profile that can be shared
    @MainActor
    func getExportURL(for profile: QuizProfile, format: ExportFormat) async -> URL? {
        switch format {
        case .pdf:
            return await self.generatePDFReport(for: profile)
        case .json:
            return await self.writeExportData(await self.exportToJSON(profile: profile), for: profile, format: format)
        case .csv:
            return await self.writeExportData(await self.exportToCSV(profile: profile), for: profile, format: format)
        case .png:
            let apgiScores = await self.enhancedProfile(from: profile.results)
            return exportProfileAsPNG(profile: profile, apgiScores: apgiScores)
        case .spss:
            return await exportToSPSS(profile: profile)
        case .stata:
            return await exportToStata(profile: profile)
        case .rData:
            return await exportToRData(profile: profile)
        case .excel:
            return await exportToExcel(profile: profile)
        case .xml:
            return await exportToXML(profile: profile)
        case .bibTeX:
            return await exportToBibTeX(profile: profile)
        case .endNote:
            return await exportToEndNote(profile: profile)
        case .apa:
            return await exportToAPAReport(profile: profile)
        case .mla:
            return await exportToMLAReport(profile: profile)
        }
    }

    private func writeExportData(_ data: Data?, for profile: QuizProfile, format: ExportFormat) async -> URL? {
        guard let data else { return nil }

        let filename = ExportUtilities.generateExportFilename(profile: profile, format: format)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let tempFile = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: tempFile)
            return tempFile
        } catch {
            os_log(
                "Failed to write export file: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
            return nil
        }
    }

    private func timelineSnapshots(excluding profile: QuizProfile) async -> [ReportSnapshot] {
        var snapshots: [ReportSnapshot] = []

        for savedProfile in self.profiles.filter({ $0.id != profile.id }) {
            let savedApgi = await self.enhancedProfile(from: savedProfile.results)
            let savedType = self.determineProfileType(for: savedApgi)
            snapshots.append(
                ReportSnapshot(
                    name: savedProfile.name,
                    date: savedProfile.dateCreated,
                    profileType: savedType,
                    apgiProfile: savedApgi
                )
            )
        }

        return snapshots
    }
}

// MARK: - Profile Analysis Extensions

extension ProfileManager {
    /// Returns states ranked by accessibility for this profile
    func rankedStatesForProfile(_ profile: APGIProfile) -> [StateAccessibility] {
        let states = StateModel().states

        return states.map { state in
            let accessibility = self.calculateAccessibility(state: state, profile: profile)
            return StateAccessibility(
                state: state, score: accessibility.score, explanation: accessibility.explanation
            )
        }
        .sorted { $0.score > $1.score }
    }

    private func calculateAccessibility(state: PsychologicalState, profile: APGIProfile) -> (
        score: Double, explanation: String
    ) {
        // Parse state parameters
        let stateParams = self.parseStateParameters(state)

        var score = 0.0
        var factors: [String] = []

        // Epsilon matching (Prediction Error)
        if let stateEpsilon = stateParams.epsilon {
            let epsilonMatch = 1.0 - abs(profile.epsilon - stateEpsilon) / 100.0
            score += epsilonMatch * 0.3
            if epsilonMatch > 0.7 {
                factors.append("Your ε aligns with this state's prediction error profile")
            }
        }

        // Threshold matching
        if let stateThreshold = stateParams.threshold {
            let thresholdMatch = 1.0 - abs(profile.threshold - stateThreshold) / 100.0
            score += thresholdMatch * 0.3
            if thresholdMatch > 0.7 {
                factors.append("Your θₜ makes this state highly accessible")
            }
        }

        // Somatic bias matching
        if let stateSomatic = stateParams.somaticBias {
            let somaticMatch = 1.0 - abs(profile.somaticBias - stateSomatic) / 100.0
            score += somaticMatch * 0.25
            if somaticMatch > 0.7 {
                factors.append("Your β level predisposes you to this state")
            }
        }

        // Precision matching
        if let statePrecision = stateParams.precision {
            let precisionMatch = 1.0 - abs(profile.precision - statePrecision) / 100.0
            score += precisionMatch * 0.15
        }

        let explanation =
            factors.isEmpty ? "Moderate match to your profile" : factors.joined(separator: "; ")

        return (score, explanation)
    }

    private func parseStateParameters(_ state: PsychologicalState) -> StateParameters {
        StateParameters(
            epsilon: self.extractNumericValue(from: state.predictionError),
            precision: self.extractNumericValue(from: state.precision),
            threshold: self.extractNumericValue(from: state.threshold),
            somaticBias: self.extractNumericValue(from: state.somaticBias)
        )
    }

    /// Extracts a numeric value from a state's parameter string (e.g., "1.5-2.0" -> 1.75)
    private func extractNumericValue(from string: String) -> Double? {
        // Remove any non-numeric characters except decimal points and minus signs
        let numericString =
            string
                .replacingOccurrences(of: "[^0-9.-]", with: " ", options: .regularExpression)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .first ?? "0"

        // Handle ranges (e.g., "1.5-2.0" -> average of 1.5 and 2.0)
        if numericString.contains("-") {
            let values = numericString.components(separatedBy: "-")
                .prefix(2)
                .compactMap { Double($0) }
            if values.count == 2 {
                return (values[0] + values[1]) / 2.0
            }
        }

        return Double(numericString)
    }

    private func exportProfileAsPNG(profile: QuizProfile, apgiScores: APGIProfile) -> URL? {
        let filename = ExportUtilities.generateExportFilename(profile: profile, format: .png)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let tempFile = tempDir.appendingPathComponent(filename)

        // Create a SwiftUI view for the chart
        let chartView = ProfileChartView(profile: profile, apgiScores: apgiScores)

        // Convert SwiftUI view to NSImage
        if let nsImage = createNSImage(from: chartView) {
            // Convert NSImage to PNG data
            if let tiffData = nsImage.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                do {
                    try pngData.write(to: tempFile)
                    return tempFile
                } catch {
                    os_log(
                        "Failed to write PNG file: %{public}@", log: self.log, type: .error,
                        error.localizedDescription
                    )
                }
            }
        }

        return nil
    }

    private func createNSImage(from view: some View) -> NSImage? {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)

        // Fix layout recursion: use needsLayout = true + layoutSubtreeIfNeeded
        hostingView.needsLayout = true
        hostingView.layoutSubtreeIfNeeded()

        guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

        let nsImage = NSImage(size: hostingView.bounds.size)
        nsImage.addRepresentation(rep)

        return nsImage
    }
}

// MARK: - Profile Chart View for PNG Export

struct ProfileChartView: View {
    let profile: QuizProfile
    let apgiScores: APGIProfile

    var body: some View {
        VStack(spacing: 20) {
            Text(self.profile.name)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)

            Text("APGI Profile")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                ParameterRow(name: "Epsilon (ε)", value: self.apgiScores.epsilon, color: .blue)
                ParameterRow(name: "Precision (π)", value: self.apgiScores.precision, color: .green)
                ParameterRow(name: "Threshold (θₜ)", value: self.apgiScores.threshold, color: .orange)
                ParameterRow(name: "Somatic Bias (β)", value: self.apgiScores.somaticBias, color: .red)
            }
            .padding(.horizontal)

            Spacer()

            Text("Created: \(self.profile.dateCreated, formatter: DateFormatter.shortDate)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom)
        }
        .frame(width: 800, height: 600)
        .background(Color.white)
    }
}

struct ParameterRow: View {
    let name: String
    let value: Double
    let color: Color

    var body: some View {
        HStack {
            Text(self.name)
                .font(.body)
                .frame(width: 150, alignment: .leading)

            ProgressView(value: self.value, total: 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: self.color))
                .frame(width: 400)

            Text(String(format: "%.2f", self.value))
                .font(.body)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

struct StateParameters {
    let epsilon: Double?
    let precision: Double?
    let threshold: Double?
    let somaticBias: Double?
}

struct StateAccessibility: Identifiable {
    let id = UUID()
    let state: PsychologicalState
    let score: Double
    let explanation: String
}

// MARK: - QuizProfile Model

struct QuizProfile: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    let dateCreated: Date
    var dateModified: Date
    var results: [String: Int]

    var parameterSummary: String {
        """
        ε: \(self.results["epsilon"] ?? 0)
        π: \(self.results["precision"] ?? 0)
        θₜ: \(self.results["threshold"] ?? 0)
        β: \(self.results["somatic"] ?? 0)
        """
    }

    /// Computed properties for analytics compatibility
    var epsilon: Double {
        Double(self.results["epsilon"] ?? 0)
    }

    var precision: Double {
        Double(self.results["precision"] ?? 0)
    }

    var threshold: Double {
        Double(self.results["threshold"] ?? 0)
    }

    var somaticBias: Double {
        Double(self.results["somatic"] ?? 0)
    }

    /// Demographic properties for export compatibility
    var age: Int {
        self.results["age"] ?? 0
    }

    var gender: String {
        // Since results are Int, perhaps demographics are not stored
        // Return empty string for now
        ""
    }

    var education: String {
        ""
    }

    var occupation: String {
        ""
    }
}

// MARK: - Additional Export Formats

extension ProfileManager {
    /// Exports profile to SPSS .sav format
    private func exportToSPSS(profile: QuizProfile) async -> URL? {
        let filename = ExportUtilities.generateExportFilename(profile: profile, format: .spss)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent(filename)

        // Create a basic SPSS-compatible file structure
        // Note: This is a simplified implementation - real SPSS files require complex binary formatting
        let csvData = await self.exportToCSV(profile: profile)
        do {
            try csvData?.write(to: fileURL)
            return fileURL
        } catch {
            os_log(
                "Failed to write SPSS export file: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
            return nil
        }
    }

    /// Exports profile to Stata .dta format
    private func exportToStata(profile: QuizProfile) async -> URL? {
        let filename = ExportUtilities.generateExportFilename(profile: profile, format: .stata)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent(filename)

        // Create a basic Stata-compatible file structure
        // Note: This is a simplified implementation - real Stata files require complex binary formatting
        let csvData = await self.exportToCSV(profile: profile)
        do {
            try csvData?.write(to: fileURL)
            return fileURL
        } catch {
            os_log(
                "Failed to write Stata export file: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
            return nil
        }
    }

    /// Exports profile to R Data format
    private func exportToRData(profile: QuizProfile) async -> URL? {
        let filename = ExportUtilities.generateExportFilename(profile: profile, format: .rData)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent(filename)

        // Compute APGI profile on background thread
        let signpostID = OSSignpostID(log: self.log)
        os_signpost(.begin, log: self.log, name: "Score Calculation", signpostID: signpostID)
        let apgiProfile = await self.enhancedProfile(from: profile.results)
        os_signpost(.end, log: self.log, name: "Score Calculation", signpostID: signpostID)

        let rScript = """
        # APGI Profile Data
        # Generated on \(Date())

        # Profile metadata
        profile_name <- "\(profile.name)"
        profile_date <- as.POSIXct("\(profile.dateCreated)")

        # APGI scores
        epsilon <- \(apgiProfile.epsilon)
        precision <- \(apgiProfile.precision)
        threshold <- \(apgiProfile.threshold)
        somatic_bias <- \(apgiProfile.somaticBias)

        # Create data frame
        apgi_data <- data.frame(
            parameter = c("epsilon", "precision", "threshold", "somatic_bias"),
            value = c(epsilon, precision, threshold, somatic_bias)
        )

        # Save workspace
        save(profile_name, profile_date, apgi_data, file = "\(filename)")
        """

        do {
            try rScript.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            os_log(
                "Failed to write R Data export file: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
            return nil
        }
    }

    /// Exports profile to Excel format
    private func exportToExcel(profile: QuizProfile) async -> URL? {
        let filename = ExportUtilities.generateExportFilename(profile: profile, format: .excel)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent(filename)

        // Create CSV content (Excel can open CSV files directly)
        // Note: For true .xlsx format, a library like ExcelKit would be needed
        let csvData = await self.exportToCSV(profile: profile)
        do {
            try csvData?.write(to: fileURL)
            return fileURL
        } catch {
            os_log(
                "Failed to write Excel export file: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
            return nil
        }
    }

    /// Exports profile to XML format
    private func exportToXML(profile: QuizProfile) async -> URL? {
        let filename = ExportUtilities.generateExportFilename(profile: profile, format: .xml)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent(filename)

        // Compute APGI profile on background thread
        let apgiProfile = await self.enhancedProfile(from: profile.results)
        let profileType = self.determineProfileType(for: apgiProfile)

        let xmlContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <apgi_profile>
            <metadata>
                <name>\(profile.name.replacingOccurrences(of: "&", with: "&amp;"))</name>
                <date_created>\(ISO8601DateFormatter().string(from: profile.dateCreated))</date_created>
                <profile_type>\(profileType.rawValue)</profile_type>
            </metadata>
            <scores>
                <epsilon>\(apgiProfile.epsilon)</epsilon>
                <precision>\(apgiProfile.precision)</precision>
                <threshold>\(apgiProfile.threshold)</threshold>
                <somatic_bias>\(apgiProfile.somaticBias)</somatic_bias>
            </scores>
            <responses>
        """

        let xmlEnd = """
            </responses>
        </apgi_profile>
        """

        let fullXML =
            xmlContent
                + profile.results.map { response in
                    "        <response id=\"\(response.key)\" value=\"\(response.value)\"/>"
                }.joined(separator: "\n") + xmlEnd

        do {
            try fullXML.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            return fileURL
        } catch {
            os_log(
                "Failed to write XML export file: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
            return nil
        }
    }

    /// Exports profile to BibTeX format
    private func exportToBibTeX(profile: QuizProfile) async -> URL? {
        let filename = ExportUtilities.generateExportFilename(profile: profile, format: .bibTeX)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent(filename)

        // Compute APGI profile on background thread
        let apgiProfile = await self.enhancedProfile(from: profile.results)
        let profileType = self.determineProfileType(for: apgiProfile)

        // Create a unique citation key
        let citationKey =
            "\(profile.name.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970)"

        let bibtexContent = """
        @misc{\(citationKey),
            author = {APGI Explorer},
            title = {Psychological Profile: \(profile.name)},
            year = {\(Calendar.current.component(.year, from: profile.dateCreated))},
            month = {\(Calendar.current.monthSymbols[Calendar.current.component(.month, from: profile.dateCreated) - 1])},
            note = {Profile Type: \(profileType.rawValue), Epsilon: \(apgiProfile.epsilon), Precision: \(apgiProfile.precision), Threshold: \(apgiProfile.threshold), Somatic Bias: \(apgiProfile.somaticBias)},
            howpublished = {APGI Explorer Application}
        }
        """

        do {
            try bibtexContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            os_log(
                "Failed to write BibTeX export file: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
            return nil
        }
    }

    /// Exports profile to EndNote format
    private func exportToEndNote(profile: QuizProfile) async -> URL? {
        let filename = ExportUtilities.generateExportFilename(profile: profile, format: .endNote)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent(filename)

        // Compute APGI profile on background thread
        let apgiProfile = await self.enhancedProfile(from: profile.results)
        let profileType = self.determineProfileType(for: apgiProfile)

        let endNoteContent = """
        %0 Generic
        %T Psychological Profile: \(profile.name)
        %A APGI Explorer
        %D \(Calendar.current.component(.year, from: profile.dateCreated))
        %\(Calendar.current.component(.month, from: profile.dateCreated)) \(Calendar.current.monthSymbols[Calendar.current.component(.month, from: profile.dateCreated) - 1])
        %X Profile Type: \(profileType.rawValue). APGI scores: Epsilon=\(apgiProfile.epsilon), Precision=\(apgiProfile.precision), Threshold=\(apgiProfile.threshold), Somatic Bias=\(apgiProfile.somaticBias).
        %9 APGI Explorer Application
        %@
        """

        do {
            try endNoteContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            os_log(
                "Failed to write EndNote export file: %{public}@", log: self.log, type: .error,
                error.localizedDescription
            )
            return nil
        }
    }

    /// Exports profile to APA-formatted report (PDF)
    private func exportToAPAReport(profile: QuizProfile) async -> URL? {
        // For now, reuse the PDF generation but format it according to APA style
        await self.generatePDFReport(for: profile)
    }

    /// Exports profile to MLA-formatted report (PDF)
    private func exportToMLAReport(profile: QuizProfile) async -> URL? {
        // For now, reuse the PDF generation but format it according to MLA style
        await self.generatePDFReport(for: profile)
    }
}
