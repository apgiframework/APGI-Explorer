import CoreData
import XCTest
@testable import APGI_Explorer

/// Native tests for the research outbox, credential store and product gate.
/// NOT executed in the Linux environment where they were written; run them with the Xcode
/// test command in `.github/workflows/ci.yml` on macOS before merging.
@MainActor
final class ResearchNativeTests: XCTestCase {
  private var directory: URL!

  override func setUpWithError() throws {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent("outbox-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: directory)
  }

  private func momURL(_ name: String) throws -> URL {
    try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "mom", subdirectory: "APGIExplorer.momd"),
                  "missing compiled model \(name)")
  }

  private func container(model: NSManagedObjectModel, store: URL) throws -> NSPersistentContainer {
    let container = NSPersistentContainer(name: "APGIExplorer", managedObjectModel: model)
    let description = NSPersistentStoreDescription(url: store)
    description.shouldMigrateStoreAutomatically = true
    description.shouldInferMappingModelAutomatically = true
    description.shouldAddStoreAsynchronously = false
    container.persistentStoreDescriptions = [description]
    var failure: Error?
    container.loadPersistentStores { _, error in failure = error }
    if let failure { throw failure }
    return container
  }

  private func currentModel() throws -> NSManagedObjectModel {
    let url = try XCTUnwrap(Bundle.main.url(forResource: "APGIExplorer", withExtension: "momd"))
    return try XCTUnwrap(NSManagedObjectModel(contentsOf: url))
  }

  private func record(_ seq: Int, session: String = "s1") -> PendingEventRecord {
    let payload = Data(#"{"item_id":1,"value":2}"#.utf8)
    return PendingEventRecord(
      eventKey: EventKey.make(sessionID: session, seqNo: seq), sessionID: session, seqNo: seq, payload: payload,
      payloadDigest: PortableSHA256.hexDigest(payload), state: .pending, attemptCount: 0, nextAttemptAt: nil,
      createdAt: Date(), verifiedAt: nil)
  }

  func testCurrentModelContainsPendingEventAndOriginalVersionDoesNot() throws {
    XCTAssertNotNil(try currentModel().entitiesByName["PendingEvent"])
    let original = try XCTUnwrap(NSManagedObjectModel(contentsOf: try momURL("APGISignature")))
    XCTAssertNil(original.entitiesByName["PendingEvent"], "the original model version must stay unchanged")
    XCTAssertNotNil(original.entitiesByName["QuizSession"])
  }

  func testOutboxSurvivesContainerRestartAndTombstoneBlocksReenqueue() async throws {
    let storeURL = directory.appendingPathComponent("outbox.sqlite")
    let model = try currentModel()
    var first: NSPersistentContainer? = try container(model: model, store: storeURL)
    var store = CoreDataPendingEventStore(container: try XCTUnwrap(first))
    let one = record(0)
    let two = record(1)
    _ = try await store.insertIfAbsent(one)
    _ = try await store.insertIfAbsent(two)
    try await store.markVerified(eventKey: one.eventKey, at: Date())
    first = nil

    let reopened = try container(model: model, store: storeURL)
    store = CoreDataPendingEventStore(container: reopened)
    let tombstone = try await store.record(eventKey: one.eventKey)
    XCTAssertEqual(tombstone?.state, .verified)
    XCTAssertNil(tombstone?.payload, "a verified entry keeps no payload")
    let again = try await store.insertIfAbsent(one)
    XCTAssertEqual(again, .alreadyAcknowledged(eventKey: one.eventKey))
    let pending = try await store.record(eventKey: two.eventKey)
    XCTAssertNotNil(pending?.payload)
    let sessions = try await store.sessionsWithWork()
    XCTAssertEqual(sessions, ["s1"])
  }

  /// The model the app actually loads (through `PersistenceController`, i.e. whatever `.xccurrentversion`
  /// selects after Xcode compiles the `.momd`) must expose the outbox with every attribute the store uses.
  func testModelTheAppLoadsContainsTheOutboxEntity() throws {
    let loaded = PersistenceController(inMemory: true).container.managedObjectModel
    let entity = try XCTUnwrap(loaded.entitiesByName["PendingEvent"], "the selected model version must contain PendingEvent")
    XCTAssertEqual(Set(entity.attributesByName.keys),
                   ["attemptCount", "createdAt", "eventKey", "nextAttemptAt", "payload", "payloadDigest",
                    "seqNo", "sessionID", "stateRaw", "verifiedAt"])
    XCTAssertFalse(entity.uniquenessConstraints.isEmpty, "eventKey uniqueness keeps tombstones from being duplicated")
    XCTAssertNotNil(loaded.entitiesByName["QuizSession"], "personal data model must remain")
    XCTAssertEqual(loaded.entitiesByName.keys.sorted(), try currentModel().entitiesByName.keys.sorted())
  }

  /// Retry state is durable: after a failed attempt the counter, the deadline and the payload survive a
  /// restart of the persistent container, the backoff still blocks early uploads, an interrupted upload
  /// returns to pending, and the next failure continues the schedule instead of restarting it.
  func testRetryAndBackoffStateSurviveContainerRestart() async throws {
    let storeURL = directory.appendingPathComponent("retry.sqlite")
    let model = try currentModel()
    let first = record(0)
    let second = record(1)
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)
    var container: NSPersistentContainer? = try self.container(model: model, store: storeURL)
    var store = CoreDataPendingEventStore(container: try XCTUnwrap(container))
    _ = try await store.insertIfAbsent(first)
    _ = try await store.insertIfAbsent(second)
    try await store.markUploading(eventKeys: [first.eventKey, second.eventKey])
    try await store.recordFailure(eventKey: first.eventKey, nextAttemptAt: t0.addingTimeInterval(5))
    container = nil

    store = CoreDataPendingEventStore(container: try self.container(model: model, store: storeURL))
    var stored = try await store.record(eventKey: first.eventKey)
    XCTAssertEqual(stored?.attemptCount, 1)
    XCTAssertEqual(stored?.nextAttemptAt, t0.addingTimeInterval(5))
    XCTAssertEqual(stored?.state, .pending)
    XCTAssertEqual(stored?.payload, first.payload, "the payload is retained until a verified acknowledgement")
    let interrupted = try await store.record(eventKey: second.eventKey)
    XCTAssertEqual(interrupted?.state, .uploading, "the interrupted upload is still marked in flight")

    try await store.resetInFlight()
    var due = try await store.dueEvents(sessionID: "s1", now: t0, limit: 10)
    XCTAssertTrue(due.isEmpty, "the backoff deadline survives the restart and blocks later events too")
    due = try await store.dueEvents(sessionID: "s1", now: t0.addingTimeInterval(5), limit: 10)
    XCTAssertEqual(due.map(\.seqNo), [0, 1])

    try await store.recordFailure(eventKey: first.eventKey, nextAttemptAt: t0.addingTimeInterval(15))
    stored = try await store.record(eventKey: first.eventKey)
    XCTAssertEqual(stored?.attemptCount, 2, "the attempt counter continues across the restart")
    XCTAssertEqual(stored?.nextAttemptAt, t0.addingTimeInterval(15))
  }

  func testSequenceOrderingBackoffAndRelaunchReset() async throws {
    let store = CoreDataPendingEventStore(container: try container(model: try currentModel(),
                                                                   store: directory.appendingPathComponent("order.sqlite")))
    for seq in [2, 0, 1] { _ = try await store.insertIfAbsent(record(seq)) }
    let now = Date()
    var due = try await store.dueEvents(sessionID: "s1", now: now, limit: 10)
    XCTAssertEqual(due.map(\.seqNo), [0, 1, 2])
    try await store.markUploading(eventKeys: due.map(\.eventKey))
    due = try await store.dueEvents(sessionID: "s1", now: now, limit: 10)
    XCTAssertTrue(due.isEmpty)
    try await store.resetInFlight()
    try await store.recordFailure(eventKey: EventKey.make(sessionID: "s1", seqNo: 0), nextAttemptAt: now.addingTimeInterval(60))
    due = try await store.dueEvents(sessionID: "s1", now: now, limit: 10)
    XCTAssertTrue(due.isEmpty, "later events must not overtake a backed-off earlier event")
    due = try await store.dueEvents(sessionID: "s1", now: now.addingTimeInterval(61), limit: 10)
    XCTAssertEqual(due.first?.attemptCount, 1)
  }

  func testConflictingPayloadForSameSequenceIsRejected() async throws {
    let store = CoreDataPendingEventStore(container: try container(model: try currentModel(),
                                                                   store: directory.appendingPathComponent("conflict.sqlite")))
    _ = try await store.insertIfAbsent(record(0))
    var other = record(0)
    other = PendingEventRecord(eventKey: other.eventKey, sessionID: "s1", seqNo: 0, payload: Data("x".utf8),
                               payloadDigest: PortableSHA256.hexDigest("x"), state: .pending, attemptCount: 0,
                               nextAttemptAt: nil, createdAt: Date(), verifiedAt: nil)
    do { _ = try await store.insertIfAbsent(other); XCTFail() } catch {
      XCTAssertEqual(error as? OutboxError, .conflictingPayload(seqNo: 0))
    }
  }

  /// Lightweight migration: a store written with the original model opens with the new
  /// version, keeps personal data, and gains an empty outbox.
  func testPersonalDataMigratesAndIsNeverReadIntoTheOutbox() async throws {
    let storeURL = directory.appendingPathComponent("migrate.sqlite")
    let original = try XCTUnwrap(NSManagedObjectModel(contentsOf: try momURL("APGISignature")))
    let old = try container(model: original, store: storeURL)
    let session = NSEntityDescription.insertNewObject(forEntityName: "QuizSession", into: old.viewContext)
    session.setValue(UUID(), forKey: "id")
    session.setValue(Date(), forKey: "createdAt")
    session.setValue(false, forKey: "isCompleted")
    session.setValue(3, forKey: "progress")
    session.setValue(Data(#"{"answers":{"1":2}}"#.utf8), forKey: "jsonData")
    try old.viewContext.save()
    for store in old.persistentStoreCoordinator.persistentStores { try old.persistentStoreCoordinator.remove(store) }

    let migrated = try container(model: try currentModel(), store: storeURL)
    let sessions = try migrated.viewContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "QuizSession"))
    XCTAssertEqual(sessions.count, 1)
    XCTAssertEqual(sessions.first?.value(forKey: "progress") as? Int32, 3)
    let store = CoreDataPendingEventStore(container: migrated)
    let work = try await store.sessionsWithWork()
    XCTAssertTrue(work.isEmpty, "personal journals never feed the research outbox")
  }

  func testResearchCredentialsUseDeviceKeychainAndRotate() async throws {
    let store = ResearchKeychainCredentialStore(service: "org.apgiframework.APGI-Explorer.tests.\(UUID().uuidString)")
    defer { try? store.clear() }
    XCTAssertNil(try store.load())
    let expired = ResearchCredentials(accessToken: "a0", refreshToken: "r0", accessExpiry: Date().addingTimeInterval(-5))
    try store.save(expired)
    XCTAssertEqual(try store.load(), expired)
    struct Rotating: ResearchTokenRefreshing {
      func refresh(refreshToken: String) async throws -> ResearchCredentials {
        ResearchCredentials(accessToken: "a1", refreshToken: "r1", accessExpiry: Date().addingTimeInterval(3_600))
      }
    }
    let manager = ResearchCredentialManager(store: store, refresher: Rotating())
    let token = try await manager.validAccessToken()
    XCTAssertEqual(token, "a1")
    XCTAssertEqual(try store.load()?.refreshToken, "r1")
    try await manager.signOut()
    XCTAssertNil(try store.load())
    XCTAssertNil(UserDefaults.standard.object(forKey: "keychain_fallback_research-credentials"))
  }

  func testProductsStayDisabledEvenWhenRemoteFlagIsTrue() async throws {
    XCTAssertFalse(ProductEligibility.current(remoteValidationResults: true).isEligible)
    let manager = StoreManager.shared
    await manager.loadProducts()
    XCTAssertTrue(manager.products.isEmpty)
    await manager.restorePurchases()
    XCTAssertTrue(manager.purchasedProductIDs.isEmpty)
    XCTAssertFalse(manager.hasPremiumFeatures || manager.hasProfessionalFeatures
                   || manager.hasResearchFeatures || manager.hasUnlimitedProfiles)
  }

  /// The approved-test-build configuration exists only in Debug builds compiled with the flag.
  func testResearchStaysOffUnlessThisIsAnApprovedDebugTestBuild() {
    XCTAssertFalse(ExplorerBuildApproval.researchApproved)
    #if DEBUG && APGI_RESEARCH_TEST_BUILD
      XCTAssertTrue(ResearchTestBuild.isCompiledIn)
      XCTAssertNil(ResearchTestBuild.resolve(production: APGIIdentifiers.api, environment: [:]),
                   "a test build without a test server must not fall back to production")
    #else
      XCTAssertFalse(ResearchTestBuild.isCompiledIn)
      XCTAssertNil(ResearchTestBuild.resolve(production: APGIIdentifiers.api,
                                             environment: [ResearchTestBuild.environmentKey: "https://research-test.example.org"]))
    #endif
  }
}
