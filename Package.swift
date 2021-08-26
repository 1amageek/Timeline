// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Timeline",
    platforms: [.iOS(.v14), .macOS(.v12)],
    products: [
        .library(
            name: "Timeline",
            targets: ["Timeline"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Timeline",
            dependencies: []),
        .testTarget(
            name: "TimelineTests",
            dependencies: ["Timeline"]),
    ]
)
