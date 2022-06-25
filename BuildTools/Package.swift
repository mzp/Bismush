// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "hello", targets: ["Sources"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.49.11"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.47.1"),
    ],

    targets: [
        .executableTarget(name: "Sources", path: "Sources"),
    ]
)
