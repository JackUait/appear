// swift-tools-version:6.0
import PackageDescription

let swift5 = SwiftSetting.swiftLanguageMode(.v5)

let package = Package(
    name: "BetterTab",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "BetterTabCore",
            swiftSettings: [swift5]
        ),
        .executableTarget(
            name: "BetterTab",
            dependencies: ["BetterTabCore"],
            swiftSettings: [swift5]
        ),
        .testTarget(
            name: "BetterTabCoreTests",
            dependencies: ["BetterTabCore"],
            swiftSettings: [swift5]
        ),
    ]
)
