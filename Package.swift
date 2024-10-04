// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "APIService",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "APIService",
            targets: ["APIService"]
        ),
    ],
    targets: [
        .target(
            name: "APIService"
        ),
        .testTarget(
            name: "APIServiceTests",
            dependencies: ["APIService"]
        ),
    ],
    swiftLanguageModes: [
        .v6
    ]
)
