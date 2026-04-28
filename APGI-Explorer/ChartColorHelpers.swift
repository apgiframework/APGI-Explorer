import SwiftUI

// MARK: - Chart Color Helpers

extension Color {
  static func baseColorForParameter(_ parameter: String) -> Color {
    switch parameter {
    case "ε (Epsilon)": .blue
    case "π (Precision)": .green
    case "θₜ (Threshold)": .orange
    case "β (Somatic Bias)": .purple
    default: .gray
    }
  }

  static func applyColorScheme(to color: Color, scheme: String) -> Color {
    switch scheme {
    case "colorful":
      return colorfulVariant(of: color)
    case "monochrome":
      return monochromeVariant(of: color)
    default:
      return color
    }
  }

  static func colorfulVariant(of color: Color) -> Color {
    switch color {
    case .blue: .red
    case .green: .cyan
    case .orange: .yellow
    case .purple: .pink
    default: .gray
    }
  }

  static func monochromeVariant(of color: Color) -> Color {
    switch color {
    case .blue: Color(white: 0.2)
    case .green: Color(white: 0.4)
    case .orange: Color(white: 0.6)
    case .purple: Color(white: 0.8)
    default: .gray
    }
  }
}
