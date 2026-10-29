import XCTest
@testable import ExplorerCore

/// Portable scorer tests (S1-EXP-02.x, XC-CI-08.6/.7): the same invariants the native
/// `ExplorerContractTests` check, now also run on Linux in CI.
final class ScorerTests: XCTestCase {
  private var complete: [Int: Int] { Dictionary(uniqueKeysWithValues: (1...35).map { ($0, 2) }) }
  private let scorer = APGIScorer()

  private func values(_ p: APGIProfile) -> [Double] {
    [p.epsilon, p.precision, p.threshold, p.somaticBias, p.interactionScore, p.temporalStability, p.environmentalFit]
  }

  func testIncompleteInputNeverProducesAProfile() {
    XCTAssertEqual(scorer.calculateRobustScore(answers: [:]), .failure(.incomplete))
    // 16 arbitrary answers must fail (completion is by item set, not by count).
    let sixteen = Dictionary(uniqueKeysWithValues: (1...16).map { ($0, 2) })
    XCTAssertEqual(scorer.calculateRobustScore(answers: sixteen), .failure(.incomplete))
    let scattered = Dictionary(uniqueKeysWithValues: stride(from: 1, through: 35, by: 2).map { ($0, 3) })
    XCTAssertEqual(scorer.calculateRobustScore(answers: scattered), .failure(.incomplete))
  }

  func testUnknownItemIDsAreRejectedEvenWhenTheCountMatches() {
    var answers = complete
    answers[36] = 2
    XCTAssertEqual(scorer.calculateRobustScore(answers: answers), .failure(.unknownItems))
    answers.removeValue(forKey: 1)
    XCTAssertEqual(scorer.calculateRobustScore(answers: answers), .failure(.unknownItems), "35 answers with a wrong ID")
    XCTAssertEqual(scorer.calculateRobustScore(answers: [0: 1]), .failure(.unknownItems))
  }

  func testOutOfRangeValuesAreRejectedIncludingNominalItems() {
    for value in [-1, 0, 5, Int.max, Int.min] {
      for item in [1, 7, 9, 35] {
        var answers = complete
        answers[item] = value
        XCTAssertEqual(scorer.calculateRobustScore(answers: answers), .failure(.invalidResponse), "item \(item) value \(value)")
      }
    }
  }

  func testResearchScoringAlwaysFailsLocally() {
    XCTAssertEqual(scorer.calculateRobustScore(answers: complete, researchMode: true), .failure(.researchRequiresServer))
    XCTAssertEqual(scorer.calculateRobustScore(answers: [:], researchMode: true), .failure(.researchRequiresServer))
  }

  func testUniformAnswersAreValidWithoutInventedResponseQuality() throws {
    for answer in 1...4 {
      let profile = try scorer.calculateRobustScore(answers: Dictionary(uniqueKeysWithValues: (1...35).map { ($0, answer) })).get()
      let expected = (Double(answer) - 0.5) * 25
      XCTAssertTrue(values(profile).allSatisfy { $0 == expected }, "uniform \(answer) must score \(expected)")
    }
  }

  func testEverySubscaleIsIndependent() throws {
    let baseline = values(try scorer.calculateRobustScore(answers: complete).get())
    for group in 0..<7 {
      var answers = complete
      for item in (group * 5 + 1)...(group * 5 + 5) { answers[item] = 4 }
      let result = values(try scorer.calculateRobustScore(answers: answers).get())
      for other in 0..<7 {
        if other == group { XCTAssertGreaterThan(result[other], baseline[other]) } else { XCTAssertEqual(result[other], baseline[other], "group \(group) changed group \(other)") }
      }
    }
  }

  func testNominalItemsNeverChangeNumericScores() throws {
    let baseline = try scorer.calculateRobustScore(answers: complete).get()
    for value in 1...4 {
      var answers = complete
      answers[7] = value
      answers[9] = value
      XCTAssertEqual(try scorer.calculateRobustScore(answers: answers).get(), baseline)
    }
  }

  func testScoreIsTheEqualWeightMeanOnTheDisplayScale() throws {
    var answers = complete
    let chosen: [Int] = [1, 2, 3, 4, 4]
    for (offset, item) in (1...5).enumerated() { answers[item] = chosen[offset] }
    let profile = try scorer.calculateRobustScore(answers: answers).get()
    var sum = 0.0
    for value in chosen { sum += (Double(value) - 0.5) * 25 }
    XCTAssertEqual(profile.epsilon, sum / 5, accuracy: 1e-9)
    XCTAssertTrue(values(profile).allSatisfy { (12.5...87.5).contains($0) })
  }

  func testPartialProfileIsOnlyForLocalProgress() {
    let partial = APGIScorer.descriptiveProfile(answers: [1: 4, 2: 4])
    XCTAssertEqual(partial.epsilon, 87.5)
    XCTAssertEqual(partial.precision, 0)
    XCTAssertEqual(scorer.calculateRobustScore(answers: [1: 4, 2: 4]), .failure(.incomplete))
  }

  func testNoInventedReliabilityOrIntervalsExist() throws {
    let source = try String(contentsOf: URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("APGI-Explorer/Core/APGIScorer.swift"))
    for forbidden in ["baseReliabilities", "flaggedProfile", "performCrossValidation", "1.96", "sigmoid"] {
      XCTAssertFalse(source.contains(forbidden), forbidden)
    }
  }

  func testProfileCategoriesUseFixedBands() {
    XCTAssertEqual(APGIProfile(epsilon: 12.5, precision: 37.5, threshold: 62.5, somaticBias: 87.5,
                               interactionScore: 0, temporalStability: 0, environmentalFit: 0).epsilonCategory, .veryLow)
    XCTAssertEqual(APGIProfile(epsilon: 12.5, precision: 37.5, threshold: 62.5, somaticBias: 87.5,
                               interactionScore: 0, temporalStability: 0, environmentalFit: 0).somaticCategory, .veryHigh)
  }
}
