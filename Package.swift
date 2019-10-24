// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "MapirLiveTracker",
    products: [
        .library(
            name: "MapirLiveTracker",
            targets: ["MapirLiveTracker"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MapirLiveTracker",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "MapirLiveTrackerTests",
            dependencies: ["MapirLiveTracker"],
            path: "Tests"
        ),
    ]
)
