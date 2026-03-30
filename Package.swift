// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftOpenSkills",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "SwiftOpenSkills", targets: ["SwiftOpenSkills"]),
        .library(name: "SwiftOpenSkillsResponses", targets: ["SwiftOpenSkillsResponses"]),
        .library(name: "SwiftOpenSkillsChat", targets: ["SwiftOpenSkillsChat"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
        .package(url: "https://github.com/RichNasz/SwiftOpenResponsesDSL", branch: "main"),
        .package(url: "https://github.com/RichNasz/SwiftChatCompletionsDSL", branch: "main"),
        .package(url: "https://github.com/RichNasz/SwiftLLMToolMacros", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "SwiftOpenSkills",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .target(
            name: "SwiftOpenSkillsResponses",
            dependencies: [
                "SwiftOpenSkills",
                .product(name: "SwiftOpenResponsesDSL", package: "SwiftOpenResponsesDSL"),
                .product(name: "SwiftLLMToolMacros", package: "SwiftLLMToolMacros"),
            ]
        ),
        .target(
            name: "SwiftOpenSkillsChat",
            dependencies: [
                "SwiftOpenSkills",
                .product(name: "SwiftChatCompletionsDSL", package: "SwiftChatCompletionsDSL"),
                .product(name: "SwiftLLMToolMacros", package: "SwiftLLMToolMacros"),
            ]
        ),
        // MARK: - Examples
        .target(
            name: "DiscoverSkillsExample",
            dependencies: ["SwiftOpenSkills"],
            path: "Examples/DiscoverSkills/Sources"
        ),
        .executableTarget(
            name: "discover-skills",
            dependencies: [
                "DiscoverSkillsExample",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Examples/DiscoverSkills/CLI"
        ),
        .target(
            name: "ShowCatalogExample",
            dependencies: ["SwiftOpenSkills"],
            path: "Examples/ShowCatalog/Sources"
        ),
        .executableTarget(
            name: "show-catalog",
            dependencies: [
                "ShowCatalogExample",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Examples/ShowCatalog/CLI"
        ),
        .target(
            name: "ActivateSkillExample",
            dependencies: ["SwiftOpenSkills"],
            path: "Examples/ActivateSkill/Sources"
        ),
        .executableTarget(
            name: "activate-skill",
            dependencies: [
                "ActivateSkillExample",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Examples/ActivateSkill/CLI"
        ),

        // MARK: - Tests
        .testTarget(
            name: "SwiftOpenSkillsTests",
            dependencies: ["SwiftOpenSkills"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "SwiftOpenSkillsResponsesTests",
            dependencies: ["SwiftOpenSkillsResponses"]
        ),
        .testTarget(
            name: "SwiftOpenSkillsChatTests",
            dependencies: ["SwiftOpenSkillsChat"]
        ),
    ]
)
