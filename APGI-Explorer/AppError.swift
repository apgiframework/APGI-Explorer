import Foundation
import Network
import os.log
import SwiftUI

// MARK: - Enhanced Error Handling Manager

class ErrorHandlingManager: ObservableObject {
    static let shared = ErrorHandlingManager()

    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    @Published var toastMessage: ToastMessage?

    private init() {
    }

    func handle(_ error: Error, context: String = "") {
        let appError = self.mapToAppError(error)
        self.currentError = appError

        // Log the error
        os_log("Error in %{public}@: %{public}@", log: OSLog.default, type: .error, context, error.localizedDescription)

        // Show appropriate UI feedback
        switch appError.severity {
        case .info, .warning:
            self.showToast(for: appError)
        case .error, .critical:
            self.showErrorAlert = true
        }

        // Haptic feedback for errors
        #if os(iOS)
            HapticFeedback.shared.notification(.error)
        #endif

        // Accessibility announcement
        AccessibilityManager.shared.announce("Error: \(appError.localizedDescription)")
    }

    func clearError() {
        self.currentError = nil
        self.showErrorAlert = false
        self.toastMessage = nil
    }

    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        // Map common system errors to AppError types
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .offlineMode
            case .timedOut:
                return .timeout
            default:
                return .networkError(urlError)
            }
        }

        return .dataLoadingFailed(underlying: error)
    }

    private func showToast(for error: AppError) {
        switch error.severity {
        case .info:
            self.toastMessage = .info(error.localizedDescription)
        case .warning:
            self.toastMessage = .warning(error.localizedDescription)
        case .error:
            self.toastMessage = .error(error.localizedDescription)
        case .critical:
            self.toastMessage = .error(error.localizedDescription)
        }
    }
}

// MARK: - App Error Types

enum AppError: LocalizedError {
    case dataLoadingFailed(underlying: Error)
    case stateNotFound(id: Int)
    case invalidParameters
    case networkError(Error)
    case quizValidationFailed(ValidationResult)
    case profileGenerationFailed
    case exportFailed(underlying: Error)
    case offlineMode
    case timeout
    case storageUnavailable
    case corruptedData
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case let .dataLoadingFailed(error):
            return "Unable to load psychological states data. This may be due to network issues or corrupted data. Details: \(error.localizedDescription)"
        case let .stateNotFound(id):
            return "Psychological state with ID \(id) could not be found in the database. The state may have been removed or the ID is incorrect."
        case .invalidParameters:
            return "Invalid APGI parameters detected. One or more parameters (epsilon, precision, threshold, or somatic bias) are outside the expected range."
        case let .networkError(error):
            return "Network connection error: \(error.localizedDescription). Please check your internet connection and try again."
        case let .quizValidationFailed(result):
            let warnings = result.warnings.isEmpty ? "No specific warnings available" : result.warnings.joined(separator: "; ")
            return "Quiz validation failed with \(result.warnings.count) issue(s). Completion rate: \(Int(result.completionRate * 100))%. Warnings: \(warnings)"
        case .profileGenerationFailed:
            return "Unable to generate APGI profile. This typically occurs when a profile with the same name already exists or required quiz data is missing."
        case let .exportFailed(error):
            return "Export operation failed: \(error.localizedDescription). This could be due to insufficient storage space, file permission issues, or data format problems."
        case .offlineMode:
            return "No internet connection detected. Some features require network access to function properly."
        case .timeout:
            return "Operation timed out after waiting too long for a response. This may be due to slow network connectivity or server issues."
        case .storageUnavailable:
            return "Device storage is currently unavailable or full. The app cannot save or load data at this time."
        case .corruptedData:
            return "Data corruption detected. The application data appears to be damaged and cannot be processed. This may require data restoration."
        case .permissionDenied:
            return "Required permissions have been denied. The app needs access to storage, network, or other system resources to function properly."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .dataLoadingFailed:
            "Check your internet connection, restart the app, or try again when the network is stable"
        case .networkError:
            "Verify your Wi-Fi or cellular connection, disable VPN if enabled, or try a different network"
        case .stateNotFound:
            "Use the search function to find available states, refresh the state list, or check if the state ID is correct"
        case .invalidParameters:
            "Ensure all parameter values are within valid ranges (0-100 for most parameters) and try again"
        case let .quizValidationFailed(result):
            if result.completionRate < 0.9 {
                "Complete all \(30 - Int(result.completionRate * 30)) remaining quiz questions for accurate results"
            } else {
                "Review your responses for consistency (\(result.warnings.count) warnings detected) and adjust as needed"
            }
        case .profileGenerationFailed:
            "Choose a unique profile name, ensure the quiz is fully completed, or try restarting the quiz"
        case .exportFailed:
            "Free up storage space, check file permissions, try a different export format, or restart the app"
        case .offlineMode:
            "Connect to Wi-Fi or cellular data, or use offline features until connection is restored"
        case .timeout:
            "Check network speed, move closer to your router, reduce network load, or try again with a better connection"
        case .storageUnavailable:
            "Free up device storage, restart the app, or restart your device to resolve storage access issues"
        case .corruptedData:
            "Clear app cache in Settings, restart the app, or contact support if the issue persists"
        case .permissionDenied:
            "Go to Settings > Privacy & Security > APGI Explorer and grant all required permissions"
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .dataLoadingFailed, .networkError, .offlineMode:
            .warning
        case .stateNotFound, .invalidParameters, .quizValidationFailed:
            .info
        case .profileGenerationFailed, .exportFailed, .timeout:
            .error
        case .storageUnavailable, .corruptedData, .permissionDenied:
            .critical
        }
    }

    var isRetryable: Bool {
        switch self {
        case .dataLoadingFailed, .networkError, .offlineMode, .timeout, .storageUnavailable:
            true
        case .stateNotFound, .invalidParameters, .quizValidationFailed, .corruptedData, .permissionDenied:
            false
        case .profileGenerationFailed, .exportFailed:
            true
        }
    }
}

// MARK: - Error Severity

enum ErrorSeverity {
    case info
    case warning
    case error
    case critical

    var color: String {
        switch self {
        case .info: "blue"
        case .warning: "orange"
        case .error: "red"
        case .critical: "purple"
        }
    }
}

// MARK: - Error Recovery Manager

class ErrorRecoveryManager: ObservableObject {
    @Published var pendingOperations: [PendingOperation] = []
    @Published var hasOfflineOperations = false

    private let networkMonitor = NetworkMonitor()

    struct PendingOperation: Identifiable {
        let id = UUID()
        let operation: () async throws -> Void
        let description: String
        let timestamp: Date
        var retryCount: Int = 0
        let maxRetries: Int = 3
    }

    init() {
        self.networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.processPendingOperations()
                    }
                }
            }
            .store(in: &self.cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    func scheduleOperation(_ operation: @escaping () async throws -> Void, description: String) {
        let pendingOp = PendingOperation(
            operation: operation,
            description: description,
            timestamp: Date()
        )
        self.pendingOperations.append(pendingOp)
        self.hasOfflineOperations = true
    }

    @MainActor
    private func processPendingOperations() async {
        guard self.networkMonitor.isConnected else { return }

        let operationsToProcess = self.pendingOperations.filter { $0.retryCount < $0.maxRetries }

        for operation in operationsToProcess {
            do {
                try await operation.operation()
                self.pendingOperations.removeAll { $0.id == operation.id }
            } catch {
                if let index = pendingOperations.firstIndex(where: { $0.id == operation.id }) {
                    self.pendingOperations[index].retryCount += 1
                }
            }
        }

        self.hasOfflineOperations = !self.pendingOperations.isEmpty
    }
}

// MARK: - Network Monitor

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        self.monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        self.monitor.start(queue: self.queue)
    }

    deinit {
        monitor.cancel()
    }
}

import Combine
