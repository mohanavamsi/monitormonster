import Foundation
import Darwin

public final class ThroughputService: @unchecked Sendable {
    public static let shared = ThroughputService()

    private var previousInBytes: UInt64 = 0
    private var previousOutBytes: UInt64 = 0
    private var previousTimestamp: CFAbsoluteTime = 0
    private let lock = NSLock()

    private init() {}

    public func sample(interfaceName: String = "en0") -> ThroughputMetric {
        lock.lock()
        defer { lock.unlock() }

        var inBytes: UInt64 = 0
        var outBytes: UInt64 = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return ThroughputMetric()
        }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let name = String(cString: current.pointee.ifa_name)
            if name == interfaceName {
                if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) {
                    if let data = current.pointee.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self)
                        inBytes = UInt64(networkData.pointee.ifi_ibytes)
                        outBytes = UInt64(networkData.pointee.ifi_obytes)
                    }
                }
            }
            ptr = current.pointee.ifa_next
        }

        let now = CFAbsoluteTimeGetCurrent()
        if previousTimestamp == 0 || previousInBytes == 0 {
            previousInBytes = inBytes
            previousOutBytes = outBytes
            previousTimestamp = now
            return ThroughputMetric()
        }

        let elapsed = now - previousTimestamp
        guard elapsed > 0 else { return ThroughputMetric() }

        let diffIn = inBytes >= previousInBytes ? (inBytes - previousInBytes) : 0
        let diffOut = outBytes >= previousOutBytes ? (outBytes - previousOutBytes) : 0

        previousInBytes = inBytes
        previousOutBytes = outBytes
        previousTimestamp = now

        let inPerSec = Double(diffIn) / elapsed
        let outPerSec = Double(diffOut) / elapsed

        return ThroughputMetric(bytesInPerSec: inPerSec, bytesOutPerSec: outPerSec)
    }
}
