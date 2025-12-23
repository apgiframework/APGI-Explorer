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
