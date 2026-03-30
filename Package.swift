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
