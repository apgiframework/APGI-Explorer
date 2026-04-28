import Foundation

// MARK: - Chart Data Models

struct ChartDataPoint: Identifiable, Equatable {
  let id = UUID()
  let parameter: String
  let value: Double
  let profileName: String
}

struct HistoricalDataPoint: Identifiable, Equatable {
  let id = UUID()
  let date: Date
  let epsilon: Double
  let precision: Double
  let threshold: Double
  let somaticBias: Double
}
