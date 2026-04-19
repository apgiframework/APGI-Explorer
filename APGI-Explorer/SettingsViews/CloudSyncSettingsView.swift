import CloudKit
import SwiftUI

struct CloudSyncSettingsView: View {
  @StateObject private var cloudSyncManager = CloudSyncManager.shared
  @State private var showingErrorAlert = false
  @State private var showingResetConfirmation = false
  @AppStorage("cloudAutoSyncEnabled") private var cloudAutoSyncEnabled = true
  @AppStorage("cloudSyncOverCellular") private var cloudSyncOverCellular = false

  var body: some View {
    Form {
      Section {
        HStack {
          VStack(alignment: .leading) {
            Text("iCloud Sync")
              .font(.headline)
            Text("Sync your profiles across all your devices")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          self.accountStatusView
        }

        if self.cloudSyncManager.accountStatus == .available {
          Button(action: {
            Task {
              await self.performSync()
            }
          }) {
            HStack {
              if self.cloudSyncManager.isSyncing {
                ProgressView()
                  .scaleEffect(0.8)
                Text("Syncing...")
              } else {
                Image(systemName: "icloud.and.arrow.up")
                Text("Sync Now")
              }
            }
          }
          .disabled(self.cloudSyncManager.isSyncing)

          if let lastSync = cloudSyncManager.lastSyncDate {
            Text("Last sync: \(lastSync, style: .relative) ago")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }

      if self.cloudSyncManager.accountStatus == .available {
        Section("Sync Options") {
          Toggle("Auto-sync", isOn: self.$cloudAutoSyncEnabled)

          Toggle("Sync over cellular data", isOn: self.$cloudSyncOverCellular)
        }
      }

      if self.cloudSyncManager.accountStatus == .available {
        Section("Advanced") {
          Button("Reset Cloud Data") {
            self.showingResetConfirmation = true
          }
          .foregroundColor(.red)

          Button("Check Account Status") {
            self.cloudSyncManager.checkAccountStatus()
          }
        }
      }

      Section("Information") {
        VStack(alignment: .leading, spacing: 8) {
          CloudSyncInfoRow(title: "Status", value: self.accountStatusText)
          CloudSyncInfoRow(title: "Container", value: "iCloud.com.lesoto.APGI-Explorer")
          CloudSyncInfoRow(
            title: "Environment",
            value: (Bundle.main.object(forInfoDictionaryKey: "APS-Environment") as? String)?
              .capitalized ?? "Unknown"
          )
        }
      }
    }
    .navigationTitle("Cloud Sync")
    .alert("Sync Error", isPresented: self.$showingErrorAlert) {
      Button("OK") {
      }
    } message: {
      if let error = cloudSyncManager.syncError {
        Text(error.localizedDescription)
      }
    }
    .alert("Reset Cloud Data", isPresented: self.$showingResetConfirmation) {
      Button("Cancel", role: .cancel) {
      }
      Button("Reset", role: .destructive) {
        Task {
          await self.resetCloudData()
        }
      }
    } message: {
      Text("This will permanently delete all profiles from iCloud. This action cannot be undone.")
    }
    .onAppear {
      self.cloudSyncManager.checkAccountStatus()
    }
  }

  private var accountStatusView: some View {
    HStack {
      Image(systemName: self.accountStatusIcon)
        .foregroundColor(self.accountStatusColor)
      Text(self.accountStatusText)
        .font(.caption)
        .foregroundColor(self.accountStatusColor)
    }
  }

  private var accountStatusIcon: String {
    switch self.cloudSyncManager.accountStatus {
    case .available:
      return "checkmark.circle.fill"
    case .noAccount:
      return "person.crop.circle.badge.exclamationmark"
    case .restricted:
      return "exclamationmark.triangle.fill"
    case .couldNotDetermine:
      return "questionmark.circle"
    case .temporarilyUnavailable:
      return "clock.circle"
    @unknown default:
      return "questionmark.circle"
    }
  }

  private var accountStatusColor: Color {
    switch self.cloudSyncManager.accountStatus {
    case .available:
      return .green
    case .noAccount, .restricted:
      return .red
    case .couldNotDetermine, .temporarilyUnavailable:
      return .orange
    @unknown default:
      return .gray
    }
  }

  private var accountStatusText: String {
    switch self.cloudSyncManager.accountStatus {
    case .available:
      return "Available"
    case .noAccount:
      return "No iCloud Account"
    case .restricted:
      return "Restricted"
    case .couldNotDetermine:
      return "Checking..."
    case .temporarilyUnavailable:
      return "Temporarily Unavailable"
    @unknown default:
      return "Unknown"
    }
  }

  private func performSync() async {
    do {
      try await self.cloudSyncManager.syncProfiles()
    } catch {
      self.cloudSyncManager.syncError = CloudSyncManager.CloudSyncError.unknown(error)
      self.showingErrorAlert = true
    }
  }

  private func resetCloudData() async {
    do {
      try await self.cloudSyncManager.resetCloudData()
    } catch {
      self.cloudSyncManager.syncError = CloudSyncManager.CloudSyncError.unknown(error)
      self.showingErrorAlert = true
    }
  }
}

struct CloudSyncInfoRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack {
      Text(self.title)
        .foregroundColor(.secondary)
      Spacer()
      Text(self.value)
        .foregroundColor(.primary)
    }
  }
}

struct CloudSyncSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    CloudSyncSettingsView()
  }
}
