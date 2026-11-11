// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ezread",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-cmark.git", branch: "gfm"),
    ],
    targets: [
        .target(
            name: "EzreadCore",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
            ]
        ),
        .executableTarget(name: "EzreadApp", dependencies: ["EzreadCore"]),
        .executableTarget(name: "ezread-cli"),
        .testTarget(name: "EzreadCoreTests", dependencies: ["EzreadCore"]),
    ]
)
