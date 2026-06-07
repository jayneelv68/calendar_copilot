// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AnayasCoPilot",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AnayasCoPilot",
            path: "Sources/AnayasCoPilot"
        ),
        .testTarget(
            name: "AnayasCoPilotTests",
            dependencies: ["AnayasCoPilot"],
            path: "Tests/AnayasCoPilotTests"
        ),
    ]
)
