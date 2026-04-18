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

  private init() {
  }

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
      Text(self.label + ":")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
        .frame(width: 80, alignment: .leading)

      Text(self.value)
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
      Image(systemName: self.iconForSeverity)
        .font(.system(size: LayoutConstants.errorIconFontSize))
        .foregroundColor(self.colorForSeverity)
        .scaleEffect(self.pulseAnimation ? 1.1 : 1.0)
        .accessibilityLabel("Error icon: \(String(describing: self.error.severity))")
        .onAppear {
          withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            self.pulseAnimation = true
          }
        }

      // Error Title with better accessibility
      Text(self.error.localizedDescription)
        .font(.headline)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
        .accessibilityLabel("Error: \(self.error.localizedDescription)")
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
        if self.error.isRetryable {
          Button(
            action: {
              self.isRetrying = true
              HapticFeedback.shared.lightImpact()
              self.retry()
              DispatchQueue.main.asyncAfter(deadline: .now() + ColorConstants.retryDelay) {
                self.isRetrying = false
              }
            },
            label: {
              HStack {
                if self.isRetrying {
                  LoadingIndicator(size: .small)
                  Text("Retrying...")
                    .accessibilityHidden(true)
                } else {
                  Image(systemName: "arrow.clockwise")
                  Text("Retry")
                }
              }
            }
          )
          .buttonStyle(PrimaryButtonStyle())
          .disabled(self.isRetrying)
          .accessibilityLabel(self.isRetrying ? "Retrying operation" : "Retry operation")
          .accessibilityHint(self.error.isRetryable ? "Attempt the operation again" : "")
        }

        if let dismiss {
          Button(
            "Dismiss",
            action: {
              HapticFeedback.shared.lightImpact()
              dismiss()
            }
          )
          .buttonStyle(SecondaryButtonStyle())
          .accessibilityLabel("Dismiss error")
          .accessibilityHint("Close this error message")
        }

        Button("Show Details") {
          HapticFeedback.shared.selectionChanged()
          self.showingDetails.toggle()
        }
        .buttonStyle(SecondaryButtonStyle())
        .foregroundColor(self.colorForSeverity)
        .accessibilityLabel(self.showingDetails ? "Hide error details" : "Show error details")
        .accessibilityHint("View technical information about this error")
      }

      // Error Details (Expandable) with enhanced accessibility
      if self.showingDetails {
        VStack(alignment: .leading, spacing: LayoutConstants.tinySpacing) {
          HStack {
            Image(systemName: "info.circle.fill")
              .foregroundColor(self.colorForSeverity)
              .font(.caption)
            Text("Technical Details:")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(self.colorForSeverity)
          }

          VStack(alignment: .leading, spacing: 2) {
            DetailRow(label: "Error Type", value: String(describing: type(of: self.error)))
            DetailRow(label: "Severity", value: String(describing: self.error.severity))
            DetailRow(label: "Retryable", value: self.error.isRetryable ? "Yes" : "No")
            DetailRow(label: "Error Code", value: "\(type(of: self.error))")
          }
        }
        .padding()
        .background(
          RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
            .fill(AccessibleColors.cardBackground)
            .overlay(
              RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                .stroke(self.colorForSeverity.opacity(0.3), lineWidth: 1)
            )
        )
        .cornerRadius(LayoutConstants.cardCornerRadius)
        .transition(
          .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 1.05))
          )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Technical error details")
        .accessibilityHint("Technical information for debugging purposes")
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .animation(.easeInOut(duration: ColorConstants.animationDuration), value: self.showingDetails)
    .onAppear {
    }
  }

  private var colorForSeverity: Color {
    switch self.error.severity {
    case .info: .blue
    case .warning: .orange
    case .error: .red
    case .critical: .purple
    }
  }

  private var iconForSeverity: String {
    switch self.error.severity {
    case .info: "info.circle.fill"
    case .warning: "exclamationmark.triangle.fill"
    case .error: "xmark.circle.fill"
    case .critical: "exclamationmark.octagon.fill"
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

      if !self.errorRecoveryManager.pendingOperations.isEmpty {
        VStack(alignment: .leading, spacing: LayoutConstants.tinySpacing) {
          Text("Pending Operations (\(self.errorRecoveryManager.pendingOperations.count)):")
            .font(.caption)
            .fontWeight(.semibold)

          ForEach(self.errorRecoveryManager.pendingOperations) { operation in
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
  @State private var elapsedTime: TimeInterval = 0
  @State private var timer: Timer?
  let message: String
  let progress: Double?
  let cancel: (() -> Void)?

  init(message: String, progress: Double? = nil, cancel: (() -> Void)? = nil) {
    self.message = message
    self.progress = progress
    self.cancel = cancel
  }

  var body: some View {
    VStack(spacing: 20) {
      if let progress {
        ProgressRingView(progress: progress, message: self.message)
      } else {
        VStack(spacing: 16) {
          LoadingIndicator(message: self.message, size: .large)

          Text(self.message)
            .font(.headline)
            .multilineTextAlignment(.center)

          Text("Time elapsed: \(self.formatTime(self.elapsedTime))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
          self.startTimer()
        }
        .onDisappear {
          self.stopTimer()
        }
      }
    }
  }

  private func startTimer() {
    self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      self.elapsedTime += 1
    }
  }

  private func stopTimer() {
    self.timer?.invalidate()
    self.timer = nil
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
        // Retry action for preview
      }
      .previewDisplayName("Network Error")

      ErrorView(error: .invalidParameters) {
        // Retry action for preview
      }
      .previewDisplayName("Invalid Parameters")

      ErrorView(error: .offlineMode) {
        // Retry action for preview
      }
      .previewDisplayName("Offline Mode")

      LongRunningOperationView(
        message: "Processing your data...",
        progress: 0.75,
        cancel: { /* Cancel action for preview */  }
      )
      .previewDisplayName("Long Running Operation")
    }
  }
}
