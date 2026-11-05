import SwiftUI

public struct LatencyCardView: View {
    public let metrics: LatencyMetrics

    public init(metrics: LatencyMetrics) {
        self.metrics = metrics
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Latency Diagnostics", systemImage: "waveform.path.ecg")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Real-Time")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                // Hop 1: Home Router
                LatencyGaugeItem(
                    title: "Home Router",
                    subtitle: "Wi-Fi Hop",
                    icon: "router.fill",
                    latencyMs: metrics.routerLatencyMs
                )

                Divider()
                    .frame(height: 38)

                // Hop 2: Internet / ISP
                LatencyGaugeItem(
                    title: "Internet",
                    subtitle: "WAN Hop (1.1.1.1)",
                    icon: "globe",
                    latencyMs: metrics.internetLatencyMs
                )
            }
            .padding(.vertical, 4)

            // Diagnostic Verdict Summary
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.blue)
                    .padding(.top, 1)
                Text(metrics.diagnosticVerdict)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct LatencyGaugeItem: View {
    let title: String
    let subtitle: String
    let icon: String
    let latencyMs: Double?

    var latencyColor: Color {
        guard let lat = latencyMs else { return .secondary }
        if lat < 15 { return .green }
        if lat < 60 { return .yellow }
        return .red
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(latencyColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let lat = latencyMs {
                Text(String(format: "%.1f ms", lat))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(latencyColor)
            } else {
                Text("--")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

