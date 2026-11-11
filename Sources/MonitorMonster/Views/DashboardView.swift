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
            GlowingMonsterBallView(
                mood: state.currentMood,
                isBlinking: state.isBlinking,
                isPoked: state.isMonsterPoked,
                size: 36
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("MonitorMonster")
                        .font(.system(size: 15, weight: .bold))
                    Text("v1.0")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text("by itvizag")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.85))

                    // Live Mood Status Pill
                    HStack(spacing: 3) {
                        Text(state.currentMood.emoji)
                            .font(.system(size: 10))
                        Text(state.currentMood.title)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(state.currentMood.moodColor)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(state.currentMood.moodColor.opacity(0.14))
                    .clipShape(Capsule())
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(state.isConnected ? Color.green : Color.red)
                        .frame(width: 7, height: 7)
                    Text(state.isConnected ? state.wifiDetails.ssid : "Not Connected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if state.isConnected && state.wifiDetails.isRedactedByMacOS {
                        Button(action: {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Apple masks exact Wi-Fi names when Location Services is turned off. Click to view Privacy & Security settings.")
                    }
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
            HStack(spacing: 4) {
                Text("Crafted with")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("❤️")
                    .font(.system(size: 9))
                Text("by")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Button(action: {
                    if let url = URL(string: "https://itvizag.com") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("itvizag")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.accentColor)
                }
                .buttonStyle(.plain)
                .help("Visit itvizag.com")

                Text("•")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))

                Text("Auto-refresh")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

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

// MARK: - Glowing Monster Ball View (Living, Reactive, Animated)
public struct GlowingMonsterBallView: View {
    public var mood: MonsterMood
    public var isBlinking: Bool
    public var isPoked: Bool
    public var size: CGFloat

    public init(mood: MonsterMood = .chill, isBlinking: Bool = false, isPoked: Bool = false, size: CGFloat = 34) {
        self.mood = mood
        self.isBlinking = isBlinking
        self.isPoked = isPoked
        self.size = size
    }

    public var body: some View {
        Button(action: {
            AppState.shared.pokeMonster()
        }) {
            ZStack {
                // 1. Ambient Living Glow
                Circle()
                    .fill(RadialGradient(
                        colors: [
                            mood.gradientColors.first?.opacity(0.8) ?? Color.cyan.opacity(0.8),
                            mood.gradientColors.last?.opacity(0.25) ?? Color.purple.opacity(0.25),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: size * 0.75
                    ))
                    .frame(width: size * 1.4, height: size * 1.4)

                // 2. Glowing Orb Body
                Circle()
                    .fill(LinearGradient(
                        colors: mood.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1.2)
                    )
                    .shadow(color: mood.moodColor.opacity(0.7), radius: 6, x: 0, y: 0)

                // 3. Cheeks for Happy mood
                if mood == .happy {
                    HStack(spacing: size * 0.44) {
                        Circle()
                            .fill(Color.pink.opacity(0.6))
                            .frame(width: size * 0.12, height: size * 0.08)
                        Circle()
                            .fill(Color.pink.opacity(0.6))
                            .frame(width: size * 0.12, height: size * 0.08)
                    }
                    .offset(y: size * 0.16)
                }

                // 4. Two Expressive Eyes
                HStack(spacing: size * 0.14) {
                    eyeView(isLeft: true)
                    eyeView(isLeft: false)
                }
                .offset(y: -size * 0.03)
            }
            .scaleEffect(isPoked ? 1.2 : 1.0)
        }
        .buttonStyle(.plain)
        .help("MonitorMonster: \(mood.title) (Click to poke!)")
    }

    @ViewBuilder
    private func eyeView(isLeft: Bool) -> some View {
        let isClosed = isBlinking || (isPoked && isLeft) || mood == .sleepy

        if isClosed {
            // Blinking, Winking, or Sleepy closed eye
            Capsule()
                .fill(Color.white)
                .frame(width: size * 0.20, height: 2.4)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
        } else if mood == .fever || mood == .laggy {
            // Squinty / Strained angled eyes (> <)
            Image(systemName: isLeft ? "chevron.right" : "chevron.left")
                .font(.system(size: size * 0.22, weight: .black))
                .foregroundColor(.white)
        } else if mood == .offline {
            // Surprised wide hollow eyes (O O)
            Circle()
                .stroke(Color.white, lineWidth: 2.0)
                .frame(width: size * 0.22, height: size * 0.22)
                .overlay(
                    Circle()
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.25))
                        .frame(width: size * 0.08, height: size * 0.08)
                )
        } else {
            // Cute living eye with pupil & catchlight
            ZStack {
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.18, height: size * 0.28)
                    .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)

                // Dark pupil
                Circle()
                    .fill(Color(red: 0.08, green: 0.05, blue: 0.2))
                    .frame(width: size * 0.11, height: size * 0.11)
                    .offset(y: -size * 0.03)

                // Cute catchlight glint
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.045, height: size * 0.045)
                    .offset(x: -size * 0.025, y: -size * 0.05)
            }
        }
    }
}
