import XCTest
import UserNotifications
@testable import APGI_Explorer

@MainActor
final class ExplorerContractTests: XCTestCase {
  private var complete: [Int: Int] { Dictionary(uniqueKeysWithValues: (1...35).map { ($0, 2) }) }

  func testIncompleteAndUnknownInputsNeverProduceProfile() {
    let scorer = APGIScorer()
    XCTAssertEqual(scorer.calculateRobustScore(answers: [:]), .failure(.incomplete))
    XCTAssertEqual(scorer.calculateRobustScore(answers: Dictionary(uniqueKeysWithValues: (1...16).map { ($0, 2) })), .failure(.incomplete))
    var answers = complete
    answers[36] = 2
    XCTAssertEqual(scorer.calculateRobustScore(answers: answers), .failure(.unknownItems))
    answers.removeValue(forKey: 1)
    XCTAssertEqual(scorer.calculateRobustScore(answers: answers), .failure(.unknownItems))
  }

  func testInvalidValuesRejectedIncludingNominalItems() {
    for value in [-1, 0, 5, Int.max] {
      for item in [1, 7, 9, 35] {
        var answers = complete
        answers[item] = value
        XCTAssertEqual(APGIScorer().calculateRobustScore(answers: answers), .failure(.invalidResponse))
      }
    }
  }

  func testResearchScoringAlwaysFailsLocally() {
    XCTAssertEqual(APGIScorer().calculateRobustScore(answers: complete, researchMode: true),
                   .failure(.researchRequiresServer))
  }

  func testUniformAnswersAreValidWithoutInventedResponseQuality() throws {
    let profile = try APGIScorer().calculateRobustScore(answers: complete).get()
    XCTAssertEqual(profile.epsilon, 37.5)
    XCTAssertEqual(profile.precision, 37.5)
  }

  func testEverySubscaleIsIndependent() throws {
    let scorer = APGIScorer()
    let baseline = try scorer.calculateRobustScore(answers: complete).get()
    let baseValues = [baseline.epsilon, baseline.precision, baseline.threshold, baseline.somaticBias,
                      baseline.interactionScore, baseline.temporalStability, baseline.environmentalFit]
    for group in 0..<7 {
      var answers = complete
      for item in (group * 5 + 1)...(group * 5 + 5) { answers[item] = 4 }
      let result = try scorer.calculateRobustScore(answers: answers).get()
      let values = [result.epsilon, result.precision, result.threshold, result.somaticBias,
                    result.interactionScore, result.temporalStability, result.environmentalFit]
      for other in 0..<7 {
        if other == group { XCTAssertGreaterThan(values[other], baseValues[other]) } else { XCTAssertEqual(values[other], baseValues[other]) }
      }
    }
  }

  func testNominalItemsDoNotChangeNumericScores() throws {
    let baseline = try APGIScorer().calculateRobustScore(answers: complete).get()
    var answers = complete
    answers[7] = 4
    answers[9] = 1
    XCTAssertEqual(try APGIScorer().calculateRobustScore(answers: answers).get(), baseline)
  }

  func testSavedAggregatesMatchDisplayedScores() throws {
    let model = QuizModel()
    model.restoreAnswers(complete)
    let profile = try XCTUnwrap(model.calculateScore().profile)
    let saved = QuizModel.calculateAPGIProfile(from: model.calculateRawScore())
    XCTAssertEqual(saved.epsilon, profile.epsilon.rounded())
    XCTAssertEqual(saved.precision, profile.precision.rounded())
    XCTAssertEqual(saved.threshold, profile.threshold.rounded())
    XCTAssertEqual(saved.somaticBias, profile.somaticBias.rounded())
  }

  func testAnswerJournalRoundTripsWithChangesAndProvenance() throws {
    let model = QuizModel()
    model.presentQuestion(at: 6)
    model.selectAnswer(for: 7, answer: 1)
    model.selectAnswer(for: 7, answer: 4)
    model.selectAnswer(for: 7, answer: 4)
    let data = try JSONEncoder().encode(model.snapshot(at: 6))
    let restored = QuizModel()
    restored.restore(try JSONDecoder().decode(QuizModel.Snapshot.self, from: data))
    XCTAssertEqual(restored.sessionID, model.sessionID)
    XCTAssertEqual(restored.events.count, 2)
    XCTAssertEqual(restored.events.map(\.sequence), [0, 1])
    XCTAssertEqual(restored.events.last?.previousValue, 1)
    XCTAssertEqual(restored.answers[7], 4)
    XCTAssertTrue(restored.events.allSatisfy { $0.latencyMS >= 0 && $0.latencyMS.isFinite })
    XCTAssertEqual(restored.snapshot(at: 6).instrumentID, "apgi-explorer-35")
    XCTAssertTrue(restored.snapshot(at: 6).excludedFromNorms)
  }

  func testCompletionRequiresItemSetAndValues() {
    let model = QuizModel()
    model.answers = complete
    XCTAssertTrue(model.isComplete)
    model.answers.removeValue(forKey: 1)
    model.answers[99] = 2
    XCTAssertFalse(model.isComplete)
    XCTAssertNil(model.calculateScore().profile)
  }

  @MainActor func testHandoffContainsSessionIDOnly() {
    let model = QuizModel()
    model.restoreAnswers(complete)
    let activity = HandoffActivity.createUserActivity(quizModel: model, currentQuestionIndex: 12)
    XCTAssertEqual(Set(activity.userInfo?.keys.compactMap { $0 as? String } ?? []), ["sessionID"])
    XCTAssertFalse(activity.isEligibleForSearch)
  }

  @MainActor func testPaidFeaturesIgnoreLegacyEntitlements() async {
    let store = StoreManager.shared
    store.purchasedProductIDs = Set(StoreManager.ProductID.allCases.map(\.rawValue))
    defer { store.purchasedProductIDs = [] }
    XCTAssertFalse(store.hasPremiumFeatures)
    XCTAssertFalse(store.hasProfessionalFeatures)
    XCTAssertFalse(store.hasResearchFeatures)
    XCTAssertFalse(store.hasUnlimitedProfiles)
    await store.loadProducts()
    XCTAssertTrue(store.products.isEmpty)
  }
}

private final class APIStub: URLProtocol {
  static var responder: ((URLRequest) throws -> (Int, Data))?
  override static func canInit(with request: URLRequest) -> Bool { true }
  override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      guard let responder = Self.responder, let url = request.url else {
        throw URLError(.badURL)
      }
      let (status, data) = try responder(request)
      guard let response = HTTPURLResponse(
        url: url, statusCode: status, httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"]
      ) else {
        throw URLError(.badServerResponse)
      }
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}

@MainActor
final class ExplorerAPIContractTests: XCTestCase {
  private func client() -> APGIAPIClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [APIStub.self]
    return APGIAPIClient(session: URLSession(configuration: config))
  }
  override func tearDown() { APIStub.responder = nil }

  func testGeneratedRoutesUseCanonicalOriginWithoutPersonalData() async throws {
    var paths: [String] = []
    APIStub.responder = { request in
      XCTAssertEqual(request.url?.scheme, "https")
      XCTAssertEqual(request.url?.host, "api.apgiframework.com")
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertNil(request.httpBody)
      XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
      let url = try XCTUnwrap(request.url)
      paths.append(url.path)
      return (200, Data("{}".utf8))
    }
    _ = try await client().version()
    _ = try await client().metadata()
    XCTAssertEqual(paths, ["/v1/version", "/v1/meta"])
  }

  func testServerErrorDoesNotBecomeSuccessfulMetadata() async {
    APIStub.responder = { _ in (500, Data("{\"error\":\"internal\"}".utf8)) }
    do { _ = try await client().metadata(); XCTFail("Expected HTTP failure") } catch APGIAPIError.http(let status) { XCTAssertEqual(status, 500) } catch { XCTFail("Unexpected error: \(error)") }
  }

  func testOfflineAndMalformedJSONFail() async {
    APIStub.responder = { _ in throw URLError(.notConnectedToInternet) }
    do { _ = try await client().metadata(); XCTFail("Expected offline error") } catch {}
    APIStub.responder = { _ in (200, Data("not JSON".utf8)) }
    do { _ = try await client().metadata(); XCTFail("Expected decoding error") } catch {}
  }

  func testAbsentAndWrongTypeFlagsStayDisabled() throws {
    var metadata = Dictionary(uniqueKeysWithValues:
      ["researcher", "osf", "zenodo", "code", "web", "licences"].map { ($0, APIJSONValue.object([:])) })
    metadata["release_state"] = .object(["current": .string("pre-registered")])
    var policy = try ExplorerReleasePolicy(metadata: metadata)
    XCTAssertFalse(policy.validationResults)
    XCTAssertFalse(policy.researchEnabled)
    XCTAssertFalse(policy.paidProductsEnabled)
    metadata["release_state"] = .object(["current": .string("calibrated"),
                                         "validation_results": .string("true"), "research_mode": .bool(true)])
    policy = try ExplorerReleasePolicy(metadata: metadata)
    XCTAssertFalse(policy.validationResults)
    XCTAssertFalse(policy.researchEnabled)
    XCTAssertFalse(policy.paidProductsEnabled)
    XCTAssertThrowsError(try ExplorerReleasePolicy(metadata: [:]))
  }
}

@MainActor
final class ExplorerPersistenceTests: XCTestCase {
  func testPersonalJournalPersistsAndUpsertsWithoutLosingAnswerChanges() throws {
    let storage = PersistenceController(inMemory: true)
    let model = QuizModel()
    model.selectAnswer(for: 1, answer: 1)
    try storage.savePersonalSession(model.snapshot(at: 0))
    model.selectAnswer(for: 1, answer: 3)
    try storage.savePersonalSession(model.snapshot(at: 0))
    let context = storage.container.viewContext
    try context.performAndWait {
      let rows = try context.fetch(QuizSession.fetchRequest())
      XCTAssertEqual(rows.count, 1)
      let data = try XCTUnwrap(rows.first?.jsonData)
      let snapshot = try JSONDecoder().decode(QuizModel.Snapshot.self, from: data)
      XCTAssertEqual(snapshot.events.map(\.value), [1, 3])
      XCTAssertEqual(snapshot.answers[1], 3)
      XCTAssertFalse(try XCTUnwrap(rows.first).isCompleted)
    }
  }
}

@MainActor
final class ExplorerExportContractTests: XCTestCase {
  func testRExportHasSourceExtensionAndShareableURL() async throws {
    let model = QuizModel()
    model.restoreAnswers(Dictionary(uniqueKeysWithValues: (1...35).map { ($0, 2) }))
    let profile = QuizProfile(id: UUID(), name: "Export Test", dateCreated: Date(), dateModified: Date(),
                              results: model.calculateRawScore())
    let manager = ProfileManager()
    let exportedURL = await manager.getExportURL(for: profile, format: .rData)
    let url = try XCTUnwrap(exportedURL)
    XCTAssertEqual(url.pathExtension, "R")
    let script = try String(contentsOf: url, encoding: .utf8)
    XCTAssertTrue(script.contains("save(apgi_data, file ="))
    XCTAssertFalse(script.contains("autonomy"))
  }

  func testUnsafeProfileNamesCannotEscapeExportDirectory() {
    let profile = QuizProfile(id: UUID(), name: "../../outside\\name", dateCreated: Date(),
                              dateModified: Date(), results: [:])
    let filename = ExportUtilities.generateExportFilename(profile: profile, format: .json)
    XCTAssertFalse(filename.contains("/"))
    XCTAssertFalse(filename.contains("\\"))
    XCTAssertFalse(filename.contains(".."))
  }

  func testXMLExportEscapesProfileNameAndIncludesProvenance() throws {
    let profile = QuizProfile(id: UUID(), name: "A < B & C", dateCreated: Date(),
                              dateModified: Date(), results: [:])
    let scores = APGIScorer.descriptiveProfile(answers: [1: 2])
    let export = ProfileExport(version: "2.0", timestamp: Date(), profile: profile, apgiScores: scores)
    let data = try ResearchExportManager.shared.exportProfile(export, format: .xml)
    let text = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertTrue(text.contains("A &lt; B &amp; C"))
    XCTAssertTrue(text.contains("<ExcludedFromNorms>true</ExcludedFromNorms>"))
    XCTAssertFalse(text.contains("Autonomy"))
  }
}

extension ExplorerExportContractTests {
  func testBasicPDFExportContainsRealPDFBytes() async throws {
    let profile = QuizProfile(id: UUID(), name: "PDF Test", dateCreated: Date(), dateModified: Date(),
                              results: ["epsilon": 38, "precision": 38, "threshold": 38, "somatic": 38])
    let exportedURL = await ProfileManager().getExportURL(for: profile, format: .pdf)
    let url = try XCTUnwrap(exportedURL)
    let data = try Data(contentsOf: url)
    XCTAssertEqual(try XCTUnwrap(String(data: data.prefix(5), encoding: .utf8)), "%PDF-")
  }
}

@MainActor
final class NotificationPermissionTests: XCTestCase {
  func testUnauthorizedNotificationsCannotBeScheduled() {
    XCTAssertFalse(NotificationAuthorizationPolicy.canSchedule(.notDetermined))
    XCTAssertFalse(NotificationAuthorizationPolicy.canSchedule(.denied))
    XCTAssertTrue(NotificationAuthorizationPolicy.canSchedule(.authorized))
    XCTAssertTrue(NotificationAuthorizationPolicy.canSchedule(.provisional))
  }
}
