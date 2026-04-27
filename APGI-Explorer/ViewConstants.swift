import SwiftUI

// MARK: - Layout Constants

enum LayoutConstants {
  // Spacing
  static let giantSpacing: CGFloat = APGISpacing.giant
  static let extraLargeSpacing: CGFloat = APGISpacing.xl
  static let largeSpacing: CGFloat = APGISpacing.lg
  static let mediumSpacing: CGFloat = APGISpacing.md
  static let smallSpacing: CGFloat = APGISpacing.sm
  static let tinySpacing: CGFloat = APGISpacing.xs

  /// Padding
  static var topPadding: CGFloat {
    AccessibilityManager.shared.shouldUseLargeText ? 60 : 40
  }

  static var bottomPadding: CGFloat {
    AccessibilityManager.shared.shouldUseLargeText ? 75 : 50
  }

  static var titleBottomPadding: CGFloat {
    AccessibilityManager.shared.shouldUseLargeText ? 30 : 20
  }

  static var horizontalPadding: CGFloat {
    AccessibilityManager.shared.shouldUseLargeText ? 45 : 30
  }

  static let buttonPadding: CGFloat = APGISpacing.md

  // Corner Radius
  static let buttonCornerRadius: CGFloat = APGIRadius.standard
  static let cardCornerRadius: CGFloat = APGIRadius.standard

  /// Shadow
  static let buttonShadowRadius: CGFloat = 3

  /// Font Sizes
  static var iconFontSize: CGFloat {
    AccessibilityManager.shared.shouldUseLargeText ? 90 : 60
  }

  static var errorIconFontSize: CGFloat {
    AccessibilityManager.shared.shouldUseLargeText ? 75 : 50
  }

  static var offlineIconFontSize: CGFloat {
    AccessibilityManager.shared.shouldUseLargeText ? 60 : 40
  }
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
