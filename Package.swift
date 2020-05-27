// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Similar",
    products: [
        .library(name: "Similar", targets: ["Similar"])
    ],
    targets: [
        .target(name: "Similar", dependencies: []),
        .testTarget(name: "SimilarTests", dependencies: ["Similar"])
    ]
)
