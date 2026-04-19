import Combine
import Darwin
import Foundation
import os.log

#if os(iOS)
  import UIKit
#endif

// MARK: - Crash Reporting Manager

class CrashReportingManager: ObservableObject {
  static let shared = CrashReportingManager()

  @Published var isEnabled = false

  private init() {
    self.setupCrashReporting()
    self.loadSettings()
  }

  private func setupCrashReporting() {
    // Set up crash reporting
    NSSetUncaughtExceptionHandler(handleUncaughtException)

    // Set up signal handlers for common crash signals
    Darwin.signal(SIGABRT, handleSignal)
    Darwin.signal(SIGILL, handleSignal)
    Darwin.signal(SIGSEGV, handleSignal)
    Darwin.signal(SIGFPE, handleSignal)
    Darwin.signal(SIGBUS, handleSignal)
    Darwin.signal(SIGPIPE, handleSignal)
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
    } catch {
      os_log(
        "Failed to save crash report: %{public}@", log: OSLog.default, type: .error,
        error.localizedDescription)
    }
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
