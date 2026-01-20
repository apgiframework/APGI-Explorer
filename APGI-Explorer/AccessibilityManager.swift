import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Accessibility Manager

/// Manages accessibility settings and provides accessibility utilities
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var highContrastEnabled = false
    @Published var reducedMotionEnabled = false
    @Published var largeTextEnabled = false
    @Published var voiceOverEnabled = false
    @Published var preferredContentSize: ContentSizeCategory = .medium
    @Published var accessibilityLabelsEnabled = true
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAccessibilityObservers()
        loadAccessibilitySettings()
    }
    
    private func setupAccessibilityObservers() {
        #if canImport(UIKit)
        // Monitor accessibility settings changes
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateContentSize()
            }
            .store(in: &cancellables)
        
        // Monitor voice over status
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateVoiceOverStatus()
            }
            .store(in: &cancellables)
        
        // Monitor reduce motion status
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateReduceMotionStatus()
            }
            .store(in: &cancellables)
        #endif
    }
    
    private func loadAccessibilitySettings() {
        #if canImport(UIKit)
        highContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
        largeTextEnabled = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        voiceOverEnabled = UIAccessibility.isVoiceOverRunning
        preferredContentSize = UIApplication.shared.preferredContentSizeCategory
        #else
        // macOS defaults
        highContrastEnabled = false
        reducedMotionEnabled = false
        largeTextEnabled = false
        voiceOverEnabled = false
        preferredContentSize = .medium
        #endif
    }
    
    private func updateContentSize() {
        #if canImport(UIKit)
        preferredContentSize = UIApplication.shared.preferredContentSizeCategory
        largeTextEnabled = preferredContentSize.isAccessibilityCategory
        #endif
    }
    
    private func updateVoiceOverStatus() {
        #if canImport(UIKit)
        voiceOverEnabled = UIAccessibility.isVoiceOverRunning
        #endif
    }
    
    private func updateReduceMotionStatus() {
        #if canImport(UIKit)
        reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
        #endif
    }
    
    // MARK: - Accessibility Utilities
    
    var shouldReduceMotion: Bool {
        reducedMotionEnabled
    }
    
    var shouldUseHighContrast: Bool {
        highContrastEnabled
    }
    
    var shouldUseLargeText: Bool {
        largeTextEnabled
    }
    
    var shouldAnnounceChanges: Bool {
        voiceOverEnabled
    }
    
    func announce(_ message: String) {
        #if canImport(UIKit)
        guard voiceOverEnabled else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
    
    func setAccessibilityFocus(to element: Any?) {
        #if canImport(UIKit)
        guard voiceOverEnabled else { return }
        UIAccessibility.post(notification: .screenChanged, argument: element)
        #endif
    }
}

// MARK: - Accessible Color System

struct AccessibleColors {
    
    // MARK: - High Contrast Colors
    
    static var primaryText: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.white : Color.primary
    }
    
    static var secondaryText: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.white.opacity(0.8) : Color.secondary
    }
    
    static var background: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.black : Color.adaptiveBackground
    }
    
    static var cardBackground: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.gray.opacity(0.3) : Color.adaptiveBackground
    }
    
    static var accent: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.yellow : Color.blue
    }
    
    static var success: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.green : Color(.systemGreen)
    }
    
    static var warning: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.orange : Color(.systemOrange)
    }
    
    static var error: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.red : Color(.systemRed)
    }
    
    // MARK: - Semantic Colors with Accessibility
    
    static var interactiveElement: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.white : Color.blue
    }
    
    static var disabledElement: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.gray : Color(.systemGray)
    }
    
    static var border: Color {
        AccessibilityManager.shared.shouldUseHighContrast ? 
            Color.white.opacity(0.5) : Color.gray.opacity(0.3)
    }
}

// MARK: - Accessible Animation

struct AccessibleAnimation {
    
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
                    .fill(isHighContrast ? Color.black : Color.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: isHighContrast ? 2 : 0)
                    )
            )
            .foregroundColor(isHighContrast ? Color.white : Color.white)
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
                    .fill(isHighContrast ? Color.gray.opacity(0.2) : Color.adaptiveBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHighContrast ? Color.white : Color.clear, lineWidth: isHighContrast ? 1 : 0)
                    )
            )
            .shadow(
                color: isHighContrast ? Color.clear : Color.black.opacity(0.1),
                radius: isHighContrast ? 0 : 8,
                x: 0,
                y: isHighContrast ? 0 : 4
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
                    .fill(isHighContrast ? Color.black : Color.adaptiveBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHighContrast ? Color.white : Color.gray, lineWidth: isHighContrast ? 2 : 1)
                    )
            )
            .foregroundColor(isHighContrast ? Color.white : Color.primary)
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
        Button(action: action) {
            label
        }
        .buttonStyle(AccessibleButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "")
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
        content
            .modifier(AccessibleCardStyle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel ?? "")
            .accessibilityHint(accessibilityHint ?? "")
    }
}

struct AccessibleProgressView: View {
    let progress: Double
    let total: Double
    let label: String
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return (progress / total) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(AccessibleColors.secondaryText)
            
            ProgressView(value: progress, total: total)
                .progressViewStyle(
                    LinearProgressViewStyle(tint: AccessibleColors.accent)
                )
                .accessibilityLabel("\(label): \(Int(percentage)) percent complete")
                .accessibilityValue("\(Int(percentage)) percent")
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
            Text(title)
                .font(.headline)
                .foregroundColor(AccessibleColors.primaryText)
            
            content
                .accessibilityElement(children: .contain)
                .accessibilityLabel(title)
                .accessibilityHint(description)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
        .accessibilityHint(description)
    }
}

// MARK: - Accessibility Settings View

struct AccessibilitySettingsView: View {
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Visual")) {
                    Toggle("High Contrast", isOn: .constant(accessibilityManager.highContrastEnabled))
                        .disabled(true) // System setting
                        .accessibilityHint("High contrast is controlled in system settings")
                    
                    Toggle("Large Text", isOn: .constant(accessibilityManager.largeTextEnabled))
                        .disabled(true) // System setting
                        .accessibilityHint("Large text is controlled in system settings")
                }
                
                Section(header: Text("Motion")) {
                    Toggle("Reduce Motion", isOn: .constant(accessibilityManager.reducedMotionEnabled))
                        .disabled(true) // System setting
                        .accessibilityHint("Reduce motion is controlled in system settings")
                }
                
                Section(header: Text("Audio")) {
                    Toggle("VoiceOver", isOn: .constant(accessibilityManager.voiceOverEnabled))
                        .disabled(true) // System setting
                        .accessibilityHint("VoiceOver is controlled in system settings")
                    
                    Toggle("Accessibility Labels", isOn: $accessibilityManager.accessibilityLabelsEnabled)
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
                            accessibilityManager.announce("Sample button tapped")
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
    
    func accessibilityAnnounceOnChange<T: Equatable>(_ value: T, announcement: String) -> some View {
        self.onChange(of: value) { _, _ in
            AccessibilityManager.shared.announce(announcement)
        }
    }
}

// MARK: - Accessibility Helpers

struct AccessibilityHelper {
    
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
        44 // Apple's recommended minimum touch target size
    }
    
    static var recommendedSpacing: CGFloat {
        AccessibilityManager.shared.shouldUseLargeText ? 16 : 8
    }
    
    static var recommendedPadding: CGFloat {
        AccessibilityManager.shared.shouldUseLargeText ? 20 : 16
    }
}
