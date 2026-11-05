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
    @Published public var latencyMetrics: LatencyMetrics = LatencyMetrics()
    @Published public var throughput: ThroughputMetric = ThroughputMetric()
    @Published public var isConnected: Bool = false
    @Published public var connectionTypeDescription: String = "Detecting Network..."
    @Published public var lastRefreshed: Date = Date()

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

        // Trigger latency test
        Task {
            await self.refreshLatency()
        }
    }

    public func refreshLatency() async {
        let metrics = await LatencyService.shared.checkNetworkLatency(gatewayIP: ipDetails.gatewayIP)
        self.latencyMetrics = metrics
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
            }
        }

        // 2. Wi-Fi RF details every 3s
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isConnected else { return }
                if let (wifi, ip) = WiFiService.shared.fetchCurrentWiFiDetails() {
                    self.wifiDetails = wifi
                    self.ipDetails = ip
                }
            }
        }

        // 3. Battery updates every 3s
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.batteryDetails = BatteryService.shared.fetchBatteryDetails()
            }
        }

        // 4. Latency ping every 5s
        latencyTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isConnected else { return }
                await self.refreshLatency()
            }
        }
    }
}
