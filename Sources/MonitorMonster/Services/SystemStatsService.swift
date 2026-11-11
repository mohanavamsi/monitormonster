import Foundation
import Darwin
import MachO

public final class SystemStatsService: @unchecked Sendable {
    public static let shared = SystemStatsService()

    private var previousCPUTicks: (user: Double, system: Double, idle: Double, nice: Double)?

    private init() {
        // Prime the initial CPU ticks
        _ = sampleCPU()
    }

    public func sample() -> SystemStats {
        let (cpuTotal, cpuUser, cpuSystem) = sampleCPU()
        let memory = sampleMemory()

        return SystemStats(
            cpuTotalPercent: cpuTotal,
            cpuUserPercent: cpuUser,
            cpuSystemPercent: cpuSystem,
            coreCount: ProcessInfo.processInfo.activeProcessorCount,
            usedMemoryGB: memory.usedGB,
            totalMemoryGB: memory.totalGB,
            memoryPercentage: memory.percentage,
            appMemoryGB: memory.appGB,
            wiredMemoryGB: memory.wiredGB,
            compressedMemoryGB: memory.compressedGB,
            memoryPressure: memory.pressure
        )
    }

    // MARK: - CPU Sampling via Mach Kernel
    private func sampleCPU() -> (total: Double, user: Double, system: Double) {
        var cpuLoadInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return (0.0, 0.0, 0.0)
        }

        let user = Double(cpuLoadInfo.cpu_ticks.0)
        let system = Double(cpuLoadInfo.cpu_ticks.1)
        let idle = Double(cpuLoadInfo.cpu_ticks.2)
        let nice = Double(cpuLoadInfo.cpu_ticks.3)

        guard let prev = previousCPUTicks else {
            previousCPUTicks = (user, system, idle, nice)
            return (12.0, 8.0, 4.0) // Initial estimate while priming
        }

        let deltaUser = max(0, user - prev.user)
        let deltaSystem = max(0, system - prev.system)
        let deltaIdle = max(0, idle - prev.idle)
        let deltaNice = max(0, nice - prev.nice)
        let deltaTotal = deltaUser + deltaSystem + deltaIdle + deltaNice

        previousCPUTicks = (user, system, idle, nice)

        if deltaTotal > 0 {
            let uPercent = (deltaUser / deltaTotal) * 100.0
            let sPercent = (deltaSystem / deltaTotal) * 100.0
            let tPercent = ((deltaUser + deltaSystem + deltaNice) / deltaTotal) * 100.0
            return (min(100.0, max(0.0, tPercent)), min(100.0, max(0.0, uPercent)), min(100.0, max(0.0, sPercent)))
        }

        return (0.0, 0.0, 0.0)
    }

    // MARK: - Memory Sampling via VM Statistics 64
    private func sampleMemory() -> (usedGB: Double, totalGB: Double, percentage: Double, appGB: Double, wiredGB: Double, compressedGB: Double, pressure: String) {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let totalGB = Double(totalBytes) / (1024.0 * 1024.0 * 1024.0)

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return (0.0, totalGB, 0.0, 0.0, 0.0, 0.0, "Normal")
        }

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        let pageBytes = Double(pageSize > 0 ? pageSize : 16384)

        let appMemoryGB = (Double(vmStats.active_count) + Double(vmStats.inactive_count)) * pageBytes / (1024.0 * 1024.0 * 1024.0)
        let wiredMemoryGB = Double(vmStats.wire_count) * pageBytes / (1024.0 * 1024.0 * 1024.0)
        let compressedGB = Double(vmStats.compressor_page_count) * pageBytes / (1024.0 * 1024.0 * 1024.0)

        // Used memory in macOS = Active/Inactive app memory + Wired kernel memory + Compressed memory
        let usedGB = min(totalGB, max(0.0, (Double(vmStats.active_count) * pageBytes / (1024.0 * 1024.0 * 1024.0)) + wiredMemoryGB + compressedGB))
        let percentage = min(100.0, max(0.0, (usedGB / totalGB) * 100.0))

        // Check system memory pressure
        var pressureLevel: Int32 = 0
        var size = MemoryLayout<Int32>.size
        let sysctlResult = sysctlbyname("kern.memorystatus_vm_pressure_level", &pressureLevel, &size, nil, 0)
        var pressureStr = "Normal"
        if sysctlResult == 0 {
            if pressureLevel == 4 {
                pressureStr = "Critical"
            } else if pressureLevel == 2 {
                pressureStr = "Moderate"
            } else {
                pressureStr = "Normal"
            }
        } else {
            if percentage > 85.0 {
                pressureStr = "Critical"
            } else if percentage > 70.0 {
                pressureStr = "Moderate"
            }
        }

        return (
            (usedGB * 10).rounded() / 10,
            (totalGB * 10).rounded() / 10,
            percentage,
            (appMemoryGB * 10).rounded() / 10,
            (wiredMemoryGB * 10).rounded() / 10,
            (compressedGB * 10).rounded() / 10,
            pressureStr
        )
    }
}
