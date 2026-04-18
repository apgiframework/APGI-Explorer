import XCTest

@testable import APGI_Explorer

@MainActor
final class PerformanceTests: XCTestCase {
  func testAPGIScorerPerformance() {
    let scorer = APGIScorer()
    let testAnswers: [Int: Int] = [
      1: 1,
      2: 2,
      3: 3,
      4: 1,
      5: 2,
    ]

    measure {
      for _ in 0..<1000 {
        _ = scorer.calculateRobustScore(answers: testAnswers)
      }
    }
  }

  func testProfileCalculationPerformance() {
    let scorer = APGIScorer()

    measure {
      for i in 0..<100 {
        let answers = self.generateTestAnswers(count: 50, seed: i)
        _ = scorer.calculateRobustScore(answers: answers)
      }
    }
  }

  func testKeychainPerformance() {
    let keychain = KeychainManager.shared
    let testData = Data("performance_test_data".utf8)

    measure {
      do {
        for i in 0..<100 {
          let key = "perf_test_\(i)"
          try keychain.store(testData, forKey: key)
          _ = try keychain.retrieve(forKey: key)
          try keychain.delete(forKey: key)
        }
      } catch {
        XCTFail("Keychain performance test failed: \(error)")
      }
    }
  }

  func testDatabaseQueryPerformance() {
    let persistenceController = PersistenceController.preview
    let context = persistenceController.container.viewContext

    measure {
      let request: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
      do {
        _ = try context.fetch(request)
      } catch {
        XCTFail("Database query failed: \(error)")
      }
    }
  }

  private func generateTestAnswers(count: Int, seed: Int) -> [Int: Int] {
    var answers: [Int: Int] = [:]
    for i in 0..<count {
      answers[i + 1] = (seed + i) % 5 + 1
    }
    return answers
  }
}
