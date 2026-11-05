import SwiftUI

public struct BatteryView: View {
    public let battery: BatteryDetails

    public init(battery: BatteryDetails) {
        self.battery = battery
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Main Gauge Card
            mainGaugeCard

            // Health & Specs Card
            healthCard

            // Live Electrical Telemetry Card
            powerDrawCard
        }
    }

    // MARK: - Main Gauge Card
    private var mainGaugeCard: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 10)
                    .frame(width: 100, height: 100)

                // Fill Ring
                Circle()
                    .trim(from: 0.0, to: CGFloat(Double(battery.level) / 100.0))
                    .stroke(
                        battery.batteryColor.gradient,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: battery.level)

                // Center Text
                VStack(spacing: 2) {
                    if battery.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                    }
                    Text("\(battery.level)%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
            }

            VStack(spacing: 3) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(battery.batteryColor)
                        .frame(width: 7, height: 7)
                    Text(battery.statusDescription)
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(battery.formattedTimeRemaining)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Health Card
    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Battery Health & Longevity", systemImage: "heart.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.pink)

            HStack(spacing: 10) {
                specItem(
                    title: "Max Capacity",
                    value: "\(battery.healthPercentage)%",
                    subtitle: "Original capacity",
                    icon: "percent"
                )

                Divider().frame(height: 38)

                specItem(
                    title: "Cycle Count",
                    value: "\(battery.cycleCount)",
                    subtitle: "Rated for 1,000",
                    icon: "arrow.triangle.2.circlepath"
                )

                Divider().frame(height: 38)

                if let temp = battery.temperatureCelsius {
                    specItem(
                        title: "Temperature",
                        value: String(format: "%.1f°C", temp),
                        subtitle: temp < 38.0 ? "Cool & Normal" : "Warm",
                        icon: "thermometer.medium",
                        valueColor: temp < 38.0 ? .primary : (temp < 45.0 ? .orange : .red)
                    )

                    Divider().frame(height: 38)
                }

                specItem(
                    title: "Condition",
                    value: battery.condition,
                    subtitle: "macOS status",
                    icon: "checkmark.seal.fill"
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

    // MARK: - Power Draw Card
    private var powerDrawCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Power & Electrical Sensors", systemImage: "bolt.badge.automatic.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.orange)

            HStack(spacing: 12) {
                if let watts = battery.powerDrawWatts {
                    specItem(
                        title: "Power Draw",
                        value: String(format: "%.1f W", watts),
                        subtitle: battery.isCharging ? "Charging rate" : "Discharge rate",
                        icon: "bolt.fill"
                    )
                    Divider().frame(height: 38)
                }

                if let v = battery.voltageVolts {
                    specItem(
                        title: "Voltage",
                        value: String(format: "%.2f V", v),
                        subtitle: "Pack potential",
                        icon: "waveform.path"
                    )
                    Divider().frame(height: 38)
                }

                if let a = battery.amperageMilliAmps {
                    specItem(
                        title: "Current",
                        value: "\(a) mA",
                        subtitle: a < 0 ? "Drain" : "Charge",
                        icon: "arrow.left.and.right"
                    )
                }
            }

            // Power Mode Pill
            HStack {
                Text("Power Source: ")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(battery.powerSource)
                    .font(.system(size: 11, weight: .semibold))

                Spacer()

                if battery.isLowPowerMode {
                    Text("Low Power Mode: ON")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            .padding(.top, 4)
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

    private func specItem(title: String, value: String, subtitle: String, icon: String, valueColor: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

