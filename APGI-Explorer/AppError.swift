import Foundation
import Network
import SwiftUI

// MARK: - Enhanced Error Handling Manager

class ErrorHandlingManager: ObservableObject {
    static let shared = ErrorHandlingManager()

    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    @Published var toastMessage: ToastMessage?

    private init() {}

    func handle(_ error: Error, context: String = "") {
        let appError = mapToAppError(error)
        currentError = appError

        // Log the error
        print("Error in \(context): \(error.localizedDescription)")

        // Show appropriate UI feedback
        switch appError.severity {
        case .info, .warning:
            showToast(for: appError)
        case .error, .critical:
            showErrorAlert = true
        }

        // Haptic feedback for errors
        #if os(iOS)
        HapticFeedback.shared.notification(.error)
        #endif

        // Accessibility announcement
        AccessibilityManager.shared.announce("Error: \(appError.localizedDescription)")
    }

    func clearError() {
        currentError = nil
        showErrorAlert = false
        toastMessage = nil
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
            toastMessage = .info(error.localizedDescription)
        case .warning:
            toastMessage = .warning(error.localizedDescription)
        case .error:
            toastMessage = .error(error.localizedDescription)
        case .critical:
            toastMessage = .error(error.localizedDescription)
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
        case .dataLoadingFailed(let error):
            return "Unable to load psychological states data. This may be due to network issues or corrupted data. Details: \(error.localizedDescription)"
        case .stateNotFound(let id):
            return "Psychological state with ID \(id) could not be found in the database. The state may have been removed or the ID is incorrect."
        case .invalidParameters:
            return "Invalid APGI parameters detected. One or more parameters (epsilon, precision, threshold, or somatic bias) are outside the expected range."
        case .networkError(let error):
            return "Network connection error: \(error.localizedDescription). Please check your internet connection and try again."
        case .quizValidationFailed(let result):
            let warnings = result.warnings.isEmpty ? "No specific warnings available" : result.warnings.joined(separator: "; ")
            return "Quiz validation failed with \(result.warnings.count) issue(s). Completion rate: \(Int(result.completionRate * 100))%. Warnings: \(warnings)"
        case .profileGenerationFailed:
            return "Unable to generate APGI profile. This typically occurs when a profile with the same name already exists or required quiz data is missing."
        case .exportFailed(let error):
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
            return "Check your internet connection, restart the app, or try again when the network is stable"
        case .networkError:
            return "Verify your Wi-Fi or cellular connection, disable VPN if enabled, or try a different network"
        case .stateNotFound:
            return "Use the search function to find available states, refresh the state list, or check if the state ID is correct"
        case .invalidParameters:
            return "Ensure all parameter values are within valid ranges (0-100 for most parameters) and try again"
        case .quizValidationFailed(let result):
            if result.completionRate < 0.9 {
                return "Complete all \(30 - Int(result.completionRate * 30)) remaining quiz questions for accurate results"
            } else {
                return "Review your responses for consistency (\(result.warnings.count) warnings detected) and adjust as needed"
            }
        case .profileGenerationFailed:
            return "Choose a unique profile name, ensure the quiz is fully completed, or try restarting the quiz"
        case .exportFailed:
            return "Free up storage space, check file permissions, try a different export format, or restart the app"
        case .offlineMode:
            return "Connect to Wi-Fi or cellular data, or use offline features until connection is restored"
        case .timeout:
            return "Check network speed, move closer to your router, reduce network load, or try again with a better connection"
        case .storageUnavailable:
            return "Free up device storage, restart the app, or restart your device to resolve storage access issues"
        case .corruptedData:
            return "Clear app cache in Settings, restart the app, or contact support if the issue persists"
        case .permissionDenied:
            return "Go to Settings > Privacy & Security > APGI Explorer and grant all required permissions"
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .dataLoadingFailed, .networkError, .offlineMode:
            return .warning
        case .stateNotFound, .invalidParameters, .quizValidationFailed:
            return .info
        case .profileGenerationFailed, .exportFailed, .timeout:
            return .error
        case .storageUnavailable, .corruptedData, .permissionDenied:
            return .critical
        }
    }

    var isRetryable: Bool {
        switch self {
        case .dataLoadingFailed, .networkError, .offlineMode, .timeout, .storageUnavailable:
            return true
        case .stateNotFound, .invalidParameters, .quizValidationFailed, .corruptedData, .permissionDenied:
            return false
        case .profileGenerationFailed, .exportFailed:
            return true
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
        case .info: return "blue"
        case .warning: return "orange"
        case .error: return "red"
        case .critical: return "purple"
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
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.processPendingOperations()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    func scheduleOperation(_ operation: @escaping () async throws -> Void, description: String) {
        let pendingOp = PendingOperation(
            operation: operation,
            description: description,
            timestamp: Date()
        )
        pendingOperations.append(pendingOp)
        hasOfflineOperations = true
    }

    @MainActor
    private func processPendingOperations() async {
        guard networkMonitor.isConnected else { return }

        let operationsToProcess = pendingOperations.filter { $0.retryCount < $0.maxRetries }

        for operation in operationsToProcess {
            do {
                try await operation.operation()
                pendingOperations.removeAll { $0.id == operation.id }
            } catch {
                if let index = pendingOperations.firstIndex(where: { $0.id == operation.id }) {
                    pendingOperations[index].retryCount += 1
                }
            }
        }

        hasOfflineOperations = !pendingOperations.isEmpty
    }
}

// MARK: - Network Monitor

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

import Combine
