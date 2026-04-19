import Combine
import Foundation
import os.log

#if os(iOS)
  import UIKit
#endif

#if os(macOS)
  import Darwin
#else
  import Glibc
#endif

// MARK: - Crash Reporting Manager

class CrashReportingManager: ObservableObject {
  static let shared = CrashReportingManager()

  @Published var isEnabled = false

  // MARK: - Retention Policy

  /// Maximum number of crash reports to keep (default: 50)
  private let maxCrashReportCount = 50

  /// Maximum age of crash reports in days (default: 30)
  private let maxCrashReportAgeDays = 30

  /// Minimum free space required (in MB) before writing new reports (default: 100)
  private let minFreeSpaceMB: UInt64 = 100

  private init() {
    self.setupCrashReporting()
    self.loadSettings()
    self.applyRetentionPolicy()
  }

  private func setupCrashReporting() {
    // Set up crash reporting for uncaught exceptions
    NSSetUncaughtExceptionHandler(handleUncaughtException)

    // Set up BSD signal handlers for common crash signals using proper C library signal()
    // These are C-level signal handlers that will catch hard crashes (segfaults, illegal instructions, etc.)
    // Note: signal() is from Darwin/Glibc C library, not our local stub
    let signalResult1 = Darwin.signal(SIGABRT, handleSignal)
    let signalResult2 = Darwin.signal(SIGILL, handleSignal)
    let signalResult3 = Darwin.signal(SIGSEGV, handleSignal)
    let signalResult4 = Darwin.signal(SIGFPE, handleSignal)
    let signalResult5 = Darwin.signal(SIGBUS, handleSignal)
    let signalResult6 = Darwin.signal(SIGPIPE, handleSignal)

    // Log any failures to install signal handlers
    let results = [
      ("SIGABRT", signalResult1),
      ("SIGILL", signalResult2),
      ("SIGSEGV", signalResult3),
      ("SIGFPE", signalResult4),
      ("SIGBUS", signalResult5),
      ("SIGPIPE", signalResult6),
    ]

    for (name, result) in results {
      // Check if signal handler installation failed
      // SIG_ERR is (void (*)(int))(-1), we compare the raw pointer value
      let resultPtr = unsafeBitCast(result, to: UnsafeRawPointer.self)
      let sigErrPtr = unsafeBitCast(SIG_ERR, to: UnsafeRawPointer.self)
      if resultPtr == sigErrPtr {
        os_log(
          "Failed to install signal handler for %{public}@", log: OSLog.default, type: .error,
          name)
      }
    }
  }

  private func loadSettings() {
    self.isEnabled = UserDefaults.standard.bool(forKey: "crashReportingConsent")
  }

  func enableCrashReporting() {
    self.isEnabled = true
    UserDefaults.standard.set(true, forKey: "crashReportingConsent")
  }

  func disableCrashReporting() {
    self.isEnabled = false
    UserDefaults.standard.set(false, forKey: "crashReportingConsent")
  }

  func reportCrash(_ error: Error, context: String = "") {
    guard self.isEnabled else { return }

    let crashReport = CrashReport(
      error: error,
      context: context,
      timestamp: Date(),
      deviceInfo: collectDeviceInfo(),
      appVersion: getAppVersion()
    )

    self.saveCrashReport(crashReport)
  }

  private func collectDeviceInfo() -> [String: String] {
    var deviceInfo: [String: String] = [:]

    #if os(iOS)
      deviceInfo["deviceModel"] = UIDevice.current.model
      deviceInfo["systemName"] = UIDevice.current.systemName
      deviceInfo["systemVersion"] = UIDevice.current.systemVersion
      deviceInfo["orientation"] = UIDevice.current.orientation.description
    #elseif os(macOS)
      deviceInfo["deviceModel"] = "Mac"
      deviceInfo["systemName"] = "macOS"
      deviceInfo["systemVersion"] = ProcessInfo.processInfo.operatingSystemVersionString
    #endif

    deviceInfo["appVersion"] = self.getAppVersion()
    deviceInfo["buildNumber"] = self.getBuildNumber()

    return deviceInfo
  }

  private func getAppVersion() -> String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  }

  private func getBuildNumber() -> String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
  }

  private func saveCrashReport(_ report: CrashReport) {
    // Check free space before writing
    guard hasSufficientFreeSpace() else {
      os_log(
        "Insufficient disk space to save crash report", log: OSLog.default, type: .error)
      return
    }

    // Apply retention policy before saving new report
    applyRetentionPolicy()

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601

    do {
      let data = try encoder.encode(report)
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let crashReportsPath = documentsPath.appendingPathComponent("CrashReports")

      // Create directory if it doesn't exist
      try FileManager.default.createDirectory(
        at: crashReportsPath, withIntermediateDirectories: true)

      let fileURL = crashReportsPath.appendingPathComponent(
        "crash_\(report.timestamp.timeIntervalSince1970).json")
      try data.write(to: fileURL)

      os_log(
        "Crash report saved: %{public}@", log: OSLog.default, type: .info,
        fileURL.lastPathComponent)
    } catch {
      os_log(
        "Failed to save crash report: %{public}@", log: OSLog.default, type: .error,
        error.localizedDescription)
    }
  }

  // MARK: - Retention Policy Implementation

  /// Checks if there's sufficient free disk space
  private func hasSufficientFreeSpace() -> Bool {
    do {
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let attributes = try FileManager.default.attributesOfFileSystem(forPath: documentsPath.path)
      if let freeSpace = attributes[.systemFreeSize] as? UInt64 {
        let freeSpaceMB = freeSpace / (1024 * 1024)
        return freeSpaceMB >= minFreeSpaceMB
      }
    } catch {
      os_log(
        "Failed to check disk space: %{public}@", log: OSLog.default, type: .error,
        error.localizedDescription)
    }
    return true  // Allow if we can't check
  }

  /// Applies retention policy: removes old reports and enforces max count
  private func applyRetentionPolicy() {
    let reports = getCrashReports()

    // Sort by date (oldest first)
    let sortedReports = reports.sorted { $0.timestamp < $1.timestamp }

    var reportsToDelete: [CrashReport] = []

    // 1. Remove reports older than max age
    let cutoffDate = Date().addingTimeInterval(-Double(maxCrashReportAgeDays) * 24 * 60 * 60)
    let oldReports = sortedReports.filter { $0.timestamp < cutoffDate }
    reportsToDelete.append(contentsOf: oldReports)

    // 2. Enforce max count (keep newest)
    let remainingReports = sortedReports.filter { $0.timestamp >= cutoffDate }
    if remainingReports.count > maxCrashReportCount {
      let excessCount = remainingReports.count - maxCrashReportCount
      let reportsToRemove = remainingReports.prefix(excessCount)
      reportsToDelete.append(contentsOf: reportsToRemove)
    }

    // Delete the identified reports
    for report in reportsToDelete {
      deleteCrashReport(report)
    }

    if !reportsToDelete.isEmpty {
      os_log(
        "Retention policy applied: removed %d crash reports", log: OSLog.default, type: .info,
        reportsToDelete.count)
    }
  }

  /// Deletes a specific crash report file
  private func deleteCrashReport(_ report: CrashReport) {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let crashReportsPath = documentsPath.appendingPathComponent("CrashReports")
    let fileURL = crashReportsPath.appendingPathComponent(
      "crash_\(report.timestamp.timeIntervalSince1970).json")

    do {
      try FileManager.default.removeItem(at: fileURL)
    } catch {
      os_log(
        "Failed to delete old crash report: %{public}@", log: OSLog.default, type: .error,
        error.localizedDescription)
    }
  }

  // MARK: - Public Retention Controls

  /// Returns the current crash report storage statistics
  func getStorageStats() -> CrashReportStorageStats {
    let reports = getCrashReports()
    let totalSize = calculateTotalSize(of: reports)

    return CrashReportStorageStats(
      reportCount: reports.count,
      maxReportCount: maxCrashReportCount,
      oldestReportDate: reports.min { $0.timestamp < $1.timestamp }?.timestamp,
      newestReportDate: reports.max { $0.timestamp < $1.timestamp }?.timestamp,
      totalSizeBytes: totalSize,
      maxAgeDays: maxCrashReportAgeDays
    )
  }

  /// Calculates total size of crash report files
  private func calculateTotalSize(of reports: [CrashReport]) -> UInt64 {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let crashReportsPath = documentsPath.appendingPathComponent("CrashReports")

    var totalSize: UInt64 = 0
    for report in reports {
      let fileURL = crashReportsPath.appendingPathComponent(
        "crash_\(report.timestamp.timeIntervalSince1970).json")
      if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
        let size = attributes[.size] as? UInt64
      {
        totalSize += size
      }
    }
    return totalSize
  }

  func getCrashReports() -> [CrashReport] {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let crashReportsPath = documentsPath.appendingPathComponent("CrashReports")

    guard
      let files = try? FileManager.default.contentsOfDirectory(
        at: crashReportsPath,
        includingPropertiesForKeys: nil)
    else {
      return []
    }

    var reports: [CrashReport] = []
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    for file in files {
      do {
        let data = try Data(contentsOf: file)
        let report = try decoder.decode(CrashReport.self, from: data)
        reports.append(report)
      } catch {
        os_log(
          "Failed to decode crash report from %{public}@: %{public}@", log: OSLog.default,
          type: .error, file.lastPathComponent, error.localizedDescription)
      }
    }

    return reports.sorted { $0.timestamp > $1.timestamp }
  }

  /// Manually applies retention policy (can be called from settings)
  func enforceRetentionPolicy() {
    applyRetentionPolicy()
  }

  func clearCrashReports() {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let crashReportsPath = documentsPath.appendingPathComponent("CrashReports")

    do {
      let files = try FileManager.default.contentsOfDirectory(
        at: crashReportsPath, includingPropertiesForKeys: nil)
      for file in files {
        try FileManager.default.removeItem(at: file)
      }
    } catch {
      os_log(
        "Failed to clear crash reports: %{public}@", log: OSLog.default, type: .error,
        error.localizedDescription)
    }
  }
}

// MARK: - Crash Report Model

struct CrashReport: Codable {
  let error: String
  let context: String
  let timestamp: Date
  let deviceInfo: [String: String]
  let appVersion: String
  let stackTrace: String?

  init(
    error: Error, context: String, timestamp: Date, deviceInfo: [String: String], appVersion: String
  ) {
    self.error = error.localizedDescription
    self.context = context
    self.timestamp = timestamp
    self.deviceInfo = deviceInfo
    self.appVersion = appVersion
    self.stackTrace = Thread.callStackSymbols.joined(separator: "\n")
  }
}

// MARK: - Exception Handlers

private func handleUncaughtException(exception: NSException) {
  let error = NSError(
    domain: "UncaughtException", code: -1,
    userInfo: [
      NSLocalizedDescriptionKey: exception.reason ?? "Unknown exception",
      "exceptionName": exception.name.rawValue,
      "exceptionReason": exception.reason ?? "",
    ])

  CrashReportingManager.shared.reportCrash(error, context: "Uncaught Exception")
}

private func handleSignal(signal: Int32) {
  let error = NSError(
    domain: "Signal", code: Int(signal),
    userInfo: [
      NSLocalizedDescriptionKey: "Application received signal: \(signal)"
    ])

  CrashReportingManager.shared.reportCrash(error, context: "Signal Handler")
}

// MARK: - Storage Statistics

struct CrashReportStorageStats {
  let reportCount: Int
  let maxReportCount: Int
  let oldestReportDate: Date?
  let newestReportDate: Date?
  let totalSizeBytes: UInt64
  let maxAgeDays: Int

  var formattedSize: String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(totalSizeBytes))
  }

  var formattedAgeRange: String {
    guard let oldest = oldestReportDate, let newest = newestReportDate else {
      return "No reports"
    }
    let formatter = RelativeDateTimeFormatter()
    return
      "\(formatter.localizedString(for: oldest, relativeTo: Date())) - \(formatter.localizedString(for: newest, relativeTo: Date()))"
  }

  var isNearCapacity: Bool {
    reportCount >= Int(Double(maxReportCount) * 0.9)
  }
}
