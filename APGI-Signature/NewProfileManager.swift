import Foundation
import SwiftUI
import Combine

class NewProfileManager: ObservableObject {
    @Published var profiles: [Profile] = []
    private let dataStore: DataStore
    
    init(dataStore: DataStore = FileSystemDataStore()) {
        self.dataStore = dataStore
        Task { @MainActor in
            loadProfiles()
        }
    }
    
    @MainActor
    func loadProfiles() {
        do {
            profiles = try dataStore.load([Profile].self, forKey: "profiles") ?? []
        } catch {
            print("Failed to load profiles: \(error)")
            profiles = []
        }
    }
    
    @MainActor
    func saveProfiles() {
        do {
            try dataStore.save(profiles, forKey: "profiles")
        } catch {
            print("Failed to save profiles: \(error)")
        }
    }
    
    @MainActor
    func addProfile(_ profile: Profile) {
        profiles.append(profile)
        saveProfiles()
    }
    
    @MainActor
    func deleteProfile(at index: Int) {
        profiles.remove(at: index)
        saveProfiles()
    }
}
