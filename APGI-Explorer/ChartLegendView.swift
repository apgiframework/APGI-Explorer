import SwiftUI

// MARK: - Chart Legend View

struct LegendItem: View {
  let color: Color
  let label: String

  var body: some View {
    HStack(spacing: 4) {
      Rectangle()
        .fill(self.color)
        .frame(width: 12, height: 12)
      Text(self.label)
        .font(.caption)
    }
  }
}
