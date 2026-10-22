// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RecordHighs",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "RecordCore"),
        .executableTarget(name: "RecordHighs", dependencies: ["RecordCore"]),
        .testTarget(name: "RecordCoreTests", dependencies: ["RecordCore"]),
    ]
)
