// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package

import PackageDescription

let package = Package(
    name: "PlayingCard",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(name: "PlayingCard", targets: ["PlayingCard"])
    ],
    targets: [
        .target(
            name: "PlayingCard",
            dependencies: []),
        .testTarget(
            name: "PlayingCardTests",
            dependencies: ["PlayingCard"])
    ]
)
