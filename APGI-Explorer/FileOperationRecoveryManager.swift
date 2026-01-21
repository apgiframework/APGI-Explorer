import Foundation
import SwiftUI
import Combine

// MARK: - File Operation Recovery Manager

class FileOperationRecoveryManager: ObservableObject {
    static let shared = FileOperationRecoveryManager()

    @Published var pendingRecoveries: [FileOperationRecovery] = []
    @Published var recoveryInProgress = false

    private init() {}

    func handleFileOperationError(_ error: Error, operation: FileOperation) -> FileOperationRecovery {
        let recovery = FileOperationRecovery(
            id: UUID(),
            operation: operation,
            error: error,
            timestamp: Date(),
            retryCount: 0,
            maxRetries: 3,
            suggestedActions: generateRecoveryActions(for: error, operation: operation)
        )

        DispatchQueue.main.async {
            self.pendingRecoveries.append(recovery)
        }

        return recovery
    }

    func attemptRecovery(_ recovery: FileOperationRecovery, action: RecoveryAction) async throws {
        guard recovery.retryCount < recovery.maxRetries else {
            throw FileOperationError.maxRetriesExceeded
        }

        let updatedRecovery = FileOperationRecovery(
            id: recovery.id,
            operation: recovery.operation,
            error: recovery.error,
            timestamp: recovery.timestamp,
            retryCount: recovery.retryCount + 1,
            maxRetries: recovery.maxRetries,
            suggestedActions: recovery.suggestedActions
        )

        DispatchQueue.main.async {
            if let index = self.pendingRecoveries.firstIndex(where: { $0.id == recovery.id }) {
                self.pendingRecoveries[index] = updatedRecovery
            }
            self.recoveryInProgress = true
        }

        do {
            try await performRecoveryAction(action, operation: recovery.operation)

            DispatchQueue.main.async {
                self.pendingRecoveries.removeAll { $0.id == recovery.id }
                self.recoveryInProgress = false
                #if os(iOS)
                HapticFeedback.shared.notification(.success)
                #endif
            }
        } catch {
            DispatchQueue.main.async {
                self.recoveryInProgress = false
                #if os(iOS)
                HapticFeedback.shared.notification(.error)
                #endif
            }
            throw error
        }
    }

    func dismissRecovery(_ recovery: FileOperationRecovery) {
        DispatchQueue.main.async {
            self.pendingRecoveries.removeAll { $0.id == recovery.id }
        }
    }

    private func generateRecoveryActions(for error: Error, operation: FileOperation) -> [RecoveryAction] {
        var actions: [RecoveryAction] = []

        if let nsError = error as NSError? {
            switch nsError.code {
            case NSFileReadNoSuchFileError, NSFileReadUnknownError:
                actions.append(.retry)
                actions.append(.chooseDifferentLocation)

            case NSFileWriteFileExistsError:
                actions.append(.overwrite)
                actions.append(.rename)
                actions.append(.chooseDifferentLocation)

            case NSFileWriteNoPermissionError:
                actions.append(.changePermissions)
                actions.append(.chooseDifferentLocation)

            case NSFileWriteOutOfSpaceError:
                actions.append(.freeSpace)
                actions.append(.chooseDifferentLocation)

            default:
                actions.append(.retry)
                actions.append(.contactSupport)
            }
        } else if let appError = error as? AppError {
            switch appError {
            case .exportFailed:
                actions.append(.retry)
                actions.append(.chooseDifferentFormat)
                actions.append(.freeSpace)

            case .storageUnavailable:
                actions.append(.retry)
                actions.append(.restartApp)

            case .corruptedData:
                actions.append(.useBackup)
                actions.append(.contactSupport)

            default:
                actions.append(.retry)
                actions.append(.contactSupport)
            }
        }

        return actions
    }

    private func performRecoveryAction(_ action: RecoveryAction, operation: FileOperation) async throws {
        switch action {
        case .retry:
            try await operation.execute()

        case .overwrite:
            if var fileOperation = operation as? FileExportOperation {
                fileOperation.overwrite = true
                try await fileOperation.execute()
            }

        case .rename:
            if var fileOperation = operation as? FileExportOperation {
                fileOperation.customName = generateUniqueName(fileOperation.suggestedName)
                try await fileOperation.execute()
            }

        case .chooseDifferentLocation:
            // This would need to be implemented with a file picker
            throw FileOperationError.notImplemented

        case .changePermissions:
            // This would need to be implemented with permission handling
            throw FileOperationError.notImplemented

        case .freeSpace:
            try await freeDiskSpace()
            try await operation.execute()

        case .chooseDifferentFormat:
            // This would need to be implemented with format selection
            throw FileOperationError.notImplemented

        case .useBackup:
            try await restoreFromBackup()

        case .restartApp:
            // This would need to be implemented with app restart
            throw FileOperationError.notImplemented

        case .contactSupport:
            throw FileOperationError.contactSupport
        }
    }

    private func generateUniqueName(_ baseName: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(baseName)_\(timestamp)"
    }

    private func freeDiskSpace() async throws {
        // Implementation would clear cache and temporary files
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }

    private func restoreFromBackup() async throws {
        // Implementation would restore from latest backup
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
}

// MARK: - File Operation Models

struct FileOperationRecovery: Identifiable {
    let id: UUID
    let operation: FileOperation
    let error: Error
    let timestamp: Date
    let retryCount: Int
    let maxRetries: Int
    let suggestedActions: [RecoveryAction]

    var canRetry: Bool {
        retryCount < maxRetries
    }

    var severity: RecoverySeverity {
        switch retryCount {
        case 0:
            return .low
        case 1:
            return .medium
        default:
            return .high
        }
    }
}

protocol FileOperation {
    var description: String { get }
    func execute() async throws
}

struct FileExportOperation: FileOperation {
    let profile: QuizProfile
    let destination: URL
    let format: ExportFormat
    var overwrite: Bool = false
    var customName: String?

    var description: String {
        "Export \(profile.name) as \(format.rawValue)"
    }

    var suggestedName: String {
        customName ?? "\(profile.name).\(format.rawValue)"
    }

    func execute() async throws {
        _ = try FileStorageManager.shared.exportProfile(profile, to: destination)
    }
}

enum RecoveryAction: CaseIterable {
    case retry
    case overwrite
    case rename
    case chooseDifferentLocation
    case changePermissions
    case freeSpace
    case chooseDifferentFormat
    case useBackup
    case restartApp
    case contactSupport

    var title: String {
        switch self {
        case .retry: return "Try Again"
        case .overwrite: return "Overwrite Existing File"
        case .rename: return "Rename File"
        case .chooseDifferentLocation: return "Choose Different Location"
        case .changePermissions: return "Change Permissions"
        case .freeSpace: return "Free Up Space"
        case .chooseDifferentFormat: return "Try Different Format"
        case .useBackup: return "Use Backup"
        case .restartApp: return "Restart App"
        case .contactSupport: return "Contact Support"
        }
    }

    var description: String {
        switch self {
        case .retry: return "Attempt the operation again"
        case .overwrite: return "Replace the existing file"
        case .rename: return "Save with a different name"
        case .chooseDifferentLocation: return "Save to a different location"
        case .changePermissions: return "Grant necessary permissions"
        case .freeSpace: return "Clear up disk space"
        case .chooseDifferentFormat: return "Export in a different format"
        case .useBackup: return "Restore from a previous backup"
        case .restartApp: return "Restart the application"
        case .contactSupport: return "Get help from our support team"
        }
    }

    var icon: String {
        switch self {
        case .retry: return "arrow.clockwise"
        case .overwrite: return "arrow.down.doc.fill"
        case .rename: return "pencil"
        case .chooseDifferentLocation: return "folder"
        case .changePermissions: return "lock.shield"
        case .freeSpace: return "trash"
        case .chooseDifferentFormat: return "doc.badge.gearshape"
        case .useBackup: return "clock.arrow.circlepath"
        case .restartApp: return "arrow.clockwise.circle"
        case .contactSupport: return "questionmark.circle"
        }
    }
}

enum RecoverySeverity {
    case low
    case medium
    case high

    var color: Color {
        switch self {
        case .low: return .orange
        case .medium: return .red
        case .high: return .purple
        }
    }

    var icon: String {
        switch self {
        case .low: return "exclamationmark.triangle.fill"
        case .medium: return "xmark.circle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }
}

enum FileOperationError: LocalizedError {
    case maxRetriesExceeded
    case notImplemented
    case contactSupport

    var errorDescription: String? {
        switch self {
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .notImplemented:
            return "This recovery option is not yet available"
        case .contactSupport:
            return "Please contact support for assistance"
        }
    }
}

// MARK: - File Operation Recovery View

struct FileOperationRecoveryView: View {
    @ObservedObject private var recoveryManager = FileOperationRecoveryManager.shared
    @State private var selectedRecovery: FileOperationRecovery?

    var body: some View {
        VStack(spacing: 0) {
            if !recoveryManager.pendingRecoveries.isEmpty {
                List(recoveryManager.pendingRecoveries) { recovery in
                    RecoveryRow(recovery: recovery) {
                        selectedRecovery = recovery
                    }
                }
                .listStyle(.inset)
            }

            if selectedRecovery != nil {
                RecoveryActionsSheet(
                    recovery: selectedRecovery!,
                    onDismiss: { selectedRecovery = nil }
                )
            }
        }
    }
}

struct RecoveryRow: View {
    let recovery: FileOperationRecovery
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recovery.severity.icon)
                .foregroundColor(recovery.severity.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(recovery.operation.description)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(recovery.error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Text("Attempt \(recovery.retryCount + 1) of \(recovery.maxRetries)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(recovery.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onSelect) {
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct RecoveryActionsSheet: View {
    let recovery: FileOperationRecovery
    let onDismiss: () -> Void
    @ObservedObject private var recoveryManager = FileOperationRecoveryManager.shared
    @State private var performingAction = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Error Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Operation Failed")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(recovery.operation.description)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(recovery.error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                // Recovery Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recovery Options")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ForEach(recovery.suggestedActions, id: \.self) { action in
                        RecoveryActionButton(
                            action: action,
                            isDisabled: performingAction || (!recovery.canRetry && action == .retry)
                        ) {
                            performAction(action)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("File Recovery")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        onDismiss()
                    }
                }
            }
            #elseif os(macOS)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Dismiss") {
                        onDismiss()
                    }
                }
            }
            #endif
        }
        .sheet(isPresented: $performingAction) {
            ProgressView("Attempting recovery...")
                .padding()
        }
    }

    private func performAction(_ action: RecoveryAction) {
        performingAction = true

        Task {
            do {
                try await recoveryManager.attemptRecovery(recovery, action: action)
                await MainActor.run {
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    ErrorHandlingManager.shared.handle(error, context: "File Recovery")
                    performingAction = false
                }
            }
        }
    }
}

struct RecoveryActionButton: View {
    let action: RecoveryAction
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(action.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}
