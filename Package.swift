// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Similar",
    platforms: [
        .iOS(.v15), .macOS(.v11), .tvOS(.v15), .watchOS(.v9), .visionOS(.v1)
    ],
    products: [
        .library(name: "Similar", targets: ["Similar"])
    ],
    targets: [
        .target(name: "Similar", dependencies: []),
        .testTarget(name: "SimilarTests", dependencies: ["Similar"])
    ]
)
