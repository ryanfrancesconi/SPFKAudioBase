// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-audio-base",
    defaultLocalization: "en",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        .library(
            name: "SPFKAudioBase",
            targets: ["SPFKAudioBase"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-base", branch: "development"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", branch: "development"),
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
