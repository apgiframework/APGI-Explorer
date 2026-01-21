import SwiftUI

#if os(macOS)
import AppKit
#endif

enum ParameterLevel: String, CaseIterable {
    case veryLow = "Very Low"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"

    var rawValue: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
}

// MARK: - Color Scheme Contrast
enum ColorSchemeContrast {
    case standard
    case increased
}

// MARK: - App Color System

struct AppColors {
    // Primary colors from asset catalog
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let background = Color("Background")
    static let cardBackground = Color("CardBackground")

    // System colors with dark mode support
    static var adaptiveGray: Color {
        #if os(macOS)
        Color(NSColor.systemGray)
        #else
        Color(UIColor.systemGray)
        #endif
    }
    static var adaptiveGray2: Color {
        #if os(macOS)
        Color(NSColor.systemGray.withAlphaComponent(0.8))
        #else
        Color(UIColor.systemGray2)
        #endif
    }
    static var adaptiveGray3: Color {
        #if os(macOS)
        Color(NSColor.systemGray.withAlphaComponent(0.6))
        #else
        Color(UIColor.systemGray3)
        #endif
    }
    static var adaptiveGray4: Color {
        #if os(macOS)
        Color(NSColor.systemGray.withAlphaComponent(0.4))
        #else
        Color(UIColor.systemGray4)
        #endif
    }
    static var adaptiveGray5: Color {
        #if os(macOS)
        Color(NSColor.systemGray.withAlphaComponent(0.3))
        #else
        Color(UIColor.systemGray5)
        #endif
    }
    static var adaptiveGray6: Color {
        #if os(macOS)
        Color(NSColor.systemGray.withAlphaComponent(0.2))
        #else
        Color(UIColor.systemGray6)
        #endif
    }

    // Semantic colors
    static let error = Color.red
    static let success = Color.green
    static let warning = Color.orange
    static let info = Color.blue

    // Background colors
    static var primaryBackground: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }
    static var secondaryBackground: Color {
        #if os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color(UIColor.secondarySystemBackground)
        #endif
    }
    static var tertiaryBackground: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor.blended(withFraction: 0.7, of: NSColor.controlBackgroundColor) ?? NSColor.controlBackgroundColor)
        #else
        Color(UIColor.tertiarySystemBackground)
        #endif
    }

    // Text colors
    static var primaryText: Color {
        #if os(macOS)
        Color(NSColor.labelColor)
        #else
        Color(UIColor.label)
        #endif
    }
    static var secondaryText: Color {
        #if os(macOS)
        Color(NSColor.secondaryLabelColor)
        #else
        Color(UIColor.secondaryLabel)
        #endif
    }
    static var tertiaryText: Color {
        #if os(macOS)
        Color(NSColor.tertiaryLabelColor)
        #else
        Color(UIColor.tertiaryLabel)
        #endif
    }

    // Accent colors
    static let accent = Color.accentColor

    // Custom app-specific colors
    static let parameterHigh = Color.blue
    static let parameterLow = Color.red
    static let parameterMedium = Color.orange
    static let similarityHighlight = Color.green.opacity(0.3)

    // Interactive elements
    static let buttonBackground = Color.accentColor
    static let buttonText = Color.white
    static let buttonDisabled = Color.gray.opacity(0.6)

    // Loading and progress
    static let progressTint = Color.accentColor
    static let loadingOverlay = Color.black.opacity(0.4)
}

// MARK: - Standardized Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, LayoutConstants.buttonPadding)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius)
                    .fill(configuration.isPressed ? AppColors.buttonBackground.opacity(0.8) : AppColors.buttonBackground)
            )
            .foregroundColor(AppColors.buttonText)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, LayoutConstants.buttonPadding)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius)
                    .stroke(AppColors.buttonBackground, lineWidth: 1.5)
                    .fill(configuration.isPressed ? AppColors.secondaryBackground : AppColors.primaryBackground)
            )
            .foregroundColor(AppColors.buttonBackground)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, LayoutConstants.buttonPadding)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius)
                    .fill(configuration.isPressed ? AppColors.error.opacity(0.8) : AppColors.error)
            )
            .foregroundColor(AppColors.buttonText)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct AppPlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? AppColors.adaptiveGray5 : Color.clear)
            )
            .foregroundColor(AppColors.primaryText)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Enhanced Focus Indicator Modifiers

struct FocusIndicatorModifier: ViewModifier {
    @FocusState.Binding var isFocused: Bool
    let cornerRadius: CGFloat
    let colorSchemeContrast: ColorSchemeContrast

    init(isFocused: FocusState<Bool>.Binding, cornerRadius: CGFloat = LayoutConstants.cardCornerRadius, colorSchemeContrast: ColorSchemeContrast = .standard) {
        self._isFocused = isFocused
        self.cornerRadius = cornerRadius
        self.colorSchemeContrast = colorSchemeContrast
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        focusColor,
                        lineWidth: focusLineWidth
                    )
                    .opacity(isFocused ? 1.0 : 0.0)
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .accessibilityAddTraits(.isButton)
    }

    private var focusColor: Color {
        switch colorSchemeContrast {
        case .increased:
            return AppColors.buttonBackground
        case .standard:
            return AppColors.buttonBackground.opacity(0.8)
        @unknown default:
            return AppColors.buttonBackground.opacity(0.8)
        }
    }

    private var focusLineWidth: CGFloat {
        switch colorSchemeContrast {
        case .increased:
            return 4
        case .standard:
            return 2
        @unknown default:
            return 2
        }
    }
}

struct EnhancedFocusIndicatorModifier: ViewModifier {
    @FocusState.Binding var isFocused: Bool
    let style: FocusStyle
    let colorSchemeContrast: ColorSchemeContrast

    init(isFocused: FocusState<Bool>.Binding, style: FocusStyle, colorSchemeContrast: ColorSchemeContrast = .standard) {
        self._isFocused = isFocused
        self.style = style
        self.colorSchemeContrast = colorSchemeContrast
    }

    enum FocusStyle {
        case button
        case card
        case textfield
        case custom(Color, CGFloat)

        var color: Color {
            switch self {
            case .button:
                return AppColors.buttonBackground
            case .card:
                return AppColors.accent
            case .textfield:
                return AppColors.accent
            case .custom(let color, _):
                return color
            }
        }

        var lineWidth: CGFloat {
            switch self {
            case .button:
                return 2
            case .card:
                return 1.5
            case .textfield:
                return 2
            case .custom(_, let width):
                return width
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                    .stroke(
                        style.color,
                        lineWidth: adjustedLineWidth
                    )
                    .shadow(
                        color: style.color.opacity(0.3),
                        radius: isFocused ? 4 : 0,
                        x: 0,
                        y: 0
                    )
                    .opacity(isFocused ? 1.0 : 0.0)
            )
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                    .fill(style.color.opacity(0.1))
                    .opacity(isFocused ? 1.0 : 0.0)
            )
            .scaleEffect(isFocused ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .accessibilityAddTraits(.isButton)
    }

    private var adjustedLineWidth: CGFloat {
        let baseWidth = style.lineWidth
        switch colorSchemeContrast {
        case .increased:
            return baseWidth * 1.5
        case .standard:
            return baseWidth
        @unknown default:
            return baseWidth
        }
    }
}

struct AccessibleTapModifier: ViewModifier {
    let action: () -> Void
    let accessibilityLabel: String?
    let accessibilityHint: String?

    func body(content: Content) -> some View {
        content
            .onTapGesture(perform: action)
            .accessibilityLabel(accessibilityLabel ?? "")
            .accessibilityHint(accessibilityHint ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

extension View {
    func accessibleTap(action: @escaping () -> Void, accessibilityLabel: String? = nil, accessibilityHint: String? = nil) -> some View {
        self.modifier(AccessibleTapModifier(action: action, accessibilityLabel: accessibilityLabel, accessibilityHint: accessibilityHint))
    }

    func focusIndicator<T: View>(_ isFocused: FocusState<Bool>.Binding) -> some View {
        self.modifier(FocusIndicatorModifier(isFocused: isFocused, cornerRadius: LayoutConstants.cardCornerRadius))
    }

    func enhancedFocusIndicator<T: View>(_ isFocused: FocusState<Bool>.Binding, style: EnhancedFocusIndicatorModifier.FocusStyle, colorSchemeContrast: ColorSchemeContrast = .standard) -> some View {
        self.modifier(EnhancedFocusIndicatorModifier(isFocused: isFocused, style: style, colorSchemeContrast: colorSchemeContrast))
    }

    func accessibleFocusIndicator(isFocused: FocusState<Bool>.Binding, style: EnhancedFocusIndicatorModifier.FocusStyle = .button, colorSchemeContrast: ColorSchemeContrast = .standard) -> some View {
        self.modifier(EnhancedFocusIndicatorModifier(isFocused: isFocused, style: style, colorSchemeContrast: colorSchemeContrast))
    }

    func buttonFocusIndicator(isFocused: FocusState<Bool>.Binding, colorSchemeContrast: ColorSchemeContrast = .standard) -> some View {
        self.modifier(EnhancedFocusIndicatorModifier(isFocused: isFocused, style: .button, colorSchemeContrast: colorSchemeContrast))
    }

    func cardFocusIndicator(isFocused: FocusState<Bool>.Binding, colorSchemeContrast: ColorSchemeContrast = .standard) -> some View {
        self.modifier(EnhancedFocusIndicatorModifier(isFocused: isFocused, style: .card, colorSchemeContrast: colorSchemeContrast))
    }

    func textFieldFocusIndicator(isFocused: FocusState<Bool>.Binding, colorSchemeContrast: ColorSchemeContrast = .standard) -> some View {
        self.modifier(EnhancedFocusIndicatorModifier(isFocused: isFocused, style: .textfield, colorSchemeContrast: colorSchemeContrast))
    }

    func customFocusIndicator(isFocused: FocusState<Bool>.Binding, color: Color, lineWidth: CGFloat = 2, colorSchemeContrast: ColorSchemeContrast = .standard) -> some View {
        self.modifier(EnhancedFocusIndicatorModifier(isFocused: isFocused, style: .custom(color, lineWidth), colorSchemeContrast: colorSchemeContrast))
    }

}

// MARK: - Toast Notification System

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval

    static func success(_ message: String, duration: TimeInterval = 3.0) -> ToastMessage {
        ToastMessage(message: message, type: .success, duration: duration)
    }

    static func error(_ message: String, duration: TimeInterval = 5.0) -> ToastMessage {
        ToastMessage(message: message, type: .error, duration: duration)
    }

    static func warning(_ message: String, duration: TimeInterval = 4.0) -> ToastMessage {
        ToastMessage(message: message, type: .warning, duration: duration)
    }

    static func info(_ message: String, duration: TimeInterval = 3.0) -> ToastMessage {
        ToastMessage(message: message, type: .info, duration: duration)
    }
}

enum ToastType {
    case success
    case error
    case warning
    case info

    var color: Color {
        switch self {
        case .success: return AppColors.success
        case .error: return AppColors.error
        case .warning: return AppColors.warning
        case .info: return AppColors.info
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct ToastView: View {
    let message: ToastMessage

    var body: some View {
        HStack(spacing: LayoutConstants.smallSpacing) {
            Image(systemName: message.type.icon)
                .foregroundColor(message.type.color)
                .font(.system(size: 16, weight: .semibold))

            Text(message.message)
                .font(.subheadline)
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, LayoutConstants.mediumSpacing)
        .padding(.vertical, LayoutConstants.smallSpacing)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                .fill(AppColors.primaryBackground)
                .shadow(color: .black.opacity(ColorConstants.shadowOpacity), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                .stroke(message.type.color, lineWidth: 1)
        )
    }
}

struct ToastContainer: ViewModifier {
    @Binding var toast: ToastMessage?

    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if let toast = toast {
                        ToastView(message: toast)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                            .padding(.top, LayoutConstants.largeSpacing)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        self.toast = nil
                                    }
                                }
                            }
                        Spacer()
                    }
                }
                .padding(.horizontal, LayoutConstants.mediumSpacing),
                alignment: .top
            )
            .animation(.easeInOut(duration: 0.3), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        self.modifier(ToastContainer(toast: toast))
    }
}

// MARK: - Reusable View Components

struct StandardCard<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat

    init(
        backgroundColor: Color = AppColors.primaryBackground,
        cornerRadius: CGFloat = LayoutConstants.cardCornerRadius,
        shadowRadius: CGFloat = LayoutConstants.buttonShadowRadius,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }

    var body: some View {
        content
            .padding(LayoutConstants.mediumSpacing)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(ColorConstants.shadowOpacity), radius: shadowRadius, x: 0, y: 2)
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        StandardCard {
            VStack(alignment: .leading, spacing: LayoutConstants.smallSpacing) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)

                content
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
}

struct ActionButton<Content: View>: View {
    let action: () -> Void
    let style: any ButtonStyle
    let content: Content
    let isDisabled: Bool

    init(
        style: any ButtonStyle = PrimaryButtonStyle(),
        isDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.style = style
        self.content = content()
        self.isDisabled = isDisabled
    }

    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(AnyButtonStyle(style: style))
        .disabled(isDisabled)
    }
}

struct FormRow<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.tinySpacing) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.primaryText)

            content
        }
        .padding(.vertical, LayoutConstants.smallSpacing)
    }
}

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    let style: any ButtonStyle

    init(
        title: String,
        isLoading: Bool = false,
        style: any ButtonStyle = PrimaryButtonStyle(),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutConstants.smallSpacing) {
                if isLoading {
                    LoadingIndicator(size: .small)
                }

                Text(isLoading ? "Loading..." : title)
            }
        }
        .buttonStyle(AnyButtonStyle(style: style))
        .disabled(isLoading)
    }
}

// MARK: - Color Extensions

extension Color {
    static func parameterLevel(_ level: ParameterLevel) -> Color {
        switch level {
        case .veryLow, .low:
            return AppColors.parameterLow
        case .moderate:
            return AppColors.parameterMedium
        case .high, .veryHigh:
            return AppColors.parameterHigh
        }
    }

    static func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...1.0:
            return AppColors.success
        case 0.6..<0.8:
            return AppColors.warning
        default:
            return AppColors.error
        }
    }
}

// MARK: - Type Erasure for ButtonStyle

struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
