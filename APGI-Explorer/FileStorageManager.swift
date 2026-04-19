import Combine
import Foundation
import os.log

@MainActor
class FileStorageManager: ObservableObject {
  static let shared: FileStorageManager = {
    do {
      return try FileStorageManager()
    } catch {
      // Log the critical error and return a fallback that will show error UI
      os_log(
        "Critical: Unable to initialize FileStorageManager: %{public}@",
        log: OSLog.default, type: .fault, error.localizedDescription)
      // Return a placeholder instance that will fail gracefully on operations
      // Using try! because placeholder mode is designed to never throw
      return try! FileStorageManager(placeholder: true)
    }
  }()

  private let fileManager = FileManager.default
  private var backupTimer: Timer?
  private let isPlaceholder: Bool

  private var documentsDirectory: URL {
    if isPlaceholder {
      // Return a dummy URL that will fail gracefully
      return URL(fileURLWithPath: "/dev/null")
    }
    guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
      // This should not happen in normal circumstances, but handle gracefully
      os_log(
        "Critical: Unable to access Documents directory at runtime",
        log: OSLog.default, type: .fault)
      return URL(fileURLWithPath: "/dev/null")
    }
    return url
  }

  private init(placeholder: Bool = false) throws {
    self.isPlaceholder = placeholder
    if placeholder {
      throw FileStorageError.documentsDirectoryUnavailable
    }
    // Verify documents directory is accessible
    guard fileManager.urls(for: .documentDirectory, in: .userDomainMask).first != nil else {
      throw FileStorageError.documentsDirectoryUnavailable
    }
  }

  private lazy var profilesDirectory: URL = {
    let url = self.documentsDirectory.appendingPathComponent("Profiles", isDirectory: true)
    try? self.fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }()

  private lazy var exportsDirectory: URL = {
    let url = self.documentsDirectory.appendingPathComponent("Exports", isDirectory: true)
    try? self.fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }()

  private lazy var backupsDirectory: URL = {
    let url = self.documentsDirectory.appendingPathComponent("Backups", isDirectory: true)
    try? self.fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }()

  /// CRIT-003 Fix: Add free disk space calculation
  private var freeDiskSpace: UInt64 {
    do {
      let attributes = try fileManager.attributesOfFileSystem(forPath: self.documentsDirectory.path)
      return attributes[.systemFreeSize] as? UInt64 ?? 0
    } catch {
      return 0
    }
  }

  // MARK: - Profile Export/Import

  func exportProfile(_ profile: QuizProfile, to url: URL? = nil) throws -> URL {
    // Check if in placeholder mode
    if isPlaceholder {
      throw FileStorageError.storageUnavailable
    }
    // CRIT-003 Fix: Check available disk space before export
    let requiredSpace: UInt64 = 1024 * 1024  // 1MB minimum estimate
    let availableSpace = self.freeDiskSpace
    guard availableSpace >= requiredSpace else {
      throw AppError.exportFailed(
        underlying: NSError(
          domain: NSPOSIXErrorDomain, code: Int(ENOSPC),
          userInfo: [
            NSLocalizedDescriptionKey:
              "Insufficient disk space for export. Required: \(requiredSpace / 1024)KB, Available: \(availableSpace / 1024)KB"
          ]))
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    let data = try encoder.encode(profile)

    let destinationURL =
      url
      ?? self.exportsDirectory.appendingPathComponent(
        "\(profile.name)_\(profile.id.uuidString).json")

    do {
      try data.write(to: destinationURL)
      return destinationURL
    } catch {
      // CRIT-003 Fix: Provide better error handling for write failures
      throw AppError.exportFailed(underlying: error)
    }
  }

  func importProfile(from url: URL) throws -> QuizProfile {
    if isPlaceholder {
      throw FileStorageError.storageUnavailable
    }
    let data = try Data(contentsOf: url)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    return try decoder.decode(QuizProfile.self, from: data)
  }

  // MARK: - Backup/Restore

  func createBackup() async throws -> URL {
    if isPlaceholder {
      throw FileStorageError.storageUnavailable
    }
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let backupURL = self.backupsDirectory.appendingPathComponent("backup_\(timestamp).json")

    let profiles = try await PersistenceController.shared.fetchProfiles()

    let backup = ProfileBackup(
      version: "1.0",
      createdAt: Date(),
      profiles: profiles,
      settings: captureSettings()
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    let data = try encoder.encode(backup)
    try data.write(to: backupURL)

    return backupURL
  }

  func restoreBackup(from url: URL) async throws {
    if isPlaceholder {
      throw FileStorageError.storageUnavailable
    }
    let data = try Data(contentsOf: url)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let backup = try decoder.decode(ProfileBackup.self, from: data)

    // Restore profiles
    for profile in backup.profiles {
      try await PersistenceController.shared.saveProfile(profile)
    }

    // Restore settings
    self.restoreSettings(backup.settings)
  }

  func listBackups() throws -> [URL] {
    if isPlaceholder {
      throw FileStorageError.storageUnavailable
    }
    let contents = try fileManager.contentsOfDirectory(
      at: self.backupsDirectory,
      includingPropertiesForKeys: [.creationDateKey],
      options: .skipsHiddenFiles
    )

    return
      contents
      .filter { $0.pathExtension == "json" }
      .sorted { url1, url2 in
        let date1 =
          (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
        let date2 =
          (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
        return date1 > date2
      }
  }

  func deleteBackup(at url: URL) throws {
    if isPlaceholder {
      throw FileStorageError.storageUnavailable
    }
    try self.fileManager.removeItem(at: url)
  }

  // MARK: - Automatic Backup Scheduling

  func scheduleAutomaticBackups() {
    if isPlaceholder {
      os_log("Cannot schedule backups: storage unavailable", log: OSLog.default, type: .error)
      return
    }
    // Stop existing timer
    self.backupTimer?.invalidate()

    let frequency = UserDefaultsManager.shared.backupFrequency

    // Don't schedule if manual backup is selected
    guard frequency != .manual else { return }

    let interval = frequency.timeInterval
    guard interval > 0 else { return }

    // Check if backup is needed on background queue
    DispatchQueue.global(qos: .background).async {
      Task { await self.checkAndPerformBackup() }
    }

    // Schedule recurring backups on background queue
    self.backupTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
      DispatchQueue.global(qos: .background).async {
        Task { await self.checkAndPerformBackup() }
      }
    }
  }

  func stopAutomaticBackups() {
    self.backupTimer?.invalidate()
    self.backupTimer = nil
  }

  private func checkAndPerformBackup() {
    let userDefaults = UserDefaultsManager.shared
    let frequency = userDefaults.backupFrequency

    // Skip if manual backup
    guard frequency != .manual else { return }

    // Check if enough time has passed since last backup
    if let lastBackupDate = userDefaults.lastBackupDate {
      let timeSinceLastBackup = Date().timeIntervalSince(lastBackupDate)
      guard timeSinceLastBackup >= frequency.timeInterval else { return }
    }

    // Perform backup
    Task {
      do {
        _ = try await self.createBackup()
        userDefaults.lastBackupDate = Date()
        os_log("Automatic backup completed successfully", log: OSLog.default, type: .info)
      } catch {
        os_log(
          "Automatic backup failed: %{public}@", log: OSLog.default, type: .error,
          error.localizedDescription)
      }
    }
  }

  // MARK: - Helper Methods

  private func captureSettings() -> [String: Any] {
    let prefs = UserDefaultsManager.shared
    return [
      "preferredChartStyle": prefs.preferredChartStyle.rawValue,
      "theme": prefs.theme.rawValue,
      "showConfidenceIndicators": prefs.showConfidenceIndicators,
      "autoSaveEnabled": prefs.autoSaveEnabled,
      "soundEffectsEnabled": prefs.soundEffectsEnabled,
      "hapticsEnabled": prefs.hapticsEnabled,
    ]
  }

  private func restoreSettings(_ settings: [String: Any]) {
    let prefs = UserDefaultsManager.shared

    if let chartStyle = settings["preferredChartStyle"] as? String,
      let style = ChartStyle(rawValue: chartStyle)
    {
      prefs.preferredChartStyle = style
    }

    if let theme = settings["theme"] as? String,
      let appTheme = AppTheme(rawValue: theme)
    {
      prefs.theme = appTheme
    }

    if let showConfidence = settings["showConfidenceIndicators"] as? Bool {
      prefs.showConfidenceIndicators = showConfidence
    }

    if let autoSave = settings["autoSaveEnabled"] as? Bool {
      prefs.autoSaveEnabled = autoSave
    }
  }
}

struct ProfileBackup: Codable {
  let version: String
  let createdAt: Date
  let profiles: [QuizProfile]
  let settings: [String: Any]

  enum CodingKeys: String, CodingKey {
    case version, createdAt, profiles, settings
  }

  init(version: String, createdAt: Date, profiles: [QuizProfile], settings: [String: Any]) {
    self.version = version
    self.createdAt = createdAt
    self.profiles = profiles
    self.settings = settings
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.version = try container.decode(String.self, forKey: .version)
    self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    self.profiles = try container.decode([QuizProfile].self, forKey: .profiles)
    self.settings = try container.decode([String: AnyCodable].self, forKey: .settings)
      .mapValues { $0.value }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.version, forKey: .version)
    try container.encode(self.createdAt, forKey: .createdAt)
    try container.encode(self.profiles, forKey: .profiles)
    try container.encode(self.settings.mapValues { AnyCodable($0) }, forKey: .settings)
  }
}

struct AnyCodable: Codable {
  let value: Any

  init(_ value: Any) {
    self.value = value
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let bool = try? container.decode(Bool.self) {
      self.value = bool
    } else if let int = try? container.decode(Int.self) {
      self.value = int
    } else if let double = try? container.decode(Double.self) {
      self.value = double
    } else if let string = try? container.decode(String.self) {
      self.value = string
    } else {
      self.value = ""
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self.value {
    case let bool as Bool:
      try container.encode(bool)
    case let int as Int:
      try container.encode(int)
    case let double as Double:
      try container.encode(double)
    case let string as String:
      try container.encode(string)
    default:
      try container.encodeNil()
    }
  }
}

// MARK: - File Storage Error

enum FileStorageError: LocalizedError {
  case documentsDirectoryUnavailable
  case storageUnavailable

  var errorDescription: String? {
    switch self {
    case .documentsDirectoryUnavailable:
      return "Unable to access the Documents directory. Please check your system permissions."
    case .storageUnavailable:
      return "Storage is currently unavailable. Please restart the app and try again."
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .documentsDirectoryUnavailable:
      return "Ensure the app has permission to access your Documents folder in System Settings."
    case .storageUnavailable:
      return "If the problem persists, please contact support."
    }
  }
}
