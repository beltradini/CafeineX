// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CafeineXCore",
    platforms: [
        .watchOS(.v10),
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CafeineXCore",
            targets: ["CafeineXCore"]
        ),
    ],
    targets: [
        .target(
            name: "CafeineXCore",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CafeineXCoreTests",
            dependencies: ["CafeineXCore"]
        ),
    ]
)
