// swift-tools-version: 6.0
import Foundation
import PackageDescription

let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .path

let package = Package(
    name: "Castor",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CastorApp", targets: ["CastorApp"]),
    ],
    targets: [
        .target(
            name: "CCastorCore",
            path: "macos/Sources/CCastorCore",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "CastorApp",
            dependencies: ["CCastorCore"],
            path: "macos/Sources/CastorApp",
            linkerSettings: [
                .unsafeFlags(["-L\(repositoryRoot)/target/release"]),
                .linkedLibrary("castor_ffi"),
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
