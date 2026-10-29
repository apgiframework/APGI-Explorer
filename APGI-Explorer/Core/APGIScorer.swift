import Foundation

/// Descriptive scoring key for the exploratory local instrument, not a scientific model.
/// Equal-weight item means on a 0–100 display scale; no reliability or norm claims.
nonisolated final class APGIScorer {
  enum ScoringError: Error, Equatable {
    case researchRequiresServer
    case unknownItems
    case invalidResponse
    case incomplete
  }

  static let requiredItemIDs = Set(1...35)
  static let nominalItemIDs: Set<Int> = [7, 9]

  func calculateRobustScore(answers: [Int: Int], researchMode: Bool = false)
    -> Result<APGIProfile, ScoringError> {
    guard !researchMode else { return .failure(.researchRequiresServer) }
    guard Set(answers.keys).isSubset(of: Self.requiredItemIDs) else {
      return .failure(.unknownItems)
    }
    guard answers.values.allSatisfy({ (1...4).contains($0) }) else {
      return .failure(.invalidResponse)
    }
    guard Set(answers.keys) == Self.requiredItemIDs else { return .failure(.incomplete) }
    return .success(Self.descriptiveProfile(answers: answers))
  }

  /// Partial means are for local progress only, never a completed or research result.
  static func descriptiveProfile(answers: [Int: Int]) -> APGIProfile {
    func mean(_ ids: ClosedRange<Int>) -> Double {
      let values = ids.filter { !nominalItemIDs.contains($0) }.compactMap { answers[$0] }
        .filter { (1...4).contains($0) }
      guard !values.isEmpty else { return 0 }
      return values.reduce(0.0) { $0 + (Double($1) - 0.5) * 25 } / Double(values.count)
    }
    return APGIProfile(
      epsilon: mean(1...5), precision: mean(6...10), threshold: mean(11...15),
      somaticBias: mean(16...20), interactionScore: mean(21...25),
      temporalStability: mean(26...30), environmentalFit: mean(31...35))
  }
}
