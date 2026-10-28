import Combine
import SwiftUI

@MainActor
final class ExplorerAPIStatus: ObservableObject {
  static let shared = ExplorerAPIStatus()
  @Published private(set) var message = "Connection not checked"
  @Published private(set) var isChecking = false
  @Published private(set) var policy: ExplorerReleasePolicy?
  private let client = APGIAPIClient()

  func refresh() async {
    guard !isChecking else { return }
    isChecking = true
    policy = nil
    defer { isChecking = false }
    do {
      let metadata = try await client.metadata()
      let policy = try ExplorerReleasePolicy(metadata: metadata)
      self.policy = policy
      message = "Connected · \(policy.releaseState)"
    } catch {
      message = error.localizedDescription
    }
  }
}

struct ExplorerAPIStatusView: View {
  @ObservedObject private var status = ExplorerAPIStatus.shared
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("APGI API").font(.headline)
      Link(APGIIdentifiers.api.absoluteString, destination: APGIIdentifiers.api)
      Text(status.message).foregroundStyle(.secondary).textSelection(.enabled)
      Text("Personal answers stay on this device. Research participation and paid products are unavailable in this release.")
        .font(.caption).foregroundStyle(.secondary)
      Button(status.isChecking ? "Checking…" : "Check connection") {
        Task { await status.refresh() }
      }.disabled(status.isChecking)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
  }
}
