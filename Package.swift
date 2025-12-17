// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BodyHighlighter",
    platforms: [
        .iOS(.v17), .macOS(.v14)
    ],
    products: [
        .library(
            name: "BodyHighlighter",
            targets: ["BodyHighlighter"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BodyHighlighter",
            dependencies: []),
        .testTarget(
            name: "BodyHighlighterTests",
            dependencies: ["BodyHighlighter"]),
    ]
)
