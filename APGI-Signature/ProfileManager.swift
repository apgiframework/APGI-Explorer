import Foundation
import Combine
import PDFKit
import SwiftUI
import AppKit

class ProfileManager: ObservableObject {
    @Published var profiles: [QuizProfile] = []
    private let profilesKey = "savedQuizProfiles"

    init() {
        loadProfiles()
    }

    // MARK: - Profile CRUD

    /// Creates and saves a new profile with the given name and quiz results.
    func createProfile(name: String, results: [String: Int]) {
        let newProfile = QuizProfile(
            id: UUID(),
            name: name,
            dateCreated: Date(),
            dateModified: Date(),
            results: results
        )
        profiles.append(newProfile)
        saveProfiles()
    }

    /// Updates an existing profile with new results.
    func updateProfile(_ profile: QuizProfile, newName: String? = nil, newResults: [String: Int]? = nil) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            var updatedProfile = profile
            if let newName = newName {
                updatedProfile.name = newName
            }
            if let newResults = newResults {
                updatedProfile.results = newResults
            }
            updatedProfile.dateModified = Date()
            profiles[index] = updatedProfile
            saveProfiles()
        }
    }

    /// Deletes a profile.
    func deleteProfile(_ profile: QuizProfile) {
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()
    }

    // MARK: - Persistence

    private func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profilesKey)
        }
    }

    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([QuizProfile].self, from: data) {
            profiles = decoded
        }
    }

    // MARK: - Profile Analysis

    /// Determines the APGI profile type based on the stored integer results.
    func determineProfileType(for results: [String: Int]) -> APGIProfileType {
        let normalizedProfile = profile(from: results)
        return determineProfileType(for: normalizedProfile)
    }

    /// Determines the APGI profile type based on the derived APGIProfile.
    func determineProfileType(for profile: APGIProfile) -> APGIProfileType {
        let patterns: [(APGIProfileType, (APGIProfile) -> Double)] = [
            (.sensitiveIntegrator, { p in
                let epsilonMatch = self.closeness(value: p.epsilon, ideal: 80, tolerance: 25)
                let somaticMatch = self.closeness(value: p.somaticBias, ideal: 80, tolerance: 25)
                let thresholdMatch = self.closeness(value: p.threshold, ideal: 20, tolerance: 20)
                let precisionMatch = self.closeness(value: p.precision, ideal: 55, tolerance: 30)
                return (epsilonMatch + somaticMatch + thresholdMatch + precisionMatch) / 4
            }),

            (.analyticalGuard, { p in
                let epsilonMatch = self.closeness(value: p.epsilon, ideal: 20, tolerance: 20)
                let precisionMatch = self.closeness(value: p.precision, ideal: 85, tolerance: 20)
                let thresholdMatch = self.closeness(value: p.threshold, ideal: 80, tolerance: 20)
                return (epsilonMatch + precisionMatch + thresholdMatch) / 3
            }),

            (.adaptiveBalancer, { p in
                let epsilonMatch = self.closeness(value: p.epsilon, ideal: 50, tolerance: 25)
                let precisionMatch = self.closeness(value: p.precision, ideal: 50, tolerance: 25)
                let thresholdMatch = self.closeness(value: p.threshold, ideal: 50, tolerance: 25)
                let somaticMatch = self.closeness(value: p.somaticBias, ideal: 50, tolerance: 25)
                return (epsilonMatch + precisionMatch + thresholdMatch + somaticMatch) / 4
            }),

            (.openExplorer, { p in
                let epsilonMatch = self.closeness(value: p.epsilon, ideal: 85, tolerance: 20)
                let precisionMatch = self.closeness(value: p.precision, ideal: 30, tolerance: 20)
                let thresholdMatch = self.closeness(value: p.threshold, ideal: 30, tolerance: 20)
                return (epsilonMatch + precisionMatch + thresholdMatch) / 3
            }),

            (.contemplativeAnchor, { p in
                let epsilonMatch = self.closeness(value: p.epsilon, ideal: 25, tolerance: 25)
                let precisionMatch = self.closeness(value: p.precision, ideal: 70, tolerance: 25)
                let thresholdMatch = self.closeness(value: p.threshold, ideal: 80, tolerance: 20)
                let somaticMatch = self.closeness(value: p.somaticBias, ideal: 55, tolerance: 30)
                return (epsilonMatch + precisionMatch + thresholdMatch + somaticMatch) / 4
            }),

            (.somaticNavigator, { p in
                let epsilonMatch = self.closeness(value: p.epsilon, ideal: 45, tolerance: 25)
                let somaticMatch = self.closeness(value: p.somaticBias, ideal: 85, tolerance: 20)
                let thresholdMatch = self.closeness(value: p.threshold, ideal: 55, tolerance: 25)
                let precisionMatch = self.closeness(value: p.precision, ideal: 55, tolerance: 25)
                return (epsilonMatch + somaticMatch + thresholdMatch + precisionMatch) / 4
            }),

            (.cognitiveArchitect, { p in
                let epsilonMatch = self.closeness(value: p.epsilon, ideal: 55, tolerance: 25)
                let precisionMatch = self.closeness(value: p.precision, ideal: 90, tolerance: 15)
                let thresholdMatch = self.closeness(value: p.threshold, ideal: 75, tolerance: 20)
                let somaticMatch = self.closeness(value: p.somaticBias, ideal: 40, tolerance: 20)
                return (epsilonMatch + precisionMatch + thresholdMatch + somaticMatch) / 4
            }),

            (.dynamicResponder, { p in
                let epsilonMatch = self.closeness(value: p.epsilon, ideal: 85, tolerance: 20)
                let somaticMatch = self.closeness(value: p.somaticBias, ideal: 70, tolerance: 25)
                let interactionMatch = self.closeness(value: p.interactionScore, ideal: 80, tolerance: 25)
                let thresholdMatch = self.closeness(value: p.threshold, ideal: 60, tolerance: 20)
                return (epsilonMatch + somaticMatch + interactionMatch + thresholdMatch) / 4
            })
        ]

        let matches = patterns.map { ($0.0, $0.1(profile)) }
        guard let bestMatch = matches.max(by: { $0.1 < $1.1 }) else {
            return .adaptiveBalancer
        }

        return bestMatch.1 > 0.6 ? bestMatch.0 : .adaptiveBalancer
    }

    /// Returns a formatted summary of the profile's results.
    func summary(for profile: QuizProfile) -> String {
        let profileType = determineProfileType(for: profile.results)
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

    internal func profile(from results: [String: Int]) -> APGIProfile {
        APGIProfile(
            epsilon: Double(results["epsilon"] ?? 0),
            precision: Double(results["precision"] ?? 0),
            threshold: Double(results["threshold"] ?? 0),
            somaticBias: Double(results["somatic"] ?? 0),
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
        let apgiProfile = self.profile(from: profile.results)
        let profileType = determineProfileType(for: apgiProfile)
        
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
            .foregroundColor: NSColor.labelColor
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
            .foregroundColor: NSColor.secondaryLabelColor
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
            .foregroundColor: NSColor.labelColor
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
            .paragraphStyle: paragraphStyle
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
            .foregroundColor: NSColor.labelColor
        ]
        
        let scoreWidth = availableWidth / 2
        
        // Left column
        for (i, param) in ["ε (Epsilon)", "π (Precision)"].enumerated() {
            let score = param == "ε (Epsilon)" ? apgiProfile.epsilon : apgiProfile.precision
            let scoreText = "\(param): \(Int(score))"
            let scoreRect = CGRect(x: margin, 
                                 y: scoresY - CGFloat(i * 20), 
                                 width: scoreWidth, 
                                 height: 20)
            scoreText.draw(in: scoreRect, withAttributes: scoreAttributes)
        }
        
        // Right column
        for (i, param) in ["θₜ (Threshold)", "β (Somatic Bias)"].enumerated() {
            let score = param == "θₜ (Threshold)" ? apgiProfile.threshold : apgiProfile.somaticBias
            let scoreText = "\(param): \(Int(score))"
            let scoreRect = CGRect(x: margin + scoreWidth, 
                                 y: scoresY - CGFloat(i * 20), 
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
                print("Failed to save PDF: \(error)")
                return nil
            }
        } else {
            print("Failed to create PDF document")
            return nil
        }
    }
    
    /// Exports the profile to JSON format
    func exportToJSON(profile: QuizProfile) -> Data? {
        let apgiScores = self.profile(from: profile.results)
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
            print("Failed to encode profile: \(error)")
            return nil
        }
    }
    
    /// Returns a URL for the exported profile that can be shared
    @MainActor
    func getExportURL(for profile: QuizProfile, format: ExportFormat) -> URL? {
        switch format {
        case .pdf:
            return generatePDFReport(for: profile)
        case .json, .text:
            if let data = exportToJSON(profile: profile) {
                let filename = ExportUtilities.generateExportFilename(profile: profile, format: format)
                let tempDir = ExportUtilities.getTemporaryDirectory()
                let tempFile = tempDir.appendingPathComponent(filename)
                
                do {
                    try data.write(to: tempFile)
                    return tempFile
                } catch {
                    print("Failed to write export file: \(error)")
                    return nil
                }
            }
            return nil
        }
    }
}

// MARK: - Profile Analysis Extensions

extension ProfileManager {
    /// Returns states ranked by accessibility for this profile
    func rankedStatesForProfile(_ profile: APGIProfile) -> [StateAccessibility] {
        let states = StateModel().states
        
        return states.map { state in
            let accessibility = calculateAccessibility(state: state, profile: profile)
            return StateAccessibility(state: state, score: accessibility.score, explanation: accessibility.explanation)
        }
        .sorted { $0.score > $1.score }
    }
    
    private func calculateAccessibility(state: PsychologicalState, profile: APGIProfile) -> (score: Double, explanation: String) {
        // Parse state parameters
        let stateParams = parseStateParameters(state)
        
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
        return StateParameters(
            epsilon: extractNumericValue(from: state.predictionError),
            precision: extractNumericValue(from: state.precision),
            threshold: extractNumericValue(from: state.threshold),
            somaticBias: extractNumericValue(from: state.somaticBias)
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

struct QuizProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    let dateCreated: Date
    var dateModified: Date
    var results: [String: Int]

    var parameterSummary: String {
        """
        ε: \(results["epsilon"] ?? 0)
        π: \(results["precision"] ?? 0)
        θₜ: \(results["threshold"] ?? 0)
        β: \(results["somatic"] ?? 0)
        """
    }
}
