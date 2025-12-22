import Foundation
import Combine

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

    /// Determines the APGI profile type based on the results.
    func determineProfileType(for results: [String: Int]) -> String {
        let epsilon = results["epsilon"] ?? 0
        let precision = results["precision"] ?? 0
        let threshold = results["threshold"] ?? 0
        let somatic = results["somatic"] ?? 0

        // Example logic: You can expand this with your full APGI profile matching logic
        if epsilon >= 16 && somatic >= 13 && threshold <= 8 {
            return "SENSITIVE_INTEGRATOR"
        } else if epsilon <= 9 && precision >= 13 && threshold >= 13 {
            return "ANALYTICAL_GUARD"
        } else if (10...15).contains(epsilon) && (8...12).contains(precision) && (8...12).contains(threshold) && (8...12).contains(somatic) {
            return "ADAPTIVE_BALANCER"
        } else if epsilon >= 16 && precision <= 8 && threshold <= 8 {
            return "OPEN_EXPLORER"
        } else if epsilon <= 9 && precision >= 13 && threshold >= 13 && somatic >= 13 {
            return "CONTEMPLATIVE_ANCHOR"
        } else {
            return "ADAPTIVE_BALANCER" // Default
        }
    }

    /// Returns a formatted summary of the profile's results.
    func summary(for profile: QuizProfile) -> String {
        let profileType = determineProfileType(for: profile.results)
        let epsilon = profile.results["epsilon"] ?? 0
        let precision = profile.results["precision"] ?? 0
        let threshold = profile.results["threshold"] ?? 0
        let somatic = profile.results["somatic"] ?? 0

        return """
        **Profile Type:** \(profileType)
        **Prediction Error (ε):** \(epsilon)
        **Precision (π):** \(precision)
        **Threshold (θₜ):** \(threshold)
        **Somatic Bias (β):** \(somatic)
        **Last Modified:** \(profile.dateModified.formatted())
        """
    }
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
