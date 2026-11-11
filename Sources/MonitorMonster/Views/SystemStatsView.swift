import SwiftUI

public struct SystemStatsView: View {
    public let stats: SystemStats

    public init(stats: SystemStats) {
        self.stats = stats
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Dual Ring Gauge Card (CPU & RAM)
            dualGaugeCard

            // CPU Breakdown Card
            cpuDetailsCard

            // Memory Breakdown Card
            memoryDetailsCard
        }
    }

    // MARK: - Dual Ring Gauges (CPU & RAM Side-by-Side)
    private var dualGaugeCard: some View {
        HStack(spacing: 14) {
            // CPU Gauge
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 8)
                        .frame(width: 82, height: 82)

                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(1.0, stats.cpuTotalPercent / 100.0)))
                        .stroke(
                            stats.cpuStatusColor.gradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 82, height: 82)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stats.cpuTotalPercent)

                    VStack(spacing: 0) {
                        Image(systemName: "cpu")
                            .font(.system(size: 11))
                            .foregroundColor(stats.cpuStatusColor)
                        Text("\(Int(stats.cpuTotalPercent.rounded()))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                }

                VStack(spacing: 2) {
                    Text("CPU Load")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(stats.coreCount) Cores Active")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            // RAM Memory Gauge
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 8)
                        .frame(width: 82, height: 82)

                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(1.0, stats.memoryPercentage / 100.0)))
                        .stroke(
                            stats.memoryStatusColor.gradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 82, height: 82)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stats.memoryPercentage)

                    VStack(spacing: 0) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 11))
                            .foregroundColor(stats.memoryStatusColor)
                        Text("\(Int(stats.memoryPercentage.rounded()))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                }

                VStack(spacing: 2) {
                    Text("Memory (RAM)")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(String(format: "%.1f", stats.usedMemoryGB)) / \(String(format: "%.1f", stats.totalMemoryGB)) GB")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - CPU Details Card
    private var cpuDetailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "gauge.with.needle")
                    .foregroundColor(.cyan)
                    .font(.system(size: 12))
                Text("Processor Diagnostics")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(stats.cpuTotalPercent >= 80 ? "Heavy Load 🔥" : (stats.cpuTotalPercent < 15 ? "Cool & Chill 🧊" : "Normal ⚡"))
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(stats.cpuStatusColor.opacity(0.15))
                    .foregroundColor(stats.cpuStatusColor)
                    .cornerRadius(4)
            }

            Divider()

            HStack(spacing: 12) {
                metricItem(
                    title: "User Load",
                    value: String(format: "%.1f%%", stats.cpuUserPercent),
                    subtitle: "Apps & UI",
                    color: .cyan
                )
                Divider().frame(height: 36)
                metricItem(
                    title: "System Load",
                    value: String(format: "%.1f%%", stats.cpuSystemPercent),
                    subtitle: "macOS Kernel",
                    color: .blue
                )
                Divider().frame(height: 36)
                metricItem(
                    title: "Available",
                    value: String(format: "%.1f%%", max(0.0, 100.0 - stats.cpuTotalPercent)),
                    subtitle: "Idle Headroom",
                    color: .green
                )
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Memory Details Card
    private var memoryDetailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(.purple)
                    .font(.system(size: 12))
                Text("Memory Composition")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(pressureColor)
                        .frame(width: 6, height: 6)
                    Text("Pressure: \(stats.memoryPressure)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(pressureColor)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(pressureColor.opacity(0.12))
                .cornerRadius(4)
            }

            Divider()

            HStack(spacing: 12) {
                metricItem(
                    title: "App Memory",
                    value: "\(String(format: "%.1f", stats.appMemoryGB)) GB",
                    subtitle: "Running Apps",
                    color: .purple
                )
                Divider().frame(height: 36)
                metricItem(
                    title: "Wired",
                    value: "\(String(format: "%.1f", stats.wiredMemoryGB)) GB",
                    subtitle: "OS Core",
                    color: .indigo
                )
                Divider().frame(height: 36)
                metricItem(
                    title: "Compressed",
                    value: "\(String(format: "%.1f", stats.compressedMemoryGB)) GB",
                    subtitle: "Fast Swapped",
                    color: .secondary
                )
            }

            // Simple informative tip
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text("macOS actively caches memory for faster app switching.")
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var pressureColor: Color {
        switch stats.memoryPressure {
        case "Critical": return .red
        case "Moderate": return .orange
        default: return .green
        }
    }

    private func metricItem(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
