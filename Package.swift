// swift-tools-version: 6.0
import Foundation
import PackageDescription

let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .path

let package = Package(
    name: "TSS",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "TSSApp", targets: ["TSSApp"]),
    ],
    targets: [
        .target(
            name: "CTSSCore",
            path: "macos/Sources/CTSSCore",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "TSSApp",
            dependencies: ["CTSSCore"],
            path: "macos/Sources/TSSApp",
            linkerSettings: [
                .unsafeFlags(["-L\(repositoryRoot)/target/release"]),
                .linkedLibrary("tss_ffi"),
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
