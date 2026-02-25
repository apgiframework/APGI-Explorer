import Combine
import Foundation
import os.log
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

    private let persistence = PersistenceController.shared
    private let userDefaults = UserDefaultsManager.shared
    private let fileStorage = FileStorageManager.shared
    private let scorer = APGIScorer()

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
            self.profiles = try await self.persistence.fetchProfiles(sortBy: self.sortOption, ascending: self.sortAscending)
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
            os_log("Failed to restore last profile: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
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
                os_log("Invalid parameter value for %{public}@: %{public}@. Expected 0-100 range.", log: OSLog.default, type: .error, key, String(value))
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
    func determineProfileType(for results: [String: Int]) -> APGIProfileType {
        let normalizedProfile = self.enhancedProfile(from: results)
        return self.determineProfileType(for: normalizedProfile)
    }

    /// Determines the APGI profile type based on the derived APGIProfile.
    func determineProfileType(for profile: APGIProfile) -> APGIProfileType {
        let patterns: [(APGIProfileType, (APGIProfile) -> Double)] = [
            (.sensitiveIntegrator, { profile in
                let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 80, tolerance: 25)
                let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 80, tolerance: 25)
                let thresholdMatch = self.closeness(value: profile.threshold, ideal: 20, tolerance: 20)
                let precisionMatch = self.closeness(value: profile.precision, ideal: 55, tolerance: 30)
                return (epsilonMatch + somaticMatch + thresholdMatch + precisionMatch) / 4
            }),

            (.analyticalGuard, { profile in
                let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 20, tolerance: 20)
                let precisionMatch = self.closeness(value: profile.precision, ideal: 85, tolerance: 20)
                let thresholdMatch = self.closeness(value: profile.threshold, ideal: 80, tolerance: 20)
                return (epsilonMatch + precisionMatch + thresholdMatch) / 3
            }),

            (.adaptiveBalancer, { profile in
                let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 50, tolerance: 25)
                let precisionMatch = self.closeness(value: profile.precision, ideal: 50, tolerance: 25)
                let thresholdMatch = self.closeness(value: profile.threshold, ideal: 50, tolerance: 25)
                let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 50, tolerance: 25)
                return (epsilonMatch + precisionMatch + thresholdMatch + somaticMatch) / 4
            }),

            (.openExplorer, { profile in
                let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 85, tolerance: 20)
                let precisionMatch = self.closeness(value: profile.precision, ideal: 30, tolerance: 20)
                let thresholdMatch = self.closeness(value: profile.threshold, ideal: 30, tolerance: 20)
                return (epsilonMatch + precisionMatch + thresholdMatch) / 3
            }),

            (.contemplativeAnchor, { profile in
                let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 25, tolerance: 25)
                let precisionMatch = self.closeness(value: profile.precision, ideal: 70, tolerance: 25)
                let thresholdMatch = self.closeness(value: profile.threshold, ideal: 80, tolerance: 20)
                let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 55, tolerance: 30)
                return (epsilonMatch + precisionMatch + thresholdMatch + somaticMatch) / 4
            }),

            (.somaticNavigator, { profile in
                let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 45, tolerance: 25)
                let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 85, tolerance: 20)
                let thresholdMatch = self.closeness(value: profile.threshold, ideal: 55, tolerance: 25)
                let precisionMatch = self.closeness(value: profile.precision, ideal: 55, tolerance: 25)
                return (epsilonMatch + somaticMatch + thresholdMatch + precisionMatch) / 4
            }),

            (.cognitiveArchitect, { profile in
                let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 55, tolerance: 25)
                let precisionMatch = self.closeness(value: profile.precision, ideal: 90, tolerance: 15)
                let thresholdMatch = self.closeness(value: profile.threshold, ideal: 75, tolerance: 20)
                let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 40, tolerance: 20)
                return (epsilonMatch + precisionMatch + thresholdMatch + somaticMatch) / 4
            }),

            (.dynamicResponder, { profile in
                let epsilonMatch = self.closeness(value: profile.epsilon, ideal: 85, tolerance: 20)
                let somaticMatch = self.closeness(value: profile.somaticBias, ideal: 70, tolerance: 25)
                let interactionMatch = self.closeness(value: profile.interactionScore, ideal: 80, tolerance: 25)
                let thresholdMatch = self.closeness(value: profile.threshold, ideal: 60, tolerance: 20)
                return (epsilonMatch + somaticMatch + interactionMatch + thresholdMatch) / 4
            }),
        ]

        let matches = patterns.map { ($0.0, $0.1(profile)) }
        guard let bestMatch = matches.max(by: { $0.1 < $1.1 }) else {
            return .adaptiveBalancer
        }

        return bestMatch.1 > 0.6 ? bestMatch.0 : .adaptiveBalancer
    }

    /// Returns a formatted summary of the profile's results.
    func summary(for profile: QuizProfile) -> String {
        let profileType = self.determineProfileType(for: profile.results)
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
    private func enhancedProfile(from results: [String: Int]) -> APGIProfile {
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
            "interactions": 5, "temporal": 6, "environment": 7,
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

    func profile(from results: [String: Int]) throws -> APGIProfile {
        guard let epsilon = results["epsilon"], epsilon >= 0, epsilon <= 100 else {
            throw ProfileError.invalidData
        }

        guard let precision = results["precision"], precision >= 0, precision <= 100 else {
            throw ProfileError.invalidData
        }

        guard let threshold = results["threshold"], threshold >= 0, threshold <= 100 else {
            throw ProfileError.invalidData
        }

        guard let somatic = results["somatic"], somatic >= 0, somatic <= 100 else {
            throw ProfileError.invalidData
        }

        return APGIProfile(
            epsilon: Double(epsilon),
            precision: Double(precision),
            threshold: Double(threshold),
            somaticBias: Double(somatic),
            interactionScore: 0,
            temporalStability: 0,
            environmentalFit: 0
        )
    }

    private func closeness(value: Double, ideal: Double, tolerance: Double) -> Double {
        guard tolerance > 0 else {
            return value == ideal ? 1 : 0
        }

        let distance = abs(value - ideal)
        return max(0, 1 - distance / tolerance)
    }

    // MARK: - Export Functionality

    /// Generates a PDF report for the given profile
    func generatePDFReport(for profile: QuizProfile) -> URL? {
        let apgiProfile = self.enhancedProfile(from: profile.results)
        let profileType = self.determineProfileType(for: apgiProfile)

        // Page size with margins
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 36.0
        let availableWidth = pageWidth - (2 * margin)

        // Create PDF document
        let pdfDocument = PDFDocument()
        let pdfPage = PDFPage()
        pdfPage.setBounds(pageRect, for: .mediaBox)
        pdfDocument.insert(pdfPage, at: 0)

        // Create PDF context for drawing
        guard let context = NSGraphicsContext.current?.cgContext else { return nil }

        // Generate filename
        let filename = ExportUtilities.generateExportFilename(profile: profile, format: .pdf)
        let tempDir = ExportUtilities.getTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent(filename)

        // Begin drawing
        context.beginPDFPage(nil)

        // Title
        let title = "APGI Profile Report"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.labelColor,
        ]
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: margin, y: pageHeight - margin - titleSize.height,
                               width: availableWidth,
                               height: titleSize.height)
        title.draw(in: titleRect, withAttributes: titleAttributes)

        // Profile name and date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let subtitle = "\(profile.name) • \(formatter.string(from: profile.dateCreated))"
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        let subtitleRect = CGRect(x: margin,
                                  y: titleRect.minY - subtitleSize.height - 4,
                                  width: availableWidth,
                                  height: subtitleSize.height)
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)

        // Profile type
        let typeTitle = "Profile Type: \(profileType.rawValue)"
        let typeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 18),
            .foregroundColor: NSColor.labelColor,
        ]
        let typeSize = typeTitle.size(withAttributes: typeAttributes)
        let typeRect = CGRect(x: margin,
                              y: subtitleRect.minY - typeSize.height - 24,
                              width: availableWidth,
                              height: typeSize.height)
        typeTitle.draw(in: typeRect, withAttributes: typeAttributes)

        // Profile description
        let descriptionText = profileType.description
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4

        let descriptionAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle,
        ]

        let descriptionHeight: CGFloat = 100 // Approximate height
        let descriptionRect = CGRect(x: margin,
                                     y: typeRect.minY - descriptionHeight - 8,
                                     width: availableWidth,
                                     height: descriptionHeight)

        descriptionText.draw(with: descriptionRect,
                             options: [.usesLineFragmentOrigin, .usesFontLeading],
                             attributes: descriptionAttributes,
                             context: nil)

        // Parameter scores
        let scoresY = descriptionRect.minY - 20
        let scoreAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor,
        ]

        let scoreWidth = availableWidth / 2

        // Left column
        for (index, param) in ["ε (Epsilon)", "π (Precision)"].enumerated() {
            let score = param == "ε (Epsilon)" ? apgiProfile.epsilon : apgiProfile.precision
            let scoreText = "\(param): \(Int(score))"
            let scoreRect = CGRect(x: margin,
                                   y: scoresY - CGFloat(index * 20),
                                   width: scoreWidth,
                                   height: 20)
            scoreText.draw(in: scoreRect, withAttributes: scoreAttributes)
        }

        // Right column
        for (index, param) in ["θₜ (Threshold)", "β (Somatic Bias)"].enumerated() {
            let score = param == "θₜ (Threshold)" ? apgiProfile.threshold : apgiProfile.somaticBias
            let scoreText = "\(param): \(Int(score))"
            let scoreRect = CGRect(x: margin + scoreWidth,
                                   y: scoresY - CGFloat(index * 20),
                                   width: scoreWidth,
                                   height: 20)
            scoreText.draw(in: scoreRect, withAttributes: scoreAttributes)
        }

        // End drawing
        context.endPDFPage()

        // Save the PDF document
        if let data = pdfDocument.dataRepresentation() {
            do {
                try data.write(to: fileURL)
                return fileURL
            } catch {
                os_log("Failed to save PDF: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
                return nil
            }
        } else {
            os_log("Failed to create PDF document", log: OSLog.default, type: .error)
            return nil
        }
    }

    /// Exports the profile to JSON format
    func exportToJSON(profile: QuizProfile) -> Data? {
        let apgiScores = self.enhancedProfile(from: profile.results)
        let export = ProfileExport(
            version: "1.0",
            timestamp: Date(),
            profile: profile,
            apgiScores: apgiScores
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(export)
        } catch {
            os_log("Failed to encode profile: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
            return nil
        }
    }

    /// Exports the profile to CSV format
    func exportToCSV(profile: QuizProfile) -> Data? {
        let apgiScores = self.enhancedProfile(from: profile.results)
        let profileType = self.determineProfileType(for: apgiScores)

        // CSV header
        var csvContent = [
            "Profile Name",
            "Date Created",
            "Profile Type",
            "Epsilon (ε)",
            "Precision (π)",
            "Threshold (θₜ)",
            "Somatic Bias (β)",
            "Interaction Score",
            "Temporal Stability",
            "Environmental Fit",
            "Epsilon Category",
            "Precision Category",
            "Threshold Category",
            "Somatic Bias Category",
            "Interaction Category",
            "Temporal Category",
            "Environmental Category",
        ].joined(separator: ",")

        // CSV data row
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let dataRow = [
            "\"\(profile.name)\"",
            "\"\(formatter.string(from: profile.dateCreated))\"",
            "\"\(profileType.rawValue)\"",
            String(format: "%.2f", apgiScores.epsilon),
            String(format: "%.2f", apgiScores.precision),
            String(format: "%.2f", apgiScores.threshold),
            String(format: "%.2f", apgiScores.somaticBias),
            String(format: "%.2f", apgiScores.interactionScore),
            String(format: "%.2f", apgiScores.temporalStability),
            String(format: "%.2f", apgiScores.environmentalFit),
            "\"\(apgiScores.epsilonCategory.rawValue)\"",
            "\"\(apgiScores.precisionCategory.rawValue)\"",
            "\"\(apgiScores.thresholdCategory.rawValue)\"",
            "\"\(apgiScores.somaticCategory.rawValue)\"",
            "\"\(apgiScores.interactionCategory.rawValue)\"",
            "\"\(apgiScores.temporalCategory.rawValue)\"",
            "\"\(apgiScores.environmentalCategory.rawValue)\"",
        ].joined(separator: ",")

        csvContent += "\n" + dataRow

        return csvContent.data(using: .utf8)
    }

    /// Returns a URL for the exported profile that can be shared
    @MainActor
    func getExportURL(for profile: QuizProfile, format: ExportFormat) -> URL? {
        switch format {
        case .pdf:
            return self.generatePDFReport(for: profile)
        case .json:
            if let data = exportToJSON(profile: profile) {
                let filename = ExportUtilities.generateExportFilename(profile: profile, format: format)
                let tempDir = ExportUtilities.getTemporaryDirectory()
                let tempFile = tempDir.appendingPathComponent(filename)

                do {
                    try data.write(to: tempFile)
                    return tempFile
                } catch {
                    os_log("Failed to write JSON export file: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
                    return nil
                }
            }
            return nil
        case .csv:
            if let data = exportToCSV(profile: profile) {
                let filename = ExportUtilities.generateExportFilename(profile: profile, format: format)
                let tempDir = ExportUtilities.getTemporaryDirectory()
                let tempFile = tempDir.appendingPathComponent(filename)

                do {
                    try data.write(to: tempFile)
                    return tempFile
                } catch {
                    os_log("Failed to write CSV export file: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
                    return nil
                }
            }
            return nil
        case .png:
            if let apgiScores = try? self.profile(from: profile.results) {
                return exportProfileAsPNG(profile: profile, apgiScores: apgiScores)
            }
            return nil
        case .spss, .stata, .rData, .excel, .xml, .bibTeX, .endNote, .apa, .mla:
            // For these formats, fall back to CSV export for now
            if let data = exportToCSV(profile: profile) {
                let filename = ExportUtilities.generateExportFilename(profile: profile, format: format)
                let tempDir = ExportUtilities.getTemporaryDirectory()
                let tempFile = tempDir.appendingPathComponent(filename)

                do {
                    try data.write(to: tempFile)
                    return tempFile
                } catch {
                    os_log("Failed to write export file for %{public}@ format: %{public}@", log: OSLog.default, type: .error, format.rawValue, error.localizedDescription)
                    return nil
                }
            }
            return nil
        }
    }

    private func timelineSnapshots(excluding profile: QuizProfile) -> [ReportSnapshot] {
        self.profiles
            .filter { $0.id != profile.id }
            .map { savedProfile in
                let savedApgi = self.enhancedProfile(from: savedProfile.results)
                let savedType = self.determineProfileType(for: savedApgi)
                return ReportSnapshot(
                    name: savedProfile.name,
                    date: savedProfile.dateCreated,
                    profileType: savedType,
                    apgiProfile: savedApgi
                )
            }
    }
}

// MARK: - Profile Analysis Extensions

extension ProfileManager {
    /// Returns states ranked by accessibility for this profile
    func rankedStatesForProfile(_ profile: APGIProfile) -> [StateAccessibility] {
        let states = StateModel().states

        return states.map { state in
            let accessibility = self.calculateAccessibility(state: state, profile: profile)
            return StateAccessibility(state: state, score: accessibility.score, explanation: accessibility.explanation)
        }
        .sorted { $0.score > $1.score }
    }

    private func calculateAccessibility(state: PsychologicalState, profile: APGIProfile) -> (score: Double, explanation: String) {
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

        let explanation = factors.isEmpty ? "Moderate match to your profile" : factors.joined(separator: "; ")

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
        let numericString = string
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
               let pngData = bitmapImage.representation(using: .png, properties: [:])
            {
                do {
                    try pngData.write(to: tempFile)
                    return tempFile
                } catch {
                    os_log("Failed to write PNG file: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
                }
            }
        }

        return nil
    }

    private func createNSImage(from view: some View) -> NSImage? {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
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

            ProgressView(value: self.value, total: 5.0)
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
