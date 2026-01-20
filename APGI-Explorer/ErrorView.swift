import SwiftUI

// MARK: - Enhanced Error View

struct ErrorView: View {
    let error: AppError
    let retry: () -> Void
    let dismiss: (() -> Void)?
    
    @State private var showingDetails = false
    @State private var isRetrying = false
    
    init(error: AppError, retry: @escaping () -> Void, dismiss: (() -> Void)? = nil) {
        self.error = error
        self.retry = retry
        self.dismiss = dismiss
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon with Severity Color
            Image(systemName: iconForSeverity)
                .font(.system(size: 50))
                .foregroundColor(colorForSeverity)
            
            // Error Title
            Text(error.localizedDescription)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Recovery Suggestion
            if let recovery = error.recoverySuggestion {
                Text(recovery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if error.isRetryable {
                    Button(action: {
                        isRetrying = true
                        retry()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isRetrying = false
                        }
                    }) {
                        HStack {
                            if isRetrying {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isRetrying ? "Retrying..." : "Retry")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRetrying)
                }
                
                if let dismiss = dismiss {
                    Button("Dismiss", action: dismiss)
                        .buttonStyle(.bordered)
                }
                
                Button("Show Details") {
                    showingDetails.toggle()
                }
                .buttonStyle(.bordered)
                .foregroundColor(colorForSeverity)
            }
            
            // Error Details (Expandable)
            if showingDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error Details:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("Type: \(String(describing: type(of: error)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Severity: \(String(describing: error.severity))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Retryable: \(error.isRetryable ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.3), value: showingDetails)
    }
    
    private var iconForSeverity: String {
        switch error.severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        }
    }
    
    private var colorForSeverity: Color {
        switch error.severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - Offline Operations View

struct OfflineOperationsView: View {
    @ObservedObject var errorRecoveryManager: ErrorRecoveryManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Offline Mode")
                .font(.headline)
            
            Text("You're currently offline. Operations will resume when connection is restored.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if !errorRecoveryManager.pendingOperations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pending Operations (\(errorRecoveryManager.pendingOperations.count)):")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(errorRecoveryManager.pendingOperations) { operation in
                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                            Text(operation.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if operation.retryCount > 0 {
                                Text("Retry \(operation.retryCount)/\(operation.maxRetries)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Long Running Operation View

struct LongRunningOperationView: View {
    let message: String
    let progress: Double?
    let cancel: (() -> Void)?
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            if let progress = progress {
                ProgressRingView(progress: progress, message: message)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.blue)
                    
                    Text(message)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Time elapsed: \(formatTime(elapsedTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let cancel = cancel {
                Button("Cancel", action: cancel)
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorView(error: .networkError(URLError(.notConnectedToInternet))) {
                print("Retry tapped")
            }
            .previewDisplayName("Network Error")
            
            ErrorView(error: .invalidParameters) {
                print("Retry tapped")
            }
            .previewDisplayName("Invalid Parameters")
            
            ErrorView(error: .offlineMode) {
                print("Retry tapped")
            }
            .previewDisplayName("Offline Mode")
            
            LongRunningOperationView(
                message: "Processing your data...",
                progress: 0.75,
                cancel: { print("Cancelled") }
            )
            .previewDisplayName("Long Running Operation")
        }
    }
}
