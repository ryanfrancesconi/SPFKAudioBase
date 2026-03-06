// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-audio-base",
    defaultLocalization: "en",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "SPFKAudioBase",
            targets: ["SPFKAudioBase"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-base", from: "0.0.3"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", from: "0.0.5"),
    ],
    targets: [
        .target(
            name: "SPFKAudioBase",
            dependencies: [
                .product(name: "SPFKBase", package: "spfk-base")
            ]
        ),
        .testTarget(
            name: "SPFKAudioBaseTests",
            dependencies: [
                .targetItem(name: "SPFKAudioBase", condition: nil),
                .product(name: "SPFKTesting", package: "spfk-testing"),
            ]
        ),
    ]
)
