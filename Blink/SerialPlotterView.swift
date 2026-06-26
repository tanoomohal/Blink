import SwiftUI
import Charts

struct SerialPlotterView: View {
    @ObservedObject var serialMonitor: SerialMonitorConnection
    
    var body: some View {
        VStack {
            if serialMonitor.plotterData.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Waiting for numerical data...")
                        .foregroundColor(.secondary)
                    
                    Text("Print comma-separated numbers (e.g., Serial.println(\"10, 20\"))")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
            } else {
                Chart(serialMonitor.plotterData) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                }
                .chartXAxis(.hidden)
                .padding()
                .background(Theme.background)
            }
        }
    }
}
