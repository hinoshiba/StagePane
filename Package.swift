// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "StagePane",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "StagePaneCore", targets: ["StagePaneCore"]),
        .executable(name: "StagePane", targets: ["StagePane"])
    ],
    targets: [
        .target(
            name: "StagePaneCore",
            path: "Sources/StagePaneCore"
        ),
        .executableTarget(
            name: "StagePane",
            dependencies: ["StagePaneCore"],
            path: "Sources/StagePane",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "StagePaneCoreTests",
            dependencies: ["StagePaneCore"],
            path: "Tests/StagePaneCoreTests"
        )
    ]
)
