// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftGantt",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftGantt",
            type: .dynamic,
            targets: ["SwiftGantt"]
        )
    ],
    targets: [
        .target(
            name: "SwiftGantt"
        ),
        .testTarget(
            name: "SwiftGanttTests",
            dependencies: ["SwiftGantt"]
        )
    ]
)
