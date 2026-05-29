// swift-tools-version: 6.0
// Like One Swift — Monorepo
// One language. Every surface. With love.

import PackageDescription

let package = Package(
    name: "LikeOneSwift",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "LOCore", targets: ["LOCore"]),
        .library(name: "LOBrain", targets: ["LOBrain"]),
        .library(name: "LOAuth", targets: ["LOAuth"]),
        .library(name: "LODesign", targets: ["LODesign"]),
        .library(name: "LOContent", targets: ["LOContent"]),
        .executable(name: "LOServer", targets: ["LOServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
    ],
    targets: [
        // SQLite3 C bridge
        .target(
            name: "CSQLite3",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),

        // Foundation — models, protocols, utilities
        .target(
            name: "LOCore",
            dependencies: []
        ),

        // Brain interface — read/write/search
        .target(
            name: "LOBrain",
            dependencies: ["LOCore", "CSQLite3"]
        ),

        // Authentication — Sign in with Apple, Google, magic links
        .target(
            name: "LOAuth",
            dependencies: [
                "LOCore",
                .product(name: "Vapor", package: "vapor"),
            ]
        ),

        // Design system — tokens, components, accessibility
        .target(
            name: "LODesign",
            dependencies: ["LOCore"]
        ),

        // Content engine — courses, blog, products
        .target(
            name: "LOContent",
            dependencies: ["LOCore", "LOBrain"],
            resources: [.copy("Data")]
        ),

        // Vapor web server — API + SSR + HTMX
        .executableTarget(
            name: "LOServer",
            dependencies: [
                "LOCore",
                "LOBrain",
                "LOAuth",
                "LOContent",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Leaf", package: "leaf"),
            ]
        ),

        // Tests
        .testTarget(name: "LOCoreTests", dependencies: ["LOCore"]),
        .testTarget(name: "LOBrainTests", dependencies: ["LOBrain"]),
        .testTarget(name: "LOContentTests", dependencies: ["LOContent"]),
        .testTarget(name: "LODesignTests", dependencies: ["LODesign"]),
        .testTarget(name: "LOServerTests", dependencies: ["LOServer"]),
    ],
    swiftLanguageModes: [.v6]
)
