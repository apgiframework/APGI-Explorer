import SwiftUI
#if os(iOS)
import UIKit
#endif

#if os(iOS)
typealias NotificationFeedbackType = UINotificationFeedbackGenerator.FeedbackType
#else
typealias NotificationFeedbackType = String
#endif

// MARK: - Haptic Feedback Manager

class HapticFeedback {
    static let shared = HapticFeedback()

    private init() {}

    func lightImpact() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }

    func mediumImpact() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }

    func heavyImpact() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        #endif
    }

    func selectionChanged() {
        #if os(iOS)
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
        #endif
    }

    func notification(_ type: NotificationFeedbackType) {
        #if os(iOS)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
        #endif
    }
}

// MARK: - Enhanced Error View

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .textSelection(.enabled)

            Spacer()
        }
    }
}

struct ErrorView: View {
    let error: AppError
    let retry: () -> Void
    let dismiss: (() -> Void)?

    @State private var showingDetails = false
    @State private var isRetrying = false
    @State private var pulseAnimation = false

    init(error: AppError, retry: @escaping () -> Void, dismiss: (() -> Void)? = nil) {
        self.error = error
        self.retry = retry
        self.dismiss = dismiss
    }

    var body: some View {
        VStack(spacing: LayoutConstants.mediumSpacing) {
            // Error Icon with Severity Color and Animation
            Image(systemName: iconForSeverity)
                .font(.system(size: LayoutConstants.errorIconFontSize))
                .foregroundColor(colorForSeverity)
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .accessibilityLabel("Error icon: \(String(describing: error.severity))")
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                }

            // Error Title with better accessibility
            Text(error.localizedDescription)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityLabel("Error: \(error.localizedDescription)")
                .accessibilityAddTraits(.isStaticText)

            // Recovery Suggestion with enhanced visibility
            if let recovery = error.recoverySuggestion {
                VStack(alignment: .leading, spacing: LayoutConstants.tinySpacing) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Suggested Solution:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }

                    Text(recovery)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 20)
                }
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Recovery suggestion: \(recovery)")
            }

            // Action Buttons with enhanced accessibility
            VStack(spacing: LayoutConstants.smallSpacing) {
                if error.isRetryable {
                    Button(action: {
                        isRetrying = true
                        HapticFeedback.shared.lightImpact()
                        retry()
                        DispatchQueue.main.asyncAfter(deadline: .now() + ColorConstants.retryDelay) {
                            isRetrying = false
                        }
                    }, label: {
                        HStack {
                            if isRetrying {
                                LoadingIndicator(size: .small)
                                Text("Retrying...")
                                    .accessibilityHidden(true)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                        }
                    })
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isRetrying)
                    .accessibilityLabel(isRetrying ? "Retrying operation" : "Retry operation")
                    .accessibilityHint(error.isRetryable ? "Attempt the operation again" : "")
                }

                if let dismiss = dismiss {
                    Button("Dismiss", action: {
                        HapticFeedback.shared.lightImpact()
                        dismiss()
                    })
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityLabel("Dismiss error")
                        .accessibilityHint("Close this error message")
                }

                Button("Show Details") {
                    HapticFeedback.shared.selectionChanged()
                    showingDetails.toggle()
                }
                .buttonStyle(SecondaryButtonStyle())
                .foregroundColor(colorForSeverity)
                .accessibilityLabel(showingDetails ? "Hide error details" : "Show error details")
                .accessibilityHint("View technical information about this error")
            }

            // Error Details (Expandable) with enhanced accessibility
            if showingDetails {
                VStack(alignment: .leading, spacing: LayoutConstants.tinySpacing) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(colorForSeverity)
                            .font(.caption)
                        Text("Technical Details:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(colorForSeverity)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        DetailRow(label: "Error Type", value: String(describing: type(of: error)))
                        DetailRow(label: "Severity", value: String(describing: error.severity))
                        DetailRow(label: "Retryable", value: error.isRetryable ? "Yes" : "No")
                        DetailRow(label: "Error Code", value: "\(type(of: error))")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                        .fill(AccessibleColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                                .stroke(colorForSeverity.opacity(0.3), lineWidth: 1)
                        )
                )
                .cornerRadius(LayoutConstants.cardCornerRadius)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 1.05))
                ))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Technical error details")
                .accessibilityHint("Technical information for debugging purposes")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: ColorConstants.animationDuration), value: showingDetails)
        .onAppear {
            // Announce error for accessibility
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AccessibilityManager.shared.announce("Error occurred: \(error.localizedDescription)")
            }
        }
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
        VStack(spacing: LayoutConstants.mediumSpacing) {
            Image(systemName: "wifi.slash")
                .font(.system(size: LayoutConstants.offlineIconFontSize))
                .foregroundColor(.orange)

            Text("Offline Mode")
                .font(.headline)

            Text("You're currently offline. Operations will resume when connection is restored.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !errorRecoveryManager.pendingOperations.isEmpty {
                VStack(alignment: .leading, spacing: LayoutConstants.tinySpacing) {
                    Text("Pending Operations (\(errorRecoveryManager.pendingOperations.count)):")
                        .font(.caption)
                        .fontWeight(.semibold)

                    ForEach(errorRecoveryManager.pendingOperations) { operation in
                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: DataConstants.circleSize, height: DataConstants.circleSize)
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
                .background(AppColors.adaptiveGray3.opacity(ColorConstants.cardBackgroundOpacity))
                .cornerRadius(LayoutConstants.cardCornerRadius)
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
                    LoadingIndicator(message: message, size: .large)

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
                    .buttonStyle(DestructiveButtonStyle())
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
