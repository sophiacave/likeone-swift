// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LikeOneSwift",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "LikeOneSwift",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Leaf", package: "leaf"),
            ]
        ),
        .testTarget(
            name: "LikeOneSwiftTests",
            dependencies: ["LikeOneSwift"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
