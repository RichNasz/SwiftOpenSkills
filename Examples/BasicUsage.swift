// BasicUsage.swift — SwiftOpenSkills usage examples
// These snippets illustrate the main integration patterns.
// They are not runnable as-is; substitute your actual client and model.
//
// Package trait requirements:
//   import SwiftOpenSkills            — always available (no trait needed)
//   import SwiftOpenSkillsResponses   — requires traits: ["responses"]
//   import SwiftOpenSkillsChat        — requires traits: ["chat"]
//
// Both traits are enabled by default; specify only what your consumer target needs:
//   .package(url: "…/SwiftOpenSkills.git", branch: "main", traits: ["responses"])

import Foundation
import SwiftOpenSkills
import SwiftOpenSkillsResponses
import SwiftOpenSkillsChat

// MARK: - Core: Loading Skills

func coreLoading() async throws {
    // Load from all standard platform locations
    let store = SkillStore()
    let result = try await store.load()
    print("Loaded \(result.skills.count) skills, \(result.failures.count) failures")

    // Load from a specific directory only
    let customStore = SkillStore()
    let customDir = URL(filePath: "path/to/my/skills", directoryHint: .isDirectory)
    try await customStore.load(.directory(customDir))

    // Load from custom directory first, then fall back to standard locations
    let hybridStore = SkillStore()
    try await hybridStore.load(.directory(customDir), .standard)

    // Register a skill directly (useful for testing)
    let store2 = SkillStore()
    let skill = Skill(
        id: "my-skill",
        name: "My Skill",
        description: "Does something useful.",
        version: "1.0.0",
        author: nil,
        tags: ["example"],
        instructions: "You are an expert at doing something useful.",
        directoryURL: URL(filePath: "/tmp/my-skill", directoryHint: .isDirectory)
    )
    await store2.register(skill)
}

// MARK: - Core: Querying the Store

func coreQuerying() async throws {
    let store = SkillStore()
    try await store.load()

    // All skills, sorted by slug
    let skills = await store.skills
    for skill in skills {
        print("\(skill.id): \(skill.name) — \(skill.description)")
    }

    // Look up by slug
    if let skill = await store.skill(slug: "git-commit") {
        print("Found: \(skill.name)")
    }

    // Require a skill (throws skillNotFound if missing)
    let skill = try await store.requireSkill(slug: "code-review")
    print(skill.instructions)

    // List resource files (if any)
    let resources = try skill.resourceURLs()
    for url in resources {
        print("Resource: \(url.lastPathComponent)")
    }
}

// MARK: - Core: Skill Catalog

func coreCatalog() async throws {
    let store = SkillStore()
    try await store.load()

    let catalog = await store.catalog()

    // Compact listing: "- slug: Name — description" per line
    print(catalog.compactListing)

    // Structured entries (Encodable)
    for entry in catalog.entries {
        print("\(entry.slug): \(entry.name)")
    }

    // System prompt section: Markdown block with catalog + activate_skill usage guidance
    let section = catalog.systemPromptSection()
    let systemPrompt = "You are a coding assistant.\n\n" + section
    _ = systemPrompt  // inject into your Agent or API call
}

// MARK: - Core: Activate Skill Handler (Manual)

func coreActivateHandler() async throws {
    let store = SkillStore()
    try await store.load()

    // The handler parses {"name": "<slug>"} and returns formatted instructions
    let output = try await store.activateSkillHandler(argumentsJSON: #"{"name":"git-commit"}"#)
    print(output)
    // Output:
    // [Skill Activated: git-commit]
    //
    // # Git Commit
    //
    // <full instruction body>
    //
    // ---
    // Resources: checklist.md   ← only if resources/ exists
}

// MARK: - Responses DSL: Agent.withSkills

func responsesWithSkills(client: any Sendable, model: String) async throws {
    // `client` here represents an LLMClient from SwiftOpenResponsesDSL
    let store = SkillStore()
    try await store.load()

    // Fully automatic: activate_skill pre-registered, catalog appended to instructions
    // let agent = try await Agent.withSkills(store, client: client, model: model)
    // let response = try await agent.send("Please help me write a conventional commit.")

    // With additional tools and base instructions
    // let agent = try await Agent.withSkills(
    //     store,
    //     client: client,
    //     model: model,
    //     baseInstructions: "You are a senior software engineer.",
    //     maxToolIterations: 15
    // ) {
    //     AgentTool(tool: fileReadTool) { args in ... }
    //     AgentTool(tool: shellTool) { args in ... }
    // }
}

// MARK: - Responses DSL: SkillsAgent (Declarative)

func responsesSkillsAgent(client: any Sendable, model: String) async throws {
    let store = SkillStore()
    let projectSkillsURL = URL(filePath: "skills", directoryHint: .isDirectory)
    try await store.load(.directory(projectSkillsURL), .standard)

    // @SkillsToolBuilder accepts both Skills and AgentTool expressions
    // let agent = try await SkillsAgent(client: client, model: model) {
    //     Skills(store: store)
    //     AgentTool(tool: myFileReadTool) { args in ... }
    //     AgentTool(tool: myShellTool) { args in ... }
    // }
    //
    // let response = try await agent.send("Commit my staged changes.")
    // print(response)
    //
    // // Streaming
    // for try await event in await agent.stream("Explain the diff.") {
    //     // handle ToolSessionEvent
    // }
    //
    // await agent.reset()  // clear conversation history
}

// MARK: - Chat DSL: Manual Integration

func chatManualIntegration(client: any Sendable, model: String) async throws {
    // `client` here represents an LLMClient from SwiftChatCompletionsDSL
    let store = SkillStore()
    try await store.load()

    let catalogSection = await store.catalog().systemPromptSection()

    // let skillTool = await store.chatAgentTool()
    // let agent = try Agent(
    //     client: client,
    //     model: model,
    //     systemPrompt: "You are a coding assistant.\n\n" + catalogSection
    // ) {
    //     skillTool
    //     AgentTool(tool: myOtherTool) { args in ... }
    // }
    //
    // let response = try await agent.send("Help me write a commit message.")

    _ = catalogSection
}

// MARK: - Direct Skill Injection (No Tool Calling)

func directInjection() async throws {
    let store = SkillStore()
    try await store.load()

    let skill = try await store.requireSkill(slug: "git-commit")

    // Inject the full instructions directly — no activate_skill tool needed
    let systemPrompt = "You are an expert assistant.\n\n" + skill.instructions
    _ = systemPrompt  // pass to your API call
}

// MARK: - Discovery Only (Without SkillStore)

func discoveryOnly() async throws {
    let fixturesURL = URL(filePath: "skills", directoryHint: .isDirectory)
    let discovery = SkillDiscovery(.directory(fixturesURL), .standard)
    let result = try await discovery.discover()

    for skill in result.skills {
        print("Discovered: \(skill.id) (\(skill.name))")
    }
    for failure in result.failures {
        print("Failed: \(failure.directoryURL.lastPathComponent) — \(failure.error)")
    }
}
