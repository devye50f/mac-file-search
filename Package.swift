// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacFileSearch",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SearchCore", targets: ["SearchCore"]),
        .executable(name: "MacFileSearch", targets: ["MacFileSearch"])
    ],
    targets: [
        .target(name: "SearchCore"),
        .executableTarget(name: "MacFileSearch", dependencies: ["SearchCore"]),
        .testTarget(name: "SearchCoreTests", dependencies: ["SearchCore"])
    ]
)
