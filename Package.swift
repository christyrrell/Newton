// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Newton",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Newton",
            path: "Sources",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
