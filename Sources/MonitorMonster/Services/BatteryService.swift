import Foundation
import IOKit.ps

public final class BatteryService: @unchecked Sendable {
    public static let shared = BatteryService()

    private var cachedHealth: (health: Int, cycle: Int, condition: String) = (97, 64, "Normal")
    private var lastHealthCheck: CFAbsoluteTime = 0
    private let lock = NSLock()

    private init() {}

    public func fetchBatteryDetails() -> BatteryDetails {
        var level = 100
        var isCharging = false
        var isPluggedIn = false
        var powerSource = "Battery"
        var timeRemainingMins: Int? = nil
        var isLowPowerMode = false

        // 1. Fast IOKit Power Sources API
        if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] {
            for source in sources {
                if let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                    if let curCap = desc[kIOPSCurrentCapacityKey as String] as? Int {
                        level = curCap
                    }
                    if let charging = desc[kIOPSIsChargingKey as String] as? Bool {
                        isCharging = charging
                    }
                    if let psState = desc[kIOPSPowerSourceStateKey as String] as? String {
                        isPluggedIn = (psState == kIOPSACPowerValue as String)
                        powerSource = isPluggedIn ? "AC Power" : "Battery Power"
                    }
                    if let timeEmpty = desc[kIOPSTimeToEmptyKey as String] as? Int, timeEmpty > 0 {
                        timeRemainingMins = timeEmpty
                    } else if let timeFull = desc[kIOPSTimeToFullChargeKey as String] as? Int, timeFull > 0 {
                        timeRemainingMins = timeFull
                    }
                    if let lpm = desc["LPM Active"] as? Int {
                        isLowPowerMode = (lpm == 1)
                    }
                }
            }
        }

        // 2. Hardware telemetry (Cycle count, Voltage, Amperage, Health, Temperature)
        let (voltage, amperage, powerWatts, tempC) = readHardwarePowerMetrics()
        let (health, cycleCount, condition) = readHealthMetrics()

        return BatteryDetails(
            level: level,
            isCharging: isCharging,
            isPluggedIn: isPluggedIn,
            powerSource: powerSource,
            healthPercentage: health,
            condition: condition,
            cycleCount: cycleCount,
            timeRemainingMinutes: timeRemainingMins,
            powerDrawWatts: powerWatts,
            voltageVolts: voltage,
            amperageMilliAmps: amperage,
            temperatureCelsius: tempC,
            isLowPowerMode: isLowPowerMode
        )
    }

    private func readHardwarePowerMetrics() -> (voltage: Double?, amperage: Int?, powerWatts: Double?, tempCelsius: Double?) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
        process.arguments = ["-c", "AppleSmartBattery", "-r", "-w", "0"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        var voltageV: Double? = nil
        var amperageMA: Int? = nil
        var watts: Double? = nil
        var tempC: Double? = nil

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Read Voltage
                let regexVoltage = try? NSRegularExpression(pattern: "\"Voltage\"\\s*=\\s*([0-9]+)")
                let range = NSRange(output.startIndex..<output.endIndex, in: output)
                if let match = regexVoltage?.firstMatch(in: output, range: range),
                   let r = Range(match.range(at: 1), in: output),
                   let mv = Double(output[r]) {
                    voltageV = mv / 1000.0
                }

                // Read Amperage
                let regexAmp = try? NSRegularExpression(pattern: "\"Amperage\"\\s*=\\s*([0-9]+)")
                if let match = regexAmp?.firstMatch(in: output, range: range),
                   let r = Range(match.range(at: 1), in: output),
                   let raw = UInt64(output[r]) {
                    let signed = Int64(bitPattern: raw)
                    amperageMA = Int(signed)
                }

                // Read Temperature (centi-degrees Celsius, e.g. 3479 = 34.79°C)
                let regexTemp = try? NSRegularExpression(pattern: "\"Temperature\"\\s*=\\s*([0-9]+)")
                if let match = regexTemp?.firstMatch(in: output, range: range),
                   let r = Range(match.range(at: 1), in: output),
                   let rawTemp = Double(output[r]), rawTemp > 0 {
                    tempC = rawTemp / 100.0
                }

                if let v = voltageV, let a = amperageMA {
                    let currentA = abs(Double(a)) / 1000.0
                    watts = currentA * v
                }
            }
        } catch {
            // ignore
        }

        // If AppleSmartBattery didn't include temperature, try AppleSmartBatteryPack
        if tempC == nil {
            tempC = fetchBatteryPackTemperature()
        }

        return (voltageV, amperageMA, watts, tempC)
    }

    private func fetchBatteryPackTemperature() -> Double? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
        process.arguments = ["-c", "AppleSmartBatteryPack", "-r", "-w", "0"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let regexTemp = try? NSRegularExpression(pattern: "\"Temperature\"\\s*=\\s*([0-9]+)")
                let range = NSRange(output.startIndex..<output.endIndex, in: output)
                if let match = regexTemp?.firstMatch(in: output, range: range),
                   let r = Range(match.range(at: 1), in: output),
                   let rawTemp = Double(output[r]), rawTemp > 0 {
                    return rawTemp / 100.0
                }
            }
        } catch {
            // ignore
        }
        return nil
    }

    private func readHealthMetrics() -> (health: Int, cycle: Int, condition: String) {
        lock.lock()
        defer { lock.unlock() }

        let now = CFAbsoluteTimeGetCurrent()
        // Cache health query for 60 seconds since it changes very slowly
        if now - lastHealthCheck < 60.0 {
            return cachedHealth
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPPowerDataType"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        var health = cachedHealth.health
        var cycle = cachedHealth.cycle
        var condition = cachedHealth.condition

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.starts(with: "Cycle Count:") {
                        let val = trimmed.replacingOccurrences(of: "Cycle Count:", with: "").trimmingCharacters(in: .whitespaces)
                        if let c = Int(val) { cycle = c }
                    } else if trimmed.starts(with: "Condition:") {
                        condition = trimmed.replacingOccurrences(of: "Condition:", with: "").trimmingCharacters(in: .whitespaces)
                    } else if trimmed.starts(with: "Maximum Capacity:") {
                        let val = trimmed.replacingOccurrences(of: "Maximum Capacity:", with: "")
                            .replacingOccurrences(of: "%", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        if let h = Int(val) { health = h }
                    }
                }
                cachedHealth = (health, cycle, condition)
                lastHealthCheck = now
            }
        } catch {
            // ignore
        }

        return cachedHealth
    }
}

