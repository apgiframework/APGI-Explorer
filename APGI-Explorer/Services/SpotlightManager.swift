import CoreSpotlight
import Foundation
import os.log

/// Scores and profiles must not be indexed. Purge older app-owned indexes on every launch.
class SpotlightManager {
  static let shared = SpotlightManager()
  private init() {}

  func purgeLegacyIndex() async {
    do {
      try await CSSearchableIndex.default().deleteAllSearchableItems()
    } catch {
      os_log("Could not remove legacy Spotlight entries: %@", error.localizedDescription)
    }
  }
  func indexProfile(_ profile: QuizProfile, apgiProfile: APGIProfile, profileType: APGIProfileType) async {
    await removeProfileFromIndex(profile)
  }
  func removeProfileFromIndex(_ profile: QuizProfile) async {
    do {
      try await CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [profile.id.uuidString])
    } catch { os_log("Could not remove Spotlight entry: %@", error.localizedDescription) }
  }
  func reindexAllProfiles(_ profiles: [QuizProfile], profileManager: ProfileManager) async {
    await purgeLegacyIndex()
  }
  func handleSpotlightSearchResult(_ identifier: String, profileManager: ProfileManager) async -> QuizProfile? {
    nil
  }
}
