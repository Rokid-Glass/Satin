// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Satin",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "Satin",
            targets: ["Satin"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Satin",
            dependencies: [],
            exclude: ["Sources/Satin/Pipelines"],
            resources: [.copy("Sources/Satin/Pipelines")]),
        .testTarget(
            name: "SatinTests",
            dependencies: ["Satin"]),
    ]
)