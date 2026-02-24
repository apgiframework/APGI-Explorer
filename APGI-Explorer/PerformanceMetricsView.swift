import SwiftUI

struct PerformanceMetricsView: View {
    @AppStorage("showPerformanceMetrics") private var showPerformanceMetrics: Bool = false

    let frameRate: Double
    let memoryUsage: UInt64
    let cpuUsage: Double

    var body: some View {
        if self.showPerformanceMetrics {
            VStack(alignment: .leading, spacing: 4) {
                Text("Performance Metrics")
                    .font(.caption)
                    .fontWeight(.bold)

                HStack {
                    Text("FPS: \(String(format: "%.1f", self.frameRate))")
                    Spacer()
                    Text("Memory: \(self.formatMemory(self.memoryUsage))")
                    Spacer()
                    Text("CPU: \(String(format: "%.1f", self.cpuUsage))%")
                }
                .font(.system(size: 10, design: .monospaced))
            }
            .padding(8)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.green)
            .cornerRadius(8)
            .padding(8)
        }
    }

    private func formatMemory(_ bytes: UInt64) -> String {
        let megabytes = Double(bytes) / (1024 * 1024)
        if megabytes < 1024 {
            return "\(String(format: "%.1f", megabytes)) MB"
        } else {
            return "\(String(format: "%.1f", megabytes / 1024)) GB"
        }
    }
}
