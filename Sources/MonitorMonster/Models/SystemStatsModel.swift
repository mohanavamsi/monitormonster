import Foundation
import SwiftUI

public struct SystemStats: Sendable {
    // CPU Metrics
    public var cpuTotalPercent: Double
    public var cpuUserPercent: Double
    public var cpuSystemPercent: Double
    public var coreCount: Int

    // RAM Metrics
    public var usedMemoryGB: Double
    public var totalMemoryGB: Double
    public var memoryPercentage: Double
    public var appMemoryGB: Double
    public var wiredMemoryGB: Double
    public var compressedMemoryGB: Double
    public var memoryPressure: String // "Normal", "Moderate", "Critical"

    public init(
        cpuTotalPercent: Double = 0.0,
        cpuUserPercent: Double = 0.0,
        cpuSystemPercent: Double = 0.0,
        coreCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        usedMemoryGB: Double = 0.0,
        totalMemoryGB: Double = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024),
        memoryPercentage: Double = 0.0,
        appMemoryGB: Double = 0.0,
        wiredMemoryGB: Double = 0.0,
        compressedMemoryGB: Double = 0.0,
        memoryPressure: String = "Normal"
    ) {
        self.cpuTotalPercent = cpuTotalPercent
        self.cpuUserPercent = cpuUserPercent
        self.cpuSystemPercent = cpuSystemPercent
        self.coreCount = coreCount
        self.usedMemoryGB = usedMemoryGB
        self.totalMemoryGB = totalMemoryGB
        self.memoryPercentage = memoryPercentage
        self.appMemoryGB = appMemoryGB
        self.wiredMemoryGB = wiredMemoryGB
        self.compressedMemoryGB = compressedMemoryGB
        self.memoryPressure = memoryPressure
    }

    public var cpuStatusColor: Color {
        if cpuTotalPercent >= 85.0 {
            return .red
        } else if cpuTotalPercent >= 60.0 {
            return .orange
        } else {
            return .cyan
        }
    }

    public var memoryStatusColor: Color {
        if memoryPercentage >= 85.0 || memoryPressure == "Critical" {
            return .red
        } else if memoryPercentage >= 70.0 || memoryPressure == "Moderate" {
            return .orange
        } else {
            return .purple
        }
    }
}

