// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "zread",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-cmark.git", branch: "gfm"),
    ],
    targets: [
        .target(
            name: "ZreadCore",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
            ]
        ),
        .executableTarget(name: "ZreadApp", dependencies: ["ZreadCore"]),
        .executableTarget(name: "zread-cli"),
        .testTarget(name: "ZreadCoreTests", dependencies: ["ZreadCore"]),
    ]
)
