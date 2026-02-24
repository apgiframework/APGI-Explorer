import SwiftUI

// MARK: - Layout Constants

enum LayoutConstants {
    // Spacing
    static let largeSpacing: CGFloat = 30
    static let mediumSpacing: CGFloat = 20
    static let smallSpacing: CGFloat = 10
    static let tinySpacing: CGFloat = 4

    // Padding
    static let topPadding: CGFloat = 40
    static let bottomPadding: CGFloat = 50
    static let titleBottomPadding: CGFloat = 20
    static let horizontalPadding: CGFloat = 30
    static let buttonPadding: CGFloat = 16

    // Corner Radius
    static let buttonCornerRadius: CGFloat = 15
    static let cardCornerRadius: CGFloat = 8

    /// Shadow
    static let buttonShadowRadius: CGFloat = 3

    // Font Sizes
    static let iconFontSize: CGFloat = 60
    static let errorIconFontSize: CGFloat = 50
    static let offlineIconFontSize: CGFloat = 40
}

// MARK: - Color Constants

enum ColorConstants {
    static let backgroundOpacity: Double = 0.2
    static let cardBackgroundOpacity: Double = 0.1
    static let shadowOpacity: Double = 0.1

    // Animation
    static let animationDuration: Double = 0.3
    static let retryDelay: Double = 2.0

    // Data Ranges
    static let minParameterValue: Double = -100
    static let maxParameterValue: Double = 100
    static let minPositiveValue: Double = 0
}

// MARK: - Data Constants

enum DataConstants {
    static let previewProfileCount: Int = 5
    static let fetchLimit: Int = 1
    static let probabilityMultiplier: Double = 100.0
    static let circleSize: CGFloat = 6
}
