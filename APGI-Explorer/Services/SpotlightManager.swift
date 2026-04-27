import CoreSpotlight
import Foundation
import os.log

class SpotlightManager {
  static let shared = SpotlightManager()

  private let searchableIndex = CSSearchableIndex.default()
  private let log = OSLog(subsystem: "com.lesoto.APGI-Explorer", category: "Spotlight")

  private init() {
  }

  func indexProfile(_ profile: QuizProfile, apgiProfile: APGIProfile, profileType: APGIProfileType)
    async {
    let searchableItem = CSSearchableItem(
      uniqueIdentifier: profile.id.uuidString,
      domainIdentifier: "com.lesoto.APGE-Explorer.profiles",
      attributeSet: self.createAttributeSet(
        for: profile, apgiProfile: apgiProfile, profileType: profileType)
    )

    do {
      try await self.searchableIndex.indexSearchableItems([searchableItem])
      os_log("Successfully indexed profile %{public}@", log: self.log, type: .info, profile.name)
    } catch {
      os_log(
        "Failed to index profile %{public}@: %{public}@", log: self.log, type: .error, profile.name,
        error.localizedDescription)
    }
  }

  func removeProfileFromIndex(_ profile: QuizProfile) async {
    do {
      try await self.searchableIndex.deleteSearchableItems(withIdentifiers: [profile.id.uuidString])
      os_log(
        "Successfully removed profile %{public}@ from index", log: self.log, type: .info,
        profile.name)
    } catch {
      os_log(
        "Failed to remove profile %{public}@ from index: %{public}@", log: self.log, type: .error,
        profile.name, error.localizedDescription)
    }
  }

  func reindexAllProfiles(_ profiles: [QuizProfile], profileManager: ProfileManager) async {
    var searchableItems: [CSSearchableItem] = []

    for profile in profiles {
      let apgiProfile = await profileManager.enhancedProfile(from: profile.results)
      let profileType = profileManager.determineProfileType(for: apgiProfile)
      let searchableItem = CSSearchableItem(
        uniqueIdentifier: profile.id.uuidString,
        domainIdentifier: "com.lesoto.APGE-Explorer.profiles",
        attributeSet: self.createAttributeSet(
          for: profile, apgiProfile: apgiProfile, profileType: profileType)
      )
      searchableItems.append(searchableItem)
    }

    do {
      try await self.searchableIndex.indexSearchableItems(searchableItems)
      os_log("Successfully reindexed all profiles", log: self.log, type: .info)
    } catch {
      os_log(
        "Failed to reindex all profiles: %{public}@", log: self.log, type: .error,
        error.localizedDescription)
    }
  }

  private func createAttributeSet(
    for profile: QuizProfile, apgiProfile: APGIProfile, profileType: APGIProfileType
  ) -> CSSearchableItemAttributeSet {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
    attributeSet.title = profile.name
    attributeSet.contentDescription =
      "APGI Profile: \(profileType.rawValue)\nEpsilon: \(Int(apgiProfile.epsilon)), Precision: \(Int(apgiProfile.precision)), Threshold: \(Int(apgiProfile.threshold)), Somatic Bias: \(Int(apgiProfile.somaticBias))"
    attributeSet.keywords = [
      "APGI", "profile", profileType.rawValue, "psychological", "assessment"
    ]
    attributeSet.displayName = profile.name
    attributeSet.creator = "APGI Explorer"
    attributeSet.contentCreationDate = profile.dateCreated
    attributeSet.contentModificationDate = profile.dateModified

    // Additional attributes
    attributeSet.addedDate = profile.dateCreated
    attributeSet.lastUsedDate = profile.dateModified

    return attributeSet
  }

  func handleSpotlightSearchResult(_ identifier: String, profileManager: ProfileManager) async
    -> QuizProfile? {
    guard let profileId = UUID(uuidString: identifier),
      let profile = try? await profileManager.persistence.fetchProfile(id: profileId)
    else {
      return nil
    }
    return profile
  }
}
