@testable import APGI_Explorer
import XCTest

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
            for _ in 0 ..< 1000 {
                _ = scorer.calculateScore(for: testAnswers)
            }
        }
    }

    func testProfileCalculationPerformance() {
        let scorer = APGIScorer()

        measure {
            for i in 0 ..< 100 {
                let answers = self.generateTestAnswers(count: 50, seed: i)
                _ = scorer.calculateScore(for: answers)
            }
        }
    }

    func testDataStoragePerformance() {
        let profileManager = ProfileManager()
        let testProfile = self.createTestProfile()

        measure {
            for i in 0 ..< 50 {
                let profile = self.createTestProfile()
                profile.name = "Test Profile \(i)"
                try? profileManager.saveProfile(profile)
            }
        }
    }

    func testKeychainPerformance() {
        let keychain = KeychainManager.shared
        let testData = Data("performance_test_data".utf8)

        measure {
            do {
                for i in 0 ..< 100 {
                    let key = "perf_test_\(i)"
                    try keychain.store(testData, forKey: key)
                    _ = try keychain.retrieve(forKey: key)
                    try keychain.delete(forKey: key)
                }
            }
            catch {
                XCTFail("Keychain performance test failed: \(error)")
            }
        }
    }

    func testExportPerformance() {
        let profileManager = ProfileManager()
        let testProfiles = (0 ..< 10).map { _ in self.createTestProfile() }

        measure {
            do {
                try profileManager.exportProfiles(testProfiles, format: .json)
                try profileManager.exportProfiles(testProfiles, format: .csv)
            }
            catch {
                XCTFail("Export performance test failed: \(error)")
            }
        }
    }

    func testChartRenderingPerformance() {
        let chartData = self.generateChartData(points: 100)

        measure {
            for _ in 0 ..< 10 {
                _ = EnhancedProfileChart(data: chartData)
            }
        }
    }

    func testSearchPerformance() {
        let searchService = StateSearchService()
        let testStates = self.generateTestStates(count: 1000)

        measure {
            for query in ["anxiety", "depression", "stress", "happiness"] {
                _ = searchService.searchStates(query, in: testStates)
            }
        }
    }

    func testMemoryUsageDuringProfileOperations() {
        let profileManager = ProfileManager()
        let initialMemory = self.getMemoryUsage()

        for i in 0 ..< 100 {
            let profile = self.createTestProfile()
            profile.name = "Memory Test Profile \(i)"
            try? profileManager.saveProfile(profile)
        }

        let finalMemory = self.getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory

        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024, "Memory increase should be less than 50MB")
    }

    func testAppLaunchPerformance() {
        measure {
            let app = APGI_ExplorerApp()
            _ = app
        }
    }

    func testDatabaseQueryPerformance() {
        let persistenceController = PersistenceController.preview
        let context = persistenceController.container.viewContext

        measure {
            let request: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
            do {
                _ = try context.fetch(request)
            }
            catch {
                XCTFail("Database query failed: \(error)")
            }
        }
    }

    private func generateTestAnswers(count: Int, seed: Int) -> [String: Int] {
        var answers: [String: Int] = [:]
        for i in 0 ..< count {
            answers["question\(i)"] = (seed + i) % 5 + 1
        }
        return answers
    }

    private func createTestProfile() -> ProfileEntity {
        let context = PersistenceController.preview.container.viewContext
        let profile = ProfileEntity(context: context)
        profile.id = UUID()
        profile.name = "Test Profile"
        profile.createdAt = Date()
        profile.updatedAt = Date()
        return profile
    }

    private func generateChartData(points: Int) -> [CGPoint] {
        (0 ..< points).map { i in
            CGPoint(x: Double(i), y: sin(Double(i) * 0.1) * 50 + 50)
        }
    }

    private func generateTestStates(count: Int) -> [PsychologicalState] {
        (0 ..< count).map { i in
            PsychologicalState(
                id: UUID(),
                name: "State \(i)",
                description: "Test state \(i)",
                anxiety: Double.random(in: 0 ... 1),
                depression: Double.random(in: 0 ... 1),
                stress: Double.random(in: 0 ... 1),
                happiness: Double.random(in: 0 ... 1),
                timestamp: Date()
            )
        }
    }

    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Double(info.resident_size)
        }
        else {
            return 0
        }
    }
}
