import Foundation
import SwiftUI
import Combine
import Network

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public var wifiDetails: WiFiDetails = WiFiDetails()
    @Published public var ipDetails: IPDetails = IPDetails()
    @Published public var batteryDetails: BatteryDetails = BatteryDetails()
    @Published public var systemStats: SystemStats = SystemStats()
    @Published public var latencyMetrics: LatencyMetrics = LatencyMetrics()
    @Published public var throughput: ThroughputMetric = ThroughputMetric()
    @Published public var isConnected: Bool = false
    @Published public var connectionTypeDescription: String = "Detecting Network..."
    @Published public var lastRefreshed: Date = Date()

    // The Monster's Personality & Mood
    @Published public var currentMood: MonsterMood = .chill
    @Published public var isBlinking: Bool = false
    @Published public var isMonsterPoked: Bool = false

    // History for throughput mini-sparkline
    @Published public var downloadHistory: [Double] = Array(repeating: 0.0, count: 20)
    @Published public var uploadHistory: [Double] = Array(repeating: 0.0, count: 20)

    // UI state
    @Published public var copiedText: String? = nil
    @Published public var selectedTab: Int = 0 // 0: Network, 1: Battery

    private var throughputTimer: Timer?
    private var metricsTimer: Timer?
    private var latencyTimer: Timer?
    private var batteryTimer: Timer?
    private var systemTimer: Timer?
    private var blinkTimer: Timer?

    private init() {
        setupNetworkObserver()
        refreshAll()
        startTimers()
    }

    private func setupNetworkObserver() {
        NetworkPathMonitor.shared.onNetworkChanged = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(path)
            }
        }
        NetworkPathMonitor.shared.start()
    }

    private func handlePathUpdate(_ path: NWPath) {
        if path.status == .satisfied {
            isConnected = true
            if path.usesInterfaceType(.wifi) {
                connectionTypeDescription = "Wi-Fi Connected"
            } else if path.usesInterfaceType(.wiredEthernet) {
                connectionTypeDescription = "Ethernet Connected"
            } else if path.usesInterfaceType(.cellular) {
                connectionTypeDescription = "Personal Hotspot"
            } else {
                connectionTypeDescription = "Network Connected"
            }
        } else {
            isConnected = false
            connectionTypeDescription = "Offline / No Connection"
        }
        refreshAll()
    }

    public func refreshAll() {
        lastRefreshed = Date()

        if let (wifi, ip) = WiFiService.shared.fetchCurrentWiFiDetails() {
            self.wifiDetails = wifi
            self.ipDetails = ip
            self.isConnected = (ip.localIPv4 != "N/A" && !ip.localIPv4.isEmpty) || (wifi.rssi != 0)
        } else {
            self.isConnected = false
        }

        // Fetch Battery
        self.batteryDetails = BatteryService.shared.fetchBatteryDetails()

        // Fetch CPU & Memory System Stats
        self.systemStats = SystemStatsService.shared.sample()

        // Update Mood
        updateMood()

        // Trigger latency test
        Task {
            await self.refreshLatency()
            self.updateMood()
        }
    }

    public func refreshLatency() async {
        let metrics = await LatencyService.shared.checkNetworkLatency(gatewayIP: ipDetails.gatewayIP)
        self.latencyMetrics = metrics
        self.updateMood()
    }

    public func updateMood() {
        if !isConnected {
            currentMood = .offline
            return
        }
        if systemStats.cpuTotalPercent >= 85.0 || systemStats.memoryPressure == "Critical" {
            currentMood = .fever
            return
        }
        if let temp = batteryDetails.temperatureCelsius, temp >= 38.8 {
            currentMood = .fever
            return
        }
        if let rLat = latencyMetrics.routerLatencyMs, rLat >= 85.0 {
            currentMood = .laggy
            return
        }
        if let iLat = latencyMetrics.internetLatencyMs, iLat >= 140.0 {
            currentMood = .laggy
            return
        }
        if throughput.bytesInPerSec > 1.2 * 1024 * 1024 || batteryDetails.isCharging {
            currentMood = .happy
            return
        }
        if let watts = batteryDetails.powerDrawWatts, watts < 5.5 && !batteryDetails.isCharging && systemStats.cpuTotalPercent < 15.0 {
            currentMood = .sleepy
            return
        }
        currentMood = .chill
    }

    public func pokeMonster() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            isMonsterPoked = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.isMonsterPoked = false
            }
        }
    }

    private func startTimers() {
        // 1. Live Throughput (1s)
        throughputTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let metric = ThroughputService.shared.sample(interfaceName: self.wifiDetails.interfaceName)
                self.throughput = metric

                self.downloadHistory.removeFirst()
                self.downloadHistory.append(metric.bytesInPerSec)

                self.uploadHistory.removeFirst()
                self.uploadHistory.append(metric.bytesOutPerSec)

                self.updateMood()
            }
        }

        // 2. Wi-Fi RF details every 3s
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isConnected else { return }
                if let (wifi, ip) = WiFiService.shared.fetchCurrentWiFiDetails() {
                    self.wifiDetails = wifi
                    self.ipDetails = ip
                    self.updateMood()
                }
            }
        }

        // 3. Battery updates every 3s
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.batteryDetails = BatteryService.shared.fetchBatteryDetails()
                self.updateMood()
            }
        }

        // 4. CPU & RAM updates every 2s
        systemTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.systemStats = SystemStatsService.shared.sample()
                self.updateMood()
            }
        }

        // 4. Latency ping every 5s
        latencyTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isConnected else { return }
                await self.refreshLatency()
            }
        }

        // 5. Natural Eye Blink Timer (every 3.8s, quick 150ms blink)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 3.8, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isBlinking = true
                try? await Task.sleep(nanoseconds: 150_000_000)
                self.isBlinking = false
            }
        }
    }
}
