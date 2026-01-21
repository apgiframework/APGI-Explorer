import SwiftUI
import Combine

// MARK: - Settings Validation Manager

class SettingsValidationManager: ObservableObject {
    @Published var validationErrors: [ValidationError] = []
    @Published var isValid = true

    func validateDefaultProfileName(_ name: String) -> ValidationError? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return ValidationError(
                field: "Default Profile Name",
                message: "Profile name cannot be empty",
                severity: .error
            )
        }

        if trimmedName.count < 2 {
            return ValidationError(
                field: "Default Profile Name",
                message: "Profile name must be at least 2 characters long",
                severity: .warning
            )
        }

        if trimmedName.count > 50 {
            return ValidationError(
                field: "Default Profile Name",
                message: "Profile name cannot exceed 50 characters",
                severity: .error
            )
        }

        // Check for invalid characters
        let invalidChars = CharacterSet(charactersIn: "/:*?\"<>|")
        if trimmedName.rangeOfCharacter(from: invalidChars) != nil {
            return ValidationError(
                field: "Default Profile Name",
                message: "Profile name contains invalid characters",
                severity: .error
            )
        }

        return nil
    }

    func validateDataRetention(_ days: Int) -> ValidationError? {
        if days < 1 {
            return ValidationError(
                field: "Data Retention",
                message: "Data retention period must be at least 1 day",
                severity: .error
            )
        }

        if days > 3650 && days != 9999 { // 10 years max, except for "Forever"
            return ValidationError(
                field: "Data Retention",
                message: "Data retention period cannot exceed 10 years",
                severity: .warning
            )
        }

        return nil
    }

    func validateRefreshInterval(_ interval: Double) -> ValidationError? {
        if interval < 30 { // 30 seconds minimum
            return ValidationError(
                field: "Refresh Interval",
                message: "Refresh interval must be at least 30 seconds",
                severity: .error
            )
        }

        if interval > 86400 { // 24 hours maximum
            return ValidationError(
                field: "Refresh Interval",
                message: "Refresh interval cannot exceed 24 hours",
                severity: .warning
            )
        }

        return nil
    }

    func validateMaxBackupFiles(_ count: Int) -> ValidationError? {
        if count < 1 {
            return ValidationError(
                field: "Max Backup Files",
                message: "Must keep at least 1 backup file",
                severity: .error
            )
        }

        if count > 50 {
            return ValidationError(
                field: "Max Backup Files",
                message: "Keeping more than 50 backup files may use excessive storage",
                severity: .warning
            )
        }

        return nil
    }

    func validateAllSettings(
        profileName: String,
        dataRetention: Int,
        refreshInterval: Double,
        maxBackupFiles: Int
    ) {
        var errors: [ValidationError] = []

        if let error = validateDefaultProfileName(profileName) {
            errors.append(error)
        }

        if let error = validateDataRetention(dataRetention) {
            errors.append(error)
        }

        if let error = validateRefreshInterval(refreshInterval) {
            errors.append(error)
        }

        if let error = validateMaxBackupFiles(maxBackupFiles) {
            errors.append(error)
        }

        DispatchQueue.main.async {
            self.validationErrors = errors
            self.isValid = errors.filter { $0.severity == .error }.isEmpty
        }
    }
}

// MARK: - Validation Error Model

struct ValidationError: Identifiable, Equatable {
    let id = UUID()
    let field: String
    let message: String
    let severity: ValidationSeverity

    enum ValidationSeverity {
        case warning
        case error

        var color: Color {
            switch self {
            case .warning: return .orange
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - Validated TextField

struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    let validator: (String) -> ValidationError?
    @State private var validationError: ValidationError?
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let error = validationError {
                    Image(systemName: error.severity.icon)
                        .foregroundColor(error.severity.color)
                        .font(.caption)
                        .help(error.message)
                }

                Spacer()
            }

            TextField(title, text: $text)
                .textFieldStyle(.roundedBorder)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(validationError?.severity.color ?? Color.clear, lineWidth: 1)
                )
                .onAppear {
                    validate()
                }
                .onChange(of: text) { _, _ in
                    validate()
                }

            if let error = validationError, !isEditing {
                Text(error.message)
                    .font(.caption)
                    .foregroundColor(error.severity.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func validate() {
        validationError = validator(text)
    }
}

// MARK: - Validated Picker

struct ValidatedPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [(T, String)]
    let validator: (T) -> ValidationError?
    @State private var validationError: ValidationError?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let error = validationError {
                    Image(systemName: error.severity.icon)
                        .foregroundColor(error.severity.color)
                        .font(.caption)
                        .help(error.message)
                }

                Spacer()
            }

            Picker(title, selection: $selection) {
                ForEach(options, id: \.0) { option in
                    Text(option.1).tag(option.0)
                }
            }
            .pickerStyle(.menu)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(validationError?.severity.color ?? Color.clear, lineWidth: 1)
            )
            .onAppear {
                validate()
            }
            .onChange(of: selection) { _, _ in
                validate()
                HapticFeedback.shared.selectionChanged()
            }

            if let error = validationError {
                Text(error.message)
                    .font(.caption)
                    .foregroundColor(error.severity.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func validate() {
        validationError = validator(selection)
    }
}

// MARK: - Settings Validation Feedback View

struct SettingsValidationFeedback: View {
    let errors: [ValidationError]

    var body: some View {
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: errors.contains(where: { $0.severity == .error }) ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(errors.contains(where: { $0.severity == .error }) ? .red : .orange)

                    Text("Settings Validation")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                ForEach(errors) { error in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: error.severity.icon)
                            .foregroundColor(error.severity.color)
                            .font(.caption)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(error.field)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text(error.message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(errors.contains(where: { $0.severity == .error }) ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(errors.contains(where: { $0.severity == .error }) ? Color.red.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}
