# SwiftOpenSkills — Specification

> Status: **Released** — v1.0

## Overview

SwiftOpenSkills is a Swift Package Manager library that provides first-class, native Swift support for the open Agent Skills standard. It is the official skill integration companion to `SwiftOpenResponsesDSL` and `SwiftChatCompletionsDSL`.

The package handles discovery, parsing, catalog generation, and activation of Agent Skills so they can be used side-by-side with tools during LLM inference calls, following the progressive disclosure pattern defined by the Agent Skills standard.

## Goals

### Goals
- Discover Agent Skills by scanning standard and custom filesystem locations for directories containing a valid `SKILL.md` file with YAML frontmatter.
- Parse each `SKILL.md`: extract YAML frontmatter (`name`, `description`, and optional metadata) and the remaining Markdown instruction body.
- Provide a clean `Skill` model representing a parsed skill.
- Generate a compact skill catalog (name + description per skill) suitable for inclusion in LLM system prompts.
- Offer an `activate_skill(name: String)` tool definition and handler that works with both DSLs.
- When a skill is activated, return its full instructions (and optionally list its resource files) for injection into conversation context.
- Include a declarative `@SkillsToolBuilder` result builder and `SkillsAgent` wrapper optimized for use with the `Agent` in both DSLs.
- Provide lower-level helpers (`chatAgentTool()`, `responsesAgentTool()`) for manual integration.
- Remain lightweight, actor-safe, async-first, and depend only on Yams plus the two DSL packages where appropriate.

### Non-Goals
- No actual skill content is included in this package.
- No network-based skill discovery or remote skill registries.
- No skill authoring or editing tools.
- No execution of skill instructions — the package delivers instructions to the LLM; the LLM acts on them.

## SKILL.md Format

Skills live in named subdirectories. The directory name (lowercased) is the stable **slug** used as the `activate_skill` argument. The YAML `name` field is the display name shown in the catalog.

```
skills/
  git-commit/
    SKILL.md
    resources/       ← optional supporting files
      checklist.md
```

```markdown
---
name: Git Commit
description: Writes conventional commit messages by analyzing staged diffs.
version: 1.0.0
author: Jane Smith
tags: [git, commit, conventional-commits]
---

## Instructions

You are an expert at writing conventional commit messages...
```

| Field | Required | Type | Description |
|---|---|---|---|
| `name` | Yes | String | Human-readable display name shown in the skill catalog. |
| `description` | Yes | String | One-line description embedded in the catalog listing. |
| `version` | No | String | Semantic version string. |
| `author` | No | String | Author identifier. |
| `tags` | No | [String] | Categorization tags. |

Everything after the closing `---` delimiter is the Markdown instruction body. It must be non-empty.

## Skill Discovery: Search Path Hierarchy

`SkillDiscovery` and `SkillStore.load` accept an ordered array of `SkillSearchPath` values. Earlier entries take priority — if the same slug appears in multiple locations, the first occurrence wins.

```swift
public struct SkillSearchPath: Sendable {
    /// All platform-standard locations, in order:
    ///   1. {cwd}/skills/
    ///   2. {cwd}/.skills/
    ///   3. ~/.config/agent-skills/
    ///   4. ~/agent-skills/
    ///   5. /usr/local/share/agent-skills/  (macOS/Linux only)
    public static let standard: SkillSearchPath

    /// A single explicit directory to scan for skill subdirectories.
    public static func directory(_ url: URL) -> SkillSearchPath
}
```

Examples:

```swift
SkillDiscovery()                                          // standard only (default)
SkillDiscovery(.directory(myURL))                         // custom only
SkillDiscovery(.directory(myURL), .standard)              // custom first, then standard
SkillDiscovery(.standard, .directory(fallbackURL))        // standard first, then custom
SkillDiscovery(.directory(projectURL), .directory(sharedURL))  // multiple custom, no standard
```

## Capabilities

### 1. Core (`SwiftOpenSkills`)

Depends only on Yams. No DSL dependency.

#### `Skill`

```swift
public struct Skill: Sendable, Equatable, Identifiable {
    public let id: String           // slug (e.g. "git-commit")
    public let name: String
    public let description: String
    public let version: String?
    public let author: String?
    public let tags: [String]
    public let instructions: String
    public let directoryURL: URL
    public var skillFileURL: URL    // computed
    public func resourceURLs() throws -> [URL]
}
```

#### `SkillStore`

Primary entry point. Actor-safe, async-first.

```swift
public actor SkillStore {
    // Loading
    public func load() async throws -> DiscoveryResult
    public func load(_ paths: SkillSearchPath...) async throws -> DiscoveryResult
    public func load(_ paths: [SkillSearchPath]) async throws -> DiscoveryResult
    public func load(from result: DiscoveryResult)
    public func register(_ skill: Skill)

    // Querying
    public var skills: [Skill] { get }         // sorted by slug
    public var isLoaded: Bool { get }
    public func skill(slug: String) -> Skill?
    public func requireSkill(slug: String) throws -> Skill

    // Catalog
    public func catalog() -> SkillCatalog

    // Tool handler
    public static let activateSkillToolName: String
    public static let activateSkillToolDescription: String
    public func activateSkillHandler(argumentsJSON: String) async throws -> String
}
```

`activateSkillHandler` parses `{"name": "<slug>"}` from the JSON arguments and returns:

```
[Skill Activated: git-commit]

# Git Commit

{full instruction body}

---
Resources: checklist.md, examples.md   ← only if resources/ exists
```

#### `SkillCatalog`

```swift
public struct SkillCatalog: Sendable {
    public let skills: [Skill]
    public var compactListing: String        // "- slug: Name — description" per line
    public var entries: [CatalogEntry]       // Encodable structs
    public func systemPromptSection() -> String
}
```

`systemPromptSection()` produces a Markdown block instructing the LLM about available skills and the `activate_skill` tool.

#### `SkillDiscovery`

```swift
public actor SkillDiscovery {
    public init()
    public init(_ searchPaths: SkillSearchPath...)
    public init(_ searchPaths: [SkillSearchPath])
    public func discover() async throws -> DiscoveryResult
}

public struct DiscoveryResult: Sendable {
    public let skills: [Skill]
    public let failures: [DiscoveryFailure]   // non-fatal parse errors
}
```

### 2. Responses Integration (`SwiftOpenSkillsResponses`)

Depends on `SwiftOpenSkills` + `SwiftOpenResponsesDSL`.

#### `SkillStore.responsesAgentTool(strict:)`

```swift
extension SkillStore {
    public func responsesAgentTool(strict: Bool? = nil) -> AgentTool
}
```

Returns an `AgentTool` (Responses DSL type) for `activate_skill`, ready for use in `@AgentToolBuilder`.

#### `Agent.withSkills(_:client:model:...)`

```swift
extension Agent {
    public static func withSkills(
        _ store: SkillStore,
        client: LLMClient,
        model: String,
        strict: Bool? = nil,
        baseInstructions: String? = nil,
        maxToolIterations: Int = 10,
        @AgentToolBuilder tools: () -> [AgentTool] = { [] }
    ) async throws -> Agent
}
```

Creates a fully configured `Agent` with `activate_skill` pre-registered and the skill catalog appended to instructions.

#### `SkillsAgent` (Responses)

```swift
public actor SkillsAgent {
    public init(
        client: LLMClient,
        model: String,
        baseInstructions: String? = nil,
        maxToolIterations: Int = 10,
        @SkillsToolBuilder tools: () -> [SkillsComponent]
    ) async throws

    public func send(_ message: String) async throws -> String
    public func stream(_ message: String) async -> AsyncThrowingStream<ToolSessionEvent, Error>
    public var transcript: [TranscriptEntry] { get async }
    public func reset() async
}
```

Used with `@SkillsToolBuilder`, which accepts both `AgentTool` and `Skills` values:

```swift
let agent = try await SkillsAgent(client: client, model: "gpt-4o") {
    Skills(store: store)
    AgentTool(tool: myFileTool) { args in ... }
}
```

### 3. Chat Integration (`SwiftOpenSkillsChat`)

Depends on `SwiftOpenSkills` + `SwiftChatCompletionsDSL`. Mirrors the Responses integration.

#### `SkillStore.chatAgentTool()`

```swift
extension SkillStore {
    public func chatAgentTool() -> AgentTool
}
```

#### `Agent.withSkills(_:client:model:...)`

```swift
extension Agent {
    public static func withSkills(
        _ store: SkillStore,
        client: LLMClient,
        model: String,
        baseSystemPrompt: String? = nil,
        maxToolIterations: Int = 10,
        @AgentToolBuilder tools: () -> [AgentTool] = { [] }
    ) async throws -> Agent
}
```

#### `SkillsAgent` (Chat)

```swift
public actor SkillsAgent {
    public init(
        client: LLMClient,
        model: String,
        baseSystemPrompt: String? = nil,
        maxToolIterations: Int = 10,
        @SkillsToolBuilder tools: () -> [SkillsComponent]
    ) async throws

    public func send(_ message: String) async throws -> String
    public func streamSend(_ message: String) async -> AsyncThrowingStream<ToolSessionEvent, Error>
    public var history: [any ChatMessage] { get async }
    public func reset() async
}
```

## Usage Patterns

### Fully Automatic (Responses DSL)

```swift
let store = SkillStore()
try await store.load()   // or: store.load(.directory(myURL), .standard)

let agent = try await Agent.withSkills(store, client: client, model: "gpt-4o")
let response = try await agent.send("Please review my code using best practices.")
// LLM calls activate_skill(name: "code-review") automatically
```

### Declarative with SkillsAgent (Responses DSL)

```swift
let store = SkillStore()
try await store.load(.directory(projectSkillsURL), .standard)

let agent = try await SkillsAgent(client: client, model: "gpt-4o") {
    Skills(store: store)
    AgentTool(tool: myFileReadTool) { args in ... }
    AgentTool(tool: myShellTool) { args in ... }
}

let response = try await agent.send("Commit my staged changes.")
```

### Manual Integration (Chat DSL)

```swift
let store = SkillStore()
try await store.load(.directory(myURL))

let skillTool = await store.chatAgentTool()
let catalogSection = await store.catalog().systemPromptSection()

let agent = try Agent(
    client: client,
    model: "gpt-4o",
    systemPrompt: "You are a coding assistant.\n\n" + catalogSection
) {
    skillTool
    AgentTool(tool: myOtherTool) { args in ... }
}
```

### Direct Skill Injection (No Tool Calling)

```swift
let skill = try await store.requireSkill(slug: "git-commit")
// Inject instructions directly into the conversation
let systemPrompt = "You are a commit expert.\n\n" + skill.instructions
```

## Examples

Three runnable command-line examples are included under `Examples/`. Each example lives in its own directory, is split into a library target (core logic) and an executable target (CLI entry point), and uses `swift-argument-parser` for argument parsing. All examples operate against a real skills directory on the filesystem.

```
Examples/
  BasicUsage.swift               ← non-runnable code reference
  DiscoverSkills/
    Sources/DiscoverSkills.swift
    CLI/DiscoverSkillsCLI.swift
  ShowCatalog/
    Sources/ShowCatalog.swift
    CLI/ShowCatalogCLI.swift
  ActivateSkill/
    Sources/ActivateSkill.swift
    CLI/ActivateSkillCLI.swift
```

### `discover-skills`

Scans a directory for Agent Skills and prints a summary of each discovered skill (slug, name, description, and optional version and tags). Parse failures are reported after the skill list.

**Command:**

```bash
swift run discover-skills <directory>
```

**Arguments:**

| Argument | Type | Required | Description |
|---|---|---|---|
| `directory` | String (path) | Yes | Path to the directory containing skill subdirectories to scan. |

**Output:**

```
Found 3 skill(s):

  git-commit — Git Commit
  Description: Writes conventional commit messages by analyzing staged diffs.
  Version: 1.0.0  Tags: git, commit

  ...

1 failure(s):
  invalid-yaml: invalidYAML(...)
```

### `show-catalog`

Loads skills from a directory and prints the full `systemPromptSection()` output — exactly what would be prepended to an LLM system prompt to inform the model of available skills and how to activate them.

**Command:**

```bash
swift run show-catalog <directory>
```

**Arguments:**

| Argument | Type | Required | Description |
|---|---|---|---|
| `directory` | String (path) | Yes | Path to the directory containing skill subdirectories to scan. |

**Output:**

The complete Markdown block produced by `SkillCatalog.systemPromptSection()`, including the available skill listing and `activate_skill` usage guidance.

### `activate-skill`

Loads skills from a directory and activates one by slug, printing the formatted output that the LLM would receive in response to an `activate_skill` tool call.

**Command:**

```bash
swift run activate-skill <directory> <slug>
```

**Arguments:**

| Argument | Type | Required | Description |
|---|---|---|---|
| `directory` | String (path) | Yes | Path to the directory containing skill subdirectories to scan. |
| `slug` | String | Yes | The skill slug (directory name) to activate. |

**Output:**

```
[Skill Activated: git-commit]

# Git Commit

{full instruction body}

---
Resources: checklist.md   ← only if resources/ directory exists
```

## Acceptance Criteria

- [x] `SkillStore.load()` scans standard filesystem locations and returns a `DiscoveryResult`.
- [x] `SkillStore.load(_ paths: SkillSearchPath...)` accepts an explicit ordered hierarchy.
- [x] Parse failures are collected in `DiscoveryResult.failures` and do not abort the scan.
- [x] `Skill.id` is the lowercased directory name, not the YAML `name` field.
- [x] `SkillParser` handles CRLF line endings, missing frontmatter, invalid YAML, missing required keys, and empty instruction bodies with typed `SkillError` cases.
- [x] `activate_skill` tool handler parses `{"name": "<slug>"}` and returns formatted instructions.
- [x] Resource files in `resources/` are listed in the handler response when present.
- [x] `SkillCatalog.compactListing` uses the `- slug: Name — description` format.
- [x] `SkillCatalog.systemPromptSection()` includes `activate_skill` usage guidance.
- [x] `Agent.withSkills` creates a correctly configured agent for both DSLs.
- [x] `SkillsAgent` resolves `Skills` instances asynchronously and forwards all agent methods.
- [x] `@SkillsToolBuilder` accepts both `AgentTool` and `Skills` expressions.
- [x] All three targets build cleanly under Swift 6 strict concurrency.
- [x] 36 unit tests pass covering parser, discovery, store, handler, catalog, and resources.
- [x] `discover-skills` builds and prints discovered skills with slug, name, description, version, and tags.
- [x] `show-catalog` builds and prints the full `systemPromptSection()` output for a given directory.
- [x] `activate-skill` builds and prints the formatted handler output for a given directory and slug.

## Dependencies

| Dependency | Role | Targets |
|---|---|---|
| [Yams](https://github.com/jpsim/Yams) | YAML frontmatter parsing | `SwiftOpenSkills` |
| [SwiftOpenResponsesDSL](https://github.com/RichNasz/SwiftOpenResponsesDSL) | Responses API agent integration | `SwiftOpenSkillsResponses` |
| [SwiftChatCompletionsDSL](https://github.com/RichNasz/SwiftChatCompletionsDSL) | Chat Completions agent integration | `SwiftOpenSkillsChat` |
| [SwiftLLMToolMacros](https://github.com/RichNasz/SwiftLLMToolMacros) | `ToolDefinition` and `JSONSchemaValue` types | Integration targets |
| [swift-argument-parser](https://github.com/apple/swift-argument-parser) | CLI argument parsing | Example executables |
