import SwiftUI

#if os(macOS)
import AppKit
#endif

extension Color {
    // MARK: - Neural Glow Semantics
    static let thresholdBlue = Color(hex: "0066CC")
    static let precisionRed = Color(hex: "CC0033")
    static let errorYellow = Color(hex: "CC9900")
    static let workspacePurple = Color(hex: "6633CC")
    static let neuromodGreen = Color(hex: "008866")
    static let inactiveSlate = Color(hex: "6B7280")
    static let spaceBlack = Color(hex: "FFFFFF")
    static let darkNavy = Color(hex: "F3F4F6")
    // MARK: - Legacy Brand Color Aliases
    static let apgiBlue = thresholdBlue
    static let apgiPurple = workspacePurple
    static let apgiGreen = neuromodGreen
    static let apgiOrange = errorYellow
    static let apgiRed = precisionRed
    // MARK: - Semantic State Colors
    static let apgiSuccess = neuromodGreen
    static let apgiWarning = errorYellow
    static let apgiDanger = precisionRed
    static let apgiInfo = thresholdBlue
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
