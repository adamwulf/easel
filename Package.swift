// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "easel",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "EaselKit", targets: ["EaselKit"]),
        .executable(name: "easel", targets: ["easel"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/adamwulf/FellerBuncher.git", branch: "main")
    ],
    targets: [
        .target(
            name: "EaselKit",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .executableTarget(
            name: "easel",
            dependencies: [
                "EaselKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "FellerBuncher", package: "FellerBuncher")
            ]
        ),
        .testTarget(
            name: "EaselKitTests",
            dependencies: ["EaselKit"]
        ),
        .testTarget(
            name: "CLITests",
            dependencies: [
                "easel",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
