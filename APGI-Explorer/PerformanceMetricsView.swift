import SwiftUI

struct PerformanceMetricsView: View {
    @AppStorage("showPerformanceMetrics") private var showPerformanceMetrics: Bool = false
    
    let frameRate: Double
    let memoryUsage: UInt64
    let cpuUsage: Double
    
    var body: some View {
        if showPerformanceMetrics {
            VStack(alignment: .leading, spacing: 4) {
                Text("Performance Metrics")
                    .font(.caption)
                    .fontWeight(.bold)
                
                HStack {
                    Text("FPS: \(String(format: "%.1f", frameRate))")
                    Spacer()
                    Text("Memory: \(formatMemory(memoryUsage))")
                    Spacer()
                    Text("CPU: \(String(format: "%.1f", cpuUsage))%")
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
        let mb = Double(bytes) / (1024 * 1024)
        if mb < 1024 {
            return "\(String(format: "%.1f", mb)) MB"
        } else {
            return "\(String(format: "%.1f", mb / 1024)) GB"
        }
    }
}
