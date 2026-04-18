import Combine
import CoreData
import Foundation

extension ProfileEntity {
  func toQuizProfile() throws -> QuizProfile {
    guard let resultsData,
      let results = try? JSONDecoder().decode([String: Int].self, from: resultsData)
    else {
      throw PersistenceError.invalidData
    }

    return QuizProfile(
      id: id,
      name: name,
      dateCreated: dateCreated,
      dateModified: dateModified,
      results: results
    )
  }

  func update(from profile: QuizProfile) throws {
    self.id = profile.id
    self.name = profile.name
    self.dateCreated = profile.dateCreated
    self.dateModified = profile.dateModified
    self.resultsData = try JSONEncoder().encode(profile.results)

    let apgiProfile = QuizModel.calculateAPGIProfile(from: profile.results)
    self.epsilon = apgiProfile.epsilon
    self.precision = apgiProfile.precision
    self.threshold = apgiProfile.threshold
    self.somaticBias = apgiProfile.somaticBias
  }
}

enum PersistenceError: LocalizedError {
  case invalidData
  case saveFailed(Error)
  case fetchFailed(Error)
  case deleteFailed(Error)

  var errorDescription: String? {
    switch self {
    case .invalidData:
      "The profile data is corrupted or invalid"
    case .saveFailed(let error):
      "Failed to save: \(error.localizedDescription)"
    case .fetchFailed(let error):
      "Failed to load profiles: \(error.localizedDescription)"
    case .deleteFailed(let error):
      "Failed to delete profile: \(error.localizedDescription)"
    }
  }
}
