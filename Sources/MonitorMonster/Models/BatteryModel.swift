import Foundation
import SwiftUI

public struct BatteryDetails: Sendable {
    public var level: Int
    public var isCharging: Bool
    public var isPluggedIn: Bool
    public var powerSource: String
    public var healthPercentage: Int
    public var condition: String
    public var cycleCount: Int
    public var timeRemainingMinutes: Int?
    public var powerDrawWatts: Double?
    public var voltageVolts: Double?
    public var amperageMilliAmps: Int?
    public var temperatureCelsius: Double?
    public var isLowPowerMode: Bool

    public init(
        level: Int = 100,
        isCharging: Bool = false,
        isPluggedIn: Bool = false,
        powerSource: String = "Battery",
        healthPercentage: Int = 100,
        condition: String = "Normal",
        cycleCount: Int = 0,
        timeRemainingMinutes: Int? = nil,
        powerDrawWatts: Double? = nil,
        voltageVolts: Double? = nil,
        amperageMilliAmps: Int? = nil,
        temperatureCelsius: Double? = nil,
        isLowPowerMode: Bool = false
    ) {
        self.level = level
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.powerSource = powerSource
        self.healthPercentage = healthPercentage
        self.condition = condition
        self.cycleCount = cycleCount
        self.timeRemainingMinutes = timeRemainingMinutes
        self.powerDrawWatts = powerDrawWatts
        self.voltageVolts = voltageVolts
        self.amperageMilliAmps = amperageMilliAmps
        self.temperatureCelsius = temperatureCelsius
        self.isLowPowerMode = isLowPowerMode
    }

    public var statusDescription: String {
        if isCharging {
            return "Charging"
        } else if isPluggedIn {
            return "Fully Charged (AC Connected)"
        } else {
            return "On Battery"
        }
    }

    public var formattedTimeRemaining: String {
        guard let mins = timeRemainingMinutes, mins > 0 else {
            if isCharging { return "Calculating charge time..." }
            if isPluggedIn { return "Power Adapter Connected" }
            return "Calculating..."
        }
        let hours = mins / 60
        let remainder = mins % 60
        if hours > 0 {
            return "\(hours)h \(remainder)m remaining"
        } else {
            return "\(remainder)m remaining"
        }
    }

    public var batteryColor: Color {
        if isCharging { return .green }
        if level <= 15 { return .red }
        if level <= 30 { return .orange }
        return .green
    }
}

