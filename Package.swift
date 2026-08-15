// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Moleify",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Moleify",
            targets: ["Moleify"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Moleify",
            dependencies: [],
            exclude: [
                "Metal/Shaders.metal"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
