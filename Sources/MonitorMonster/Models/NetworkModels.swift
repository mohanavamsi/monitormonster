import Foundation
import SwiftUI

// MARK: - Wi-Fi Signal Quality
public enum WiFiQuality: String, CaseIterable, Sendable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case weak = "Weak"
    case disconnected = "Disconnected"

    public var color: Color {
        switch self {
        case .excellent: return Color.green
        case .good: return Color.blue
        case .fair: return Color.orange
        case .weak: return Color.red
        case .disconnected: return Color.gray
        }
    }

    public static func from(rssi: Int) -> WiFiQuality {
        if rssi >= -55 { return .excellent }
        if rssi >= -67 { return .good }
        if rssi >= -78 { return .fair }
        return .weak
    }
}

// MARK: - Wi-Fi Physical Link Details
public struct WiFiDetails: Identifiable, Sendable {
    public var id: String { bssid.isEmpty ? ssid : bssid }
    public var ssid: String
    public var bssid: String
    public var interfaceName: String
    public var rssi: Int
    public var noise: Int
    public var snr: Int
    public var txRate: Double
    public var channel: Int
    public var band: String
    public var channelWidth: String
    public var phyMode: String
    public var security: String
    public var isRedactedByMacOS: Bool
    public var quality: WiFiQuality {
        WiFiQuality.from(rssi: rssi)
    }

    public init(
        ssid: String = "Unknown",
        bssid: String = "N/A",
        interfaceName: String = "en0",
        rssi: Int = 0,
        noise: Int = 0,
        snr: Int = 0,
        txRate: Double = 0.0,
        channel: Int = 0,
        band: String = "Unknown",
        channelWidth: String = "Unknown",
        phyMode: String = "Unknown",
        security: String = "Unknown",
        isRedactedByMacOS: Bool = false
    ) {
        self.ssid = ssid
        self.bssid = bssid
        self.interfaceName = interfaceName
        self.rssi = rssi
        self.noise = noise
        self.snr = snr
        self.txRate = txRate
        self.channel = channel
        self.band = band
        self.channelWidth = channelWidth
        self.phyMode = phyMode
        self.security = security
        self.isRedactedByMacOS = isRedactedByMacOS
    }
}

// MARK: - IP & Network Configuration
public struct IPDetails: Sendable {
    public var localIPv4: String
    public var subnetMask: String
    public var gatewayIP: String
    public var dnsServers: [String]
    public var publicIP: String?
    public var leaseExpires: String?

    public init(
        localIPv4: String = "N/A",
        subnetMask: String = "255.255.255.0",
        gatewayIP: String = "N/A",
        dnsServers: [String] = [],
        publicIP: String? = nil,
        leaseExpires: String? = nil
    ) {
        self.localIPv4 = localIPv4
        self.subnetMask = subnetMask
        self.gatewayIP = gatewayIP
        self.dnsServers = dnsServers
        self.publicIP = publicIP
        self.leaseExpires = leaseExpires
    }
}

// MARK: - Latency Diagnostics
public struct LatencyMetrics: Sendable {
    public var routerLatencyMs: Double?
    public var internetLatencyMs: Double?
    public var lastUpdated: Date

    public init(
        routerLatencyMs: Double? = nil,
        internetLatencyMs: Double? = nil,
        lastUpdated: Date = Date()
    ) {
        self.routerLatencyMs = routerLatencyMs
        self.internetLatencyMs = internetLatencyMs
        self.lastUpdated = lastUpdated
    }

    public var diagnosticVerdict: String {
        guard let rLat = routerLatencyMs else {
            return "Checking router connection..."
        }
        guard let iLat = internetLatencyMs else {
            if rLat < 10 {
                return "Wi-Fi to router is pristine (<10ms), but Internet is unreachable."
            } else {
                return "Wi-Fi is experiencing high packet delay to router (\(Int(rLat))ms)."
            }
        }

        if rLat < 5 && iLat < 40 {
            return "Optimal connection! Low latency to both router and internet."
        } else if rLat < 10 && iLat >= 80 {
            return "Wi-Fi link is solid (\(Int(rLat))ms), but ISP/Internet is sluggish (\(Int(iLat))ms)."
        } else if rLat >= 25 {
            return "High Wi-Fi latency to router (\(Int(rLat))ms). Possible RF interference or distance."
        } else {
            return "Connection normal (Router: \(Int(rLat))ms, WAN: \(Int(iLat))ms)."
        }
    }
}

// MARK: - Throughput
public struct ThroughputMetric: Sendable {
    public var bytesInPerSec: Double = 0
    public var bytesOutPerSec: Double = 0

    public var downloadSpeedFormatted: String {
        formatBytes(bytesInPerSec) + "/s"
    }

    public var uploadSpeedFormatted: String {
        formatBytes(bytesOutPerSec) + "/s"
    }

    private func formatBytes(_ bytes: Double) -> String {
        if bytes >= 1024 * 1024 {
            return String(format: "%.1f MB", bytes / (1024 * 1024))
        } else if bytes >= 1024 {
            return String(format: "%.0f KB", bytes / 1024)
        } else {
            return String(format: "%.0f B", bytes)
        }
    }
}

