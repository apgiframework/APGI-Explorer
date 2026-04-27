import SwiftUI

enum APGITypography {
    // MARK: - Font Families
    private static let headlineFont = "Crimson Pro"
    private static let bodyFont = "Inter"
    private static let monoFont = "Fira Code"

    // MARK: - Scale
    static let display = fontWithFallback(custom: headlineFont, size: 72, weight: .bold, system: .largeTitle)
    static let h1 = fontWithFallback(custom: headlineFont, size: 48, weight: .bold, system: .title)
    static let h2 = fontWithFallback(custom: headlineFont, size: 30, weight: .semibold, system: .title2)
    static let h3 = fontWithFallback(custom: bodyFont, size: 20, weight: .semibold, system: .title3)
    static let body = fontWithFallback(custom: bodyFont, size: 16, weight: .regular, system: .body)
    static let label = fontWithFallback(custom: bodyFont, size: 14, weight: .medium, system: .subheadline)
    static let caption = fontWithFallback(custom: bodyFont, size: 14, weight: .regular, system: .footnote)
    static let micro = fontWithFallback(custom: bodyFont, size: 12, weight: .regular, system: .caption)
    static let mono: Font = {
        if isFontAvailable(monoFont) {
            return Font.custom(monoFont, size: 14).weight(.regular)
        } else {
            return Font.system(.body, design: .monospaced)
        }
    }()

    // MARK: - Helper Methods

    private static func fontWithFallback(
        custom: String,
        size: CGFloat,
        weight: Font.Weight,
        system: Font.TextStyle
    ) -> Font {
        if isFontAvailable(custom) {
            return Font.custom(custom, size: size).weight(weight)
        } else {
            return Font.system(system).weight(weight)
        }
    }

    private static func isFontAvailable(_ fontName: String) -> Bool {
        #if os(macOS)
        NSFont(name: fontName, size: 12) != nil
        #else
        UIFont(name: fontName, size: 12) != nil
        #endif
    }

    // MARK: - System Fallbacks
    static func fallback(for font: Font) -> Font {
        return font
    }
}

extension View {
    func apgiFont(_ typography: Font) -> some View {
        self.font(typography)
    }
}
