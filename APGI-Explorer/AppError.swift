import Foundation
import Network

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
            return "Failed to load data: \(error.localizedDescription)"
        case .stateNotFound(let id):
            return "State with ID \(id) not found"
        case .invalidParameters:
            return "Invalid APGI parameters provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .quizValidationFailed(let result):
            return "Quiz validation failed: \(result.warnings.first ?? "Unknown validation error")"
        case .profileGenerationFailed:
            return "Failed to generate APGI profile or profile name already exists"
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        case .offlineMode:
            return "No internet connection available"
        case .timeout:
            return "Operation timed out. Please try again"
        case .storageUnavailable:
            return "Storage is currently unavailable"
        case .corruptedData:
            return "Data appears to be corrupted and cannot be processed"
        case .permissionDenied:
            return "Permission denied. Please check your settings"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataLoadingFailed, .networkError:
            return "Please check your connection and try again"
        case .stateNotFound:
            return "Try searching for a different state"
        case .invalidParameters:
            return "Please adjust your parameters and try again"
        case .quizValidationFailed(let result):
            if result.completionRate < 0.9 {
                return "Please complete all quiz questions for accurate results"
            } else {
                return "Please review your responses and try again"
            }
        case .profileGenerationFailed:
            return "Please choose a different profile name or complete the quiz again"
        case .exportFailed:
            return "Please check your storage space and try again"
        case .offlineMode:
            return "Connect to the internet or try again later when online"
        case .timeout:
            return "Check your connection and try the operation again"
        case .storageUnavailable:
            return "Free up storage space or restart the app"
        case .corruptedData:
            return "Try clearing the app cache or contact support"
        case .permissionDenied:
            return "Grant necessary permissions in Settings"
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
