import SwiftUI

public struct ThroughputBadgeView: View {
    public let throughput: ThroughputMetric
    public let downloadHistory: [Double]
    public let uploadHistory: [Double]

    public init(throughput: ThroughputMetric, downloadHistory: [Double], uploadHistory: [Double]) {
        self.throughput = throughput
        self.downloadHistory = downloadHistory
        self.uploadHistory = uploadHistory
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Download Speed
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Download")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(throughput.downloadSpeedFormatted)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }

                Spacer()
                MiniSparkline(data: downloadHistory, tint: .cyan)
                    .frame(width: 48, height: 22)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            // Upload Speed
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Upload")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(throughput.uploadSpeedFormatted)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }

                Spacer()
                MiniSparkline(data: uploadHistory, tint: .purple)
                    .frame(width: 48, height: 22)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

private struct MiniSparkline: View {
    let data: [Double]
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let maxVal = max(data.max() ?? 1.0, 1.0)
            let step = geo.size.width / CGFloat(max(data.count - 1, 1))

            Path { path in
                for (i, val) in data.enumerated() {
                    let y = geo.size.height - (CGFloat(val / maxVal) * (geo.size.height - 4)) - 2
                    let x = CGFloat(i) * step
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
        }
    }
}

