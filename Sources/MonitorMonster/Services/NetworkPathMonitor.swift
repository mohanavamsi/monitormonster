import Foundation
import Network

public final class NetworkPathMonitor: @unchecked Sendable {
    public static let shared = NetworkPathMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.monitormonster.pathmonitor")
    public var onNetworkChanged: (@Sendable (NWPath) -> Void)?

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.onNetworkChanged?(path)
        }
    }

    public func start() {
        monitor.start(queue: queue)
    }

    public func stop() {
        monitor.cancel()
    }
}

