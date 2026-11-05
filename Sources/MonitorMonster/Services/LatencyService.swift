import Foundation
import Network

public actor LatencyService {
    public static let shared = LatencyService()

    private init() {}

    private final class PingCoordinator: @unchecked Sendable {
        private var isCompleted = false
        private let lock = NSLock()

        func complete() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if isCompleted { return false }
            isCompleted = true
            return true
        }
    }

    /// Measures latency to target host and port in milliseconds
    public func measureLatency(to host: String, port: UInt16 = 53, timeoutSeconds: Double = 1.5) async -> Double? {
        guard !host.isEmpty && host != "N/A" else { return nil }

        let endpointHost = NWEndpoint.Host(host)
        guard let endpointPort = NWEndpoint.Port(rawValue: port) else { return nil }

        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = Int(timeoutSeconds)
        let params = NWParameters(tls: nil, tcp: tcpOptions)
        params.prohibitedInterfaceTypes = []

        let connection = NWConnection(host: endpointHost, port: endpointPort, using: params)
        let startTime = CFAbsoluteTimeGetCurrent()
        let coordinator = PingCoordinator()

        return await withCheckedContinuation { continuation in
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                if coordinator.complete() {
                    connection.cancel()
                    continuation.resume(returning: nil)
                }
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if coordinator.complete() {
                        timeoutTask.cancel()
                        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0 // ms
                        connection.cancel()
                        continuation.resume(returning: elapsed)
                    }
                case .failed, .cancelled:
                    if coordinator.complete() {
                        timeoutTask.cancel()
                        connection.cancel()
                        continuation.resume(returning: nil)
                    }
                default:
                    break
                }
            }

            let queue = DispatchQueue(label: "com.monitormonster.ping")
            connection.start(queue: queue)
        }
    }

    /// Measures both gateway router and internet latency concurrently
    public func checkNetworkLatency(gatewayIP: String) async -> LatencyMetrics {
        async let routerPing = measureLatency(to: gatewayIP, port: 53)
        async let internetPing = measureLatency(to: "1.1.1.1", port: 53)

        let rLat = await routerPing
        let iLat = await internetPing

        return LatencyMetrics(
            routerLatencyMs: rLat,
            internetLatencyMs: iLat,
            lastUpdated: Date()
        )
    }
}
