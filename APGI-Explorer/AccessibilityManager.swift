import Combine
import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif
#if os(macOS)
  import AppKit
  import ApplicationServices
#endif

// MARK: - Accessibility Manager

/// Manages accessibility settings and provides accessibility utilities
class AccessibilityManager: ObservableObject {
  static let shared = AccessibilityManager()

  @Published var colorBlindMode: ColorBlindMode = .none
  @Published var highContrastEnabled = false
  @Published var reducedMotionEnabled = false
  @Published var largeTextEnabled = false
  @Published var voiceOverEnabled = false
  @Published var preferredContentSize: ContentSizeCategory = .medium
  @Published var accessibilityLabelsEnabled = true

  enum ColorBlindMode: String, CaseIterable, Identifiable {
    case none = "None"
    case protanopia = "Protanopia"
    case deuteranopia = "Deuteranopia"
    case tritanopia = "Tritanopia"
    var id: String { self.rawValue }
    var opacity: Double {
      switch self {
      case .none: 1.0
      case .protanopia, .deuteranopia, .tritanopia: 0.8
      }
    }

    var saturation: Double {
      switch self {
      case .none: 1.0
      case .protanopia: 0.7
      case .deuteranopia: 0.6
      case .tritanopia: 0.5
      }
    }
  }

  private var cancellables = Set<AnyCancellable>()

  private init() {
    self.setupAccessibilityObservers()
    self.loadAccessibilitySettings()
  }

  private func setupAccessibilityObservers() {
    #if canImport(UIKit)
      // Monitor accessibility settings changes
      NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
        .sink { [weak self] _ in
          self?.updateContentSize()
        }
        .store(in: &self.cancellables)

      // Monitor voice over status
      NotificationCenter.default.publisher(
        for: UIAccessibility.voiceOverStatusDidChangeNotification
      )
      .sink { [weak self] _ in
        self?.updateVoiceOverStatus()
      }
      .store(in: &self.cancellables)

      // Monitor reduce motion status
      NotificationCenter.default.publisher(
        for: UIAccessibility.reduceMotionStatusDidChangeNotification
      )
      .sink { [weak self] _ in
        self?.updateReduceMotionStatus()
      }
      .store(in: &self.cancellables)
    #endif
    #if os(macOS)
      NSWorkspace.shared.notificationCenter
        .publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
          self?.voiceOverEnabled = NSWorkspace.shared.isVoiceOverEnabled
          self?.reducedMotionEnabled = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
          self?.highContrastEnabled = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        }
        .store(in: &self.cancellables)
    #endif
  }

  private func loadAccessibilitySettings() {
    #if canImport(UIKit)
      self.highContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
      self.reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
      self.largeTextEnabled =
        UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
      self.voiceOverEnabled = UIAccessibility.isVoiceOverRunning
      self.preferredContentSize = UIApplication.shared.preferredContentSizeCategory
    #endif
    #if os(macOS)
      self.reducedMotionEnabled = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
      self.highContrastEnabled = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
      let options =
        [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false] as CFDictionary
      self.voiceOverEnabled = AXIsProcessTrustedWithOptions(options)
      self.preferredContentSize = .medium
      self.largeTextEnabled = false
    #endif
  }

  private func updateContentSize() {
    #if canImport(UIKit)
      self.preferredContentSize = UIApplication.shared.preferredContentSizeCategory
      self.largeTextEnabled = self.preferredContentSize.isAccessibilityCategory
    #endif
  }

  private func updateVoiceOverStatus() {
    #if canImport(UIKit)
      self.voiceOverEnabled = UIAccessibility.isVoiceOverRunning
    #endif
  }

  private func updateReduceMotionStatus() {
    #if canImport(UIKit)
      self.reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
    #endif
  }

  // MARK: - Accessibility Utilities

  var shouldReduceMotion: Bool {
    self.reducedMotionEnabled
  }

  var shouldUseHighContrast: Bool {
    self.highContrastEnabled
  }

  var shouldUseLargeText: Bool {
    self.largeTextEnabled
  }

  var shouldAnnounceChanges: Bool {
    self.voiceOverEnabled
  }

  func announce(_ message: String) {
    #if canImport(UIKit)
      guard self.voiceOverEnabled else { return }
      UIAccessibility.post(notification: .announcement, argument: message)
    #endif
  }

  func setAccessibilityFocus(to element: Any?) {
    #if canImport(UIKit)
      guard self.voiceOverEnabled else { return }
      UIAccessibility.post(notification: .screenChanged, argument: element)
    #endif
  }
}

// MARK: - Accessible Color System

enum AccessibleColors {
  // MARK: - High Contrast Colors

  static var primaryText: Color {
    AccessibilityManager.shared.shouldUseHighContrast ? Color.black : Color.primary
  }

  static var secondaryText: Color {
    AccessibilityManager.shared.shouldUseHighContrast ? Color.black.opacity(0.8) : Color.secondary
  }

  static var background: Color {
    AccessibilityManager.shared.shouldUseHighContrast ? Color.white : Color.adaptiveBackground
  }

  static var cardBackground: Color {
    AccessibilityManager.shared.shouldUseHighContrast
      ? Color.white : Color.adaptiveBackground
  }

  static var accent: Color {
    AccessibilityManager.shared.shouldUseHighContrast ? Color.black : Color.blue
  }

  static var success: Color {
    AccessibilityManager.shared.shouldUseHighContrast ? Color.green : Color(.systemGreen)
  }

  static var warning: Color {
    AccessibilityManager.shared.shouldUseHighContrast ? Color.orange : Color(.systemOrange)
  }

  static var error: Color {
    AccessibilityManager.shared.shouldUseHighContrast ? Color.red : Color(.systemRed)
  }

  // MARK: - Semantic Colors with Accessibility

  static var interactiveElement: Color {
    AccessibilityManager.shared.shouldUseHighContrast ? Color.white : Color.blue
  }

  static var disabledElement: Color {
    AccessibilityManager.shared.shouldUseHighContrast ? Color.gray : Color(.systemGray)
  }

  static var border: Color {
    AccessibilityManager.shared.shouldUseHighContrast
      ? Color.white.opacity(0.5) : Color.gray.opacity(0.3)
  }
}

// MARK: - Accessible Animation

enum AccessibleAnimation {
  static func defaultAnimation(_ animation: Animation? = nil) -> Animation {
    if AccessibilityManager.shared.shouldReduceMotion {
      return Animation.linear(duration: 0)
    }
    return animation ?? .easeInOut(duration: 0.3)
  }

  static func springAnimation() -> Animation {
    if AccessibilityManager.shared.shouldReduceMotion {
      return Animation.linear(duration: 0)
    }
    return .spring(response: 0.5, dampingFraction: 0.8)
  }

  static func delayedAnimation(delay: Double = 0.2) -> Animation {
    if AccessibilityManager.shared.shouldReduceMotion {
      return Animation.linear(duration: 0)
    }
    return .easeInOut(duration: 0.3).delay(delay)
  }
}

// MARK: - Accessible View Modifiers

struct AccessibleButtonStyle: ButtonStyle {
  let isHighContrast: Bool

  init() {
    self.isHighContrast = AccessibilityManager.shared.shouldUseHighContrast
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(self.isHighContrast ? Color.black : Color.blue)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.white, lineWidth: self.isHighContrast ? 2 : 0)
          )
      )
      .foregroundColor(self.isHighContrast ? Color.white : Color.white)
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(AccessibleAnimation.defaultAnimation(), value: configuration.isPressed)
  }
}

struct AccessibleCardStyle: ViewModifier {
  let isHighContrast: Bool

  init() {
    self.isHighContrast = AccessibilityManager.shared.shouldUseHighContrast
  }

  func body(content: Content) -> some View {
    content
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(self.isHighContrast ? Color.gray.opacity(0.2) : Color.adaptiveBackground)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(
                self.isHighContrast ? Color.white : Color.clear,
                lineWidth: self.isHighContrast ? 1 : 0)
          )
      )
      .shadow(
        color: self.isHighContrast ? Color.clear : Color.black.opacity(0.1),
        radius: self.isHighContrast ? 0 : 8,
        x: 0,
        y: self.isHighContrast ? 0 : 4
      )
  }
}

struct AccessibleTextFieldStyle: TextFieldStyle {
  let isHighContrast: Bool

  init() {
    self.isHighContrast = AccessibilityManager.shared.shouldUseHighContrast
  }

  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(self.isHighContrast ? Color.black : AppColors.primaryBackground)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(
                self.isHighContrast ? Color.white : Color.gray,
                lineWidth: self.isHighContrast ? 2 : 1)
          )
      )
      .foregroundColor(self.isHighContrast ? Color.white : Color.primary)
  }
}

// MARK: - Accessible Components

struct AccessibleButton<Label: View>: View {
  let action: () -> Void
  let label: Label
  let accessibilityLabel: String
  let accessibilityHint: String?

  init(
    accessibilityLabel: String,
    accessibilityHint: String? = nil,
    action: @escaping () -> Void,
    @ViewBuilder label: () -> Label
  ) {
    self.accessibilityLabel = accessibilityLabel
    self.accessibilityHint = accessibilityHint
    self.action = action
    self.label = label()
  }

  var body: some View {
    Button(action: self.action) {
      self.label
    }
    .buttonStyle(AccessibleButtonStyle())
    .accessibilityLabel(self.accessibilityLabel)
    .accessibilityHint(self.accessibilityHint ?? "")
    .accessibilityAddTraits(.isButton)
  }
}

struct AccessibleCard<Content: View>: View {
  let content: Content
  let accessibilityLabel: String?
  let accessibilityHint: String?

  init(
    accessibilityLabel: String? = nil,
    accessibilityHint: String? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.accessibilityLabel = accessibilityLabel
    self.accessibilityHint = accessibilityHint
    self.content = content()
  }

  var body: some View {
    self.content
      .modifier(AccessibleCardStyle())
      .accessibilityElement(children: .combine)
      .accessibilityLabel(self.accessibilityLabel ?? "")
      .accessibilityHint(self.accessibilityHint ?? "")
  }
}

struct AccessibleProgressView: View {
  let progress: Double
  let total: Double
  let label: String

  private var percentage: Double {
    guard self.total > 0 else { return 0 }
    return (self.progress / self.total) * 100
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(self.label)
        .font(.caption)
        .foregroundColor(AccessibleColors.secondaryText)

      ProgressView(value: self.progress, total: self.total)
        .progressViewStyle(
          LinearProgressViewStyle(tint: AccessibleColors.accent)
        )
        .accessibilityLabel("\(self.label): \(Int(self.percentage)) percent complete")
        .accessibilityValue("\(Int(self.percentage)) percent")
    }
  }
}

struct AccessibleChart<Content: View>: View {
  let content: Content
  let title: String
  let description: String

  init(
    title: String,
    description: String,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.description = description
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(self.title)
        .font(.headline)
        .foregroundColor(AccessibleColors.primaryText)

      self.content
        .accessibilityElement(children: .contain)
        .accessibilityLabel(self.title)
        .accessibilityHint(self.description)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(self.title)
    .accessibilityHint(self.description)
  }
}

// MARK: - Accessibility Settings View

struct AccessibilitySettingsView: View {
  @ObservedObject private var accessibilityManager = AccessibilityManager.shared

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Visual")) {
          Toggle("High Contrast", isOn: .constant(self.accessibilityManager.highContrastEnabled))
            .disabled(true)  // System setting
            .accessibilityHint("High contrast is controlled in system settings")

          Toggle("Large Text", isOn: .constant(self.accessibilityManager.largeTextEnabled))
            .disabled(true)  // System setting
            .accessibilityHint("Large text is controlled in system settings")
        }

        Section(header: Text("Motion")) {
          Toggle("Reduce Motion", isOn: .constant(self.accessibilityManager.reducedMotionEnabled))
            .disabled(true)  // System setting
            .accessibilityHint("Reduce motion is controlled in system settings")
        }

        Section(header: Text("Audio")) {
          Toggle("VoiceOver", isOn: .constant(self.accessibilityManager.voiceOverEnabled))
            .disabled(true)  // System setting
            .accessibilityHint("VoiceOver is controlled in system settings")

          Toggle(
            "Accessibility Labels", isOn: self.$accessibilityManager.accessibilityLabelsEnabled
          )
          .accessibilityHint("Enable additional accessibility labels throughout the app")
        }

        Section(header: Text("Preview")) {
          HStack {
            Text("Sample Button")
            Spacer()
            AccessibleButton(
              accessibilityLabel: "Sample button",
              accessibilityHint: "This is a sample accessible button"
            ) {
              self.accessibilityManager.announce("Sample button tapped")
            } label: {
              Text("Tap Me")
            }
          }

          AccessibleCard(
            accessibilityLabel: "Sample card",
            accessibilityHint: "This is a sample accessible card with content"
          ) {
            VStack(alignment: .leading) {
              Text("Sample Card")
                .font(.headline)
              Text("This is an accessible card with proper contrast and labeling.")
                .font(.body)
            }
          }
        }
      }
      .navigationTitle("Accessibility")
    }
  }
}

// MARK: - View Extensions

extension View {
  func accessibleButton(
    _ label: String,
    hint: String? = nil,
    action: @escaping () -> Void
  ) -> some View {
    AccessibleButton(accessibilityLabel: label, accessibilityHint: hint, action: action) {
      self
    }
  }

  func accessibleCard(
    _ label: String? = nil,
    hint: String? = nil
  ) -> some View {
    AccessibleCard(accessibilityLabel: label, accessibilityHint: hint) {
      self
    }
  }

  func accessibleAnimation(_ animation: Animation? = nil) -> some View {
    self.animation(AccessibleAnimation.defaultAnimation(animation), value: UUID())
  }

  func accessibleColors() -> some View {
    self.foregroundColor(AccessibleColors.primaryText)
      .background(AccessibleColors.background)
  }

  func accessibilityAnnounceOnChange(_ value: some Equatable, announcement: String) -> some View {
    self.onChange(of: value) { _, _ in
      AccessibilityManager.shared.announce(announcement)
    }
  }
}

// MARK: - Accessibility Helpers

enum AccessibilityHelper {
  static func announceProgress(_ current: Int, total: Int, item: String) {
    let percentage = Int((Double(current) / Double(total)) * 100)
    let message = "\(item) \(current) of \(total), \(percentage) percent complete"
    AccessibilityManager.shared.announce(message)
  }

  static func announceError(_ error: String) {
    AccessibilityManager.shared.announce("Error: \(error)")
  }

  static func announceSuccess(_ message: String) {
    AccessibilityManager.shared.announce("Success: \(message)")
  }

  static func setAccessibilityFocus(to view: Any?) {
    AccessibilityManager.shared.setAccessibilityFocus(to: view)
  }

  static var minimumTouchTargetSize: CGFloat {
    44  // Apple's recommended minimum touch target size
  }

  static var recommendedSpacing: CGFloat {
    AccessibilityManager.shared.shouldUseLargeText ? 16 : 8
  }

  static var recommendedPadding: CGFloat {
    AccessibilityManager.shared.shouldUseLargeText ? 20 : 16
  }
}
