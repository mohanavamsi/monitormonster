import SwiftUI
import AppKit

public struct DashboardView: View {
    @ObservedObject var state = AppState.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            Divider()

            // MARK: - Main Content Area
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 14) {
                    // 2-Tab Segmented Switcher
                    Picker("", selection: $state.selectedTab) {
                        Text("📶 Wi-Fi & Network").tag(0)
                        Text("🔋 Battery & Power").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 4)

                    if state.selectedTab == 0 {
                        overviewTabContent
                    } else {
                        BatteryView(battery: state.batteryDetails)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // MARK: - Footer
            footerBar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .frame(width: 420, height: 540)
        .background(VisualEffectView().ignoresSafeArea())
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            GlowingMonsterBallView(size: 34)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("MonitorMonster")
                        .font(.system(size: 15, weight: .bold))
                    Text("v1.0")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(state.isConnected ? Color.green : Color.red)
                        .frame(width: 7, height: 7)
                    Text(state.isConnected ? state.wifiDetails.ssid : "Not Connected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Refresh Button
            Button(action: {
                state.refreshAll()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .padding(6)
            .background(Color.primary.opacity(0.06))
            .clipShape(Circle())
            .help("Refresh metrics")
        }
    }

    // MARK: - Overview Tab
    private var overviewTabContent: some View {
        VStack(spacing: 14) {
            signalCard
            LatencyCardView(metrics: state.latencyMetrics)
            ThroughputBadgeView(
                throughput: state.throughput,
                downloadHistory: state.downloadHistory,
                uploadHistory: state.uploadHistory
            )
            networkDetailsCard
        }
    }

    // MARK: - Signal Card
    private var signalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                SignalGaugeView(rssi: state.wifiDetails.rssi, quality: state.wifiDetails.quality)

                VStack(spacing: 8) {
                    HStack {
                        metricItem(title: "Noise Floor", value: "\(state.wifiDetails.noise) dBm", icon: "waveform.badge.minus")
                        Spacer()
                        metricItem(title: "SNR Quality", value: "\(state.wifiDetails.snr) dB", icon: "arrow.up.right.circle")
                    }

                    HStack {
                        metricItem(title: "Tx Rate", value: String(format: "%.0f Mbps", state.wifiDetails.txRate), icon: "bolt.fill")
                        Spacer()
                        metricItem(title: "Security", value: state.wifiDetails.security, icon: "lock.shield.fill")
                    }
                }
            }

            HStack(spacing: 6) {
                chipBadge(state.wifiDetails.band, icon: "wave.3.forward")
                chipBadge("Ch \(state.wifiDetails.channel)", icon: "number")
                chipBadge(state.wifiDetails.channelWidth, icon: "arrow.left.and.right")
                chipBadge(state.wifiDetails.phyMode, icon: "wifi")
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func metricItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.accentColor)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
        }
    }

    private func chipBadge(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.06))
        .cornerRadius(6)
        .lineLimit(1)
    }

    // MARK: - Network Details Card
    private var networkDetailsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NETWORK CONFIGURATION")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            VStack(spacing: 6) {
                detailRow(label: "MacBook IP", value: state.ipDetails.localIPv4, copyable: true)
                detailRow(label: "Router / Gateway", value: state.ipDetails.gatewayIP, copyable: true)
                detailRow(label: "Subnet Mask", value: state.ipDetails.subnetMask, copyable: false)
                detailRow(label: "BSSID (AP MAC)", value: state.wifiDetails.bssid, copyable: true)
                if !state.ipDetails.dnsServers.isEmpty {
                    detailRow(label: "DNS Servers", value: state.ipDetails.dnsServers.joined(separator: ", "), copyable: false)
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func detailRow(label: String, value: String, copyable: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .lineLimit(1)

            if copyable && value != "N/A" {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    state.copiedText = label
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if state.copiedText == label { state.copiedText = nil }
                    }
                }) {
                    Image(systemName: state.copiedText == label ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(state.copiedText == label ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }
        }
    }

    // MARK: - Footer Bar
    private var footerBar: some View {
        HStack {
            Text("Auto-refresh active")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()

            Button("Quit MonitorMonster") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
        }
    }
}

// Visual Effect View for macOS vibrancy
public struct VisualEffectView: NSViewRepresentable {
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .popover
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Glowing Monster Ball View (Icon with two cute eyes)
public struct GlowingMonsterBallView: View {
    public var size: CGFloat = 34

    public init(size: CGFloat = 34) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Ambient outer glow
            Circle()
                .fill(RadialGradient(
                    colors: [Color.cyan.opacity(0.85), Color.purple.opacity(0.35), Color.clear],
                    center: .center,
                    startRadius: 2,
                    endRadius: size * 0.72
                ))
                .frame(width: size * 1.35, height: size * 1.35)

            // Monster Ball body with electric gradient
            Circle()
                .fill(LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.85, blue: 0.95), // Electric Cyan
                        Color(red: 0.6, green: 0.25, blue: 0.95)  // Neon Purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1.2)
                )
                .shadow(color: Color.cyan.opacity(0.8), radius: 6, x: 0, y: 0)

            // Two cute eyes
            HStack(spacing: size * 0.14) {
                eye(size: size)
                eye(size: size)
            }
            .offset(y: -size * 0.03)
        }
    }

    private func eye(size: CGFloat) -> some View {
        ZStack {
            // White eyeball
            Capsule()
                .fill(Color.white)
                .frame(width: size * 0.18, height: size * 0.28)
                .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)

            // Dark pupil
            Circle()
                .fill(Color(red: 0.08, green: 0.05, blue: 0.2))
                .frame(width: size * 0.11, height: size * 0.11)
                .offset(y: -size * 0.03)

            // Tiny catchlight glint
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.045, height: size * 0.045)
                .offset(x: -size * 0.025, y: -size * 0.05)
        }
    }
}
