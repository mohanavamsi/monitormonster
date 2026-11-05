// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MonitorMonster",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MonitorMonster", targets: ["MonitorMonster"])
    ],
    targets: [
        .executableTarget(
            name: "MonitorMonster",
            path: "Sources/MonitorMonster"
        )
    ]
)
