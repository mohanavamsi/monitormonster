import SwiftUI

public struct SignalGaugeView: View {
    public let rssi: Int
    public let quality: WiFiQuality

    public init(rssi: Int, quality: WiFiQuality) {
        self.rssi = rssi
        self.quality = quality
    }

    // Normalized progress: -100 dBm (0%) to -40 dBm (100%)
    private var progress: Double {
        if rssi >= -40 { return 1.0 }
        if rssi <= -100 { return 0.0 }
        return Double(rssi - (-100)) / 60.0
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 9)
                    .frame(width: 86, height: 86)

                // Foreground Ring
                Circle()
                    .trim(from: 0.0, to: CGFloat(max(0.05, progress)))
                    .stroke(
                        quality.color.gradient,
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 86, height: 86)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

                // Value Text inside ring
                VStack(spacing: 1) {
                    Text("\(rssi)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("dBm")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Text(quality.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(quality.color)
        }
    }
}

