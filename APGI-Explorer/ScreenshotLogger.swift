import Foundation
import os.log

// MARK: - Logger

class Logger {
    private let enabled: Bool
    private let logFile: URL?
    private let osLog: OSLog

    init(enabled: Bool = true, logFile: URL? = nil) {
        self.enabled = enabled
        self.logFile = logFile
        self.osLog = OSLog(subsystem: "com.apgi.explorer", category: "ScreenshotAutomation")

        if enabled, logFile != nil {
            self.createLogFileIfNeeded()
        }
    }

    func log(_ message: String) {
        guard self.enabled else { return }

        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        let formattedMessage = "[\(timestamp)] \(message)"

        // Log to console
        #if DEBUG
            print(formattedMessage)
        #endif

        // Log to OS Log
        os_log("%{public}@", log: self.osLog, type: .info, message)

        // Log to file if configured
        if let logFile {
            self.writeToFile(formattedMessage, to: logFile)
        }
    }

    func logError(_ message: String) {
        guard self.enabled else { return }

        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        let formattedMessage = "[\(timestamp)] ❌ ERROR: \(message)"

        // Log to console
        #if DEBUG
            print(formattedMessage)
        #endif

        // Log to OS Log
        os_log("%{public}@", log: self.osLog, type: .error, message)

        // Log to file if configured
        if let logFile {
            self.writeToFile(formattedMessage, to: logFile)
        }
    }

    func logWarning(_ message: String) {
        guard self.enabled else { return }

        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        let formattedMessage = "[\(timestamp)] ⚠️ WARNING: \(message)"

        // Log to console
        #if DEBUG
            print(formattedMessage)
        #endif

        // Log to OS Log
        os_log("%{public}@", log: self.osLog, type: .default, message)

        // Log to file if configured
        if let logFile {
            self.writeToFile(formattedMessage, to: logFile)
        }
    }

    func logSuccess(_ message: String) {
        guard self.enabled else { return }

        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        let formattedMessage = "[\(timestamp)] ✅ \(message)"

        // Log to console
        #if DEBUG
            print(formattedMessage)
        #endif

        // Log to OS Log
        os_log("%{public}@", log: self.osLog, type: .info, message)

        // Log to file if configured
        if let logFile {
            self.writeToFile(formattedMessage, to: logFile)
        }
    }

    private func createLogFileIfNeeded() {
        guard let logFile else { return }

        let directory = logFile.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                #if DEBUG
                    print("Failed to create log directory: \(error)")
                #endif
            }
        }

        if !FileManager.default.fileExists(atPath: logFile.path) {
            do {
                try "".write(to: logFile, atomically: true, encoding: .utf8)
            } catch {
                #if DEBUG
                    print("Failed to create log file: \(error)")
                #endif
            }
        }
    }

    private func writeToFile(_ message: String, to file: URL) {
        do {
            let fileHandle = try FileHandle(forWritingTo: file)
            defer { fileHandle.closeFile() }

            fileHandle.seekToEndOfFile()
            guard let data = (message + "\n").data(using: .utf8) else { return }
            fileHandle.write(data)
        } catch {
            #if DEBUG
                print("Failed to write to log file: \(error)")
            #endif
        }
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
