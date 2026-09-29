// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-plist",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Plist", targets: ["Plist"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-byte.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-compositions/swift-xml.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-async-stream.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-4648.git", branch: "main"),
        .package(url: "https://github.com/swift-iso/swift-iso-8601.git", branch: "main"),
    ],
    targets: [

        .target(
            name: "Plist Core",
            dependencies: []
        ),

        .target(
            name: "Plist XML",
            dependencies: [
                "Plist Core",
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "XML", package: "swift-xml"),
                .product(name: "RFC 4648", package: "swift-rfc-4648"),
                .product(name: "ISO 8601", package: "swift-iso-8601"),
            ]
        ),

        .target(
            name: "Plist Binary",
            dependencies: [
                "Plist Core"
            ]
        ),

        .target(
            name: "Plist",
            dependencies: [
                "Plist Core",
                "Plist XML",
                "Plist Binary",
                .product(name: "Async Stream", package: "swift-async-stream"),
            ]
        ),
        .testTarget(
            name: "Plist Tests",
            dependencies: [
                "Plist"
            ]
        ),
        .testTarget(
            name: "Plist XML Tests",
            dependencies: [
                "Plist XML"
            ]
        ),
        .testTarget(
            name: "Plist Binary Tests",
            dependencies: [
                "Plist Binary"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
