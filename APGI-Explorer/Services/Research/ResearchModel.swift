import Combine
import Foundation

/// View model for the opt-in research flow. In this build `ExplorerBuildApproval.researchApproved`
/// is false, so `refreshAvailability()` returns before any network call and the UI never appears.
@MainActor
final class ResearchModel: ObservableObject {
  static let shared = ResearchModel()

  enum Phase: Equatable {
    case unavailable, idle, preparing, consent, signIn, questionnaire, finishing
    case result([DisplayedScore])
    case failed(String)
  }

  @Published private(set) var phase: Phase = .unavailable
  @Published private(set) var preparation: ResearchPreparation?
  @Published private(set) var answers: [Int: Int] = [:]
  @Published private(set) var pendingUploads = 0
  @Published var errorMessage: String?
  /// Purposes the participant ticked on the consent screen.
  @Published private(set) var acceptedPurposes: Set<String> = []

  private var workflow: ResearchWorkflow?
  private var background: BackgroundUploadSession?

  var isAvailable: Bool { phase != .unavailable }

  private func fail(_ error: Error) {
    errorMessage = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
  }

  /// Decides whether research can be offered at all. Build approval first, then the server flag.
  func refreshAvailability() async {
    guard ExplorerBuildApproval.researchApproved else { phase = .unavailable; return }
    do {
      let transport = try APITransport(baseURL: APGIIdentifiers.api)
      let config = try await ExplorerResearchClient(transport: transport).config()
      let capability = ResearchCapability.current(serverResearchEnabled: config.researchEnabled)
      guard capability.isEnabled else { phase = .unavailable; return }
      workflow = try makeWorkflow(capability: capability, transport: transport)
      phase = .idle
    } catch {
      phase = .unavailable
    }
  }

  private func makeWorkflow(capability: ResearchCapability, transport: APITransport) throws -> ResearchWorkflow {
    let background = try BackgroundUploadSession(baseURL: APGIIdentifiers.api,
                                                 identifier: "org.apgiframework.APGI-Explorer.research-upload")
    self.background = background
    let account = ResearchAccountClient(transport: transport)
    let credentials = ResearchCredentialManager(store: ResearchKeychainCredentialStore(),
                                                refresher: APIResearchTokenRefresher(account: account))
    let coordinator = UploadCoordinator(
      store: CoreDataPendingEventStore(container: PersistenceController.shared.container),
      adapter: ExplorerResearchAdapter(transport: background), capability: capability,
      authorization: { try await credentials.validAccessToken() })
    return ResearchWorkflow(client: ExplorerResearchClient(transport: transport), account: account,
                            credentials: credentials, coordinator: coordinator,
                            progress: ResearchKeychainProgressStore(), capability: capability)
  }

  func begin() async {
    guard let workflow else { return }
    phase = .preparing
    errorMessage = nil
    do {
      preparation = try await workflow.prepare()
      _ = try await workflow.recover()
      phase = .consent
    } catch {
      fail(error)
      phase = .idle
    }
  }

  func setAccepted(_ purposes: Set<String>) { acceptedPurposes = purposes }

  func continueFromConsent() { phase = .signIn }

  func signInAndEnroll(username: String, password: String, email: String?, accepted: Set<String>) async {
    guard let workflow else { return }
    errorMessage = nil
    do {
      if let email, !email.isEmpty {
        try await workflow.register(username: username, email: email, password: password)
      } else {
        try await workflow.signIn(username: username, password: password)
      }
      try await workflow.enroll(accepted: accepted)
      answers = await workflow.answers
      pendingUploads = (try? await workflow.pendingCount()) ?? 0
      phase = .questionnaire
    } catch {
      fail(error)
    }
  }

  func show(itemID: Int) async {
    try? await workflow?.show(itemID: itemID)
  }

  func answer(itemID: Int, value: Int) async {
    guard let workflow else { return }
    do {
      try await workflow.answer(itemID: itemID, value: value)
      answers = await workflow.answers
      pendingUploads = (try? await workflow.pendingCount()) ?? pendingUploads
      Task { await self.sync() }
    } catch {
      fail(error)
    }
  }

  /// Uploads in the background; offline or failed attempts keep the data and retry with backoff.
  func sync() async {
    guard let workflow else { return }
    _ = await workflow.sync()
    pendingUploads = (try? await workflow.pendingCount()) ?? pendingUploads
  }

  func finish() async {
    guard let workflow else { return }
    phase = .finishing
    do {
      phase = .result(try await workflow.finish())
      answers = [:]
    } catch {
      fail(error)
      phase = .questionnaire
    }
  }

  func withdraw() async {
    guard let workflow else { return }
    do {
      try await workflow.withdraw(purposes: ["research_participation", "product_use"])
      answers = [:]
      pendingUploads = 0
      phase = .idle
    } catch {
      fail(error)
    }
  }

  func close() { if case .result = phase { phase = .idle } }
}
