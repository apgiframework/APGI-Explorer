import Foundation

// MARK: - Comparison Data Structures

struct ComparisonData: Hashable {
  let profile1: QuizProfile?
  let profile2: QuizProfile?
  let mode: ComparisonMode

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.profile1?.id)
    hasher.combine(self.profile2?.id)
    hasher.combine(self.mode)
  }

  static func == (lhs: ComparisonData, rhs: ComparisonData) -> Bool {
    lhs.profile1?.id == rhs.profile1?.id && lhs.profile2?.id == rhs.profile2?.id
      && lhs.mode == rhs.mode
  }
}

// MARK: - Chart Data Models

struct RadarData: Identifiable {
  let id = UUID()
  let category: String
  let value1: Double
  let value2: Double
}

struct BarData: Identifiable {
  let id = UUID()
  let category: String
  let value1: Int
  let value2: Int
}

struct LineData: Identifiable {
  let id = UUID()
  let period: String
  let value1: Int
  let value2: Int
}
