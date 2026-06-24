// swift-tools-version:6.0
import PackageDescription

let swift5 = SwiftSetting.swiftLanguageMode(.v5)

let package = Package(
    name: "Appear",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .target(
            name: "AppearCore",
            swiftSettings: [swift5]
        ),
        .executableTarget(
            name: "Appear",
            dependencies: ["AppearCore"],
            swiftSettings: [swift5]
        ),
        .testTarget(
            name: "AppearCoreTests",
            dependencies: ["AppearCore"],
            swiftSettings: [swift5]
        ),
    ]
)
