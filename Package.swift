// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package

/*
 This source file is part of the Swift.org open source project

 Copyright 2015 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageDescription

let package = Package(
    name: "PlayingCard",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "PlayingCard", targets: ["PlayingCard"]),
    ],
    targets: [
        .target(
            name: "PlayingCard",
            dependencies: [],
            swiftSettings: [
                // Disable SwiftUI compilation in CI environments
                .define("CI_BUILD", .when(configuration: .release))
            ]),
        .testTarget(
            name: "PlayingCardTests",
            dependencies: ["PlayingCard"]),
    ]
)
