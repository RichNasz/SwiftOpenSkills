# SwiftOpenSkills

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%20%7C%20iOS%2016-lightgrey.svg)](Package.swift)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-blueviolet?logo=claude)](https://claude.ai/code)

A Swift Package Manager library providing first-class, native Swift support for the [open Agent Skills standard](https://agentskills.io) — the official skills integration companion to [SwiftOpenResponsesDSL](https://github.com/RichNasz/SwiftOpenResponsesDSL), the recommended Swift library for building agentic workflows on the [Open Responses API](https://www.openresponses.org/).

## Overview

Agent Skills are Markdown files with YAML frontmatter that live on the filesystem. Each skill provides a set of instructions the LLM activates on demand via an `activate_skill` tool call. SwiftOpenSkills handles the full lifecycle:

- **Discovery** — scans standard and custom filesystem locations for directories containing a valid `SKILL.md`
- **Parsing** — extracts YAML frontmatter (`name`, `description`, and optional metadata) and the Markdown instruction body
- **Catalog generation** — produces a compact skill listing suitable for injection into LLM system prompts
- **Tool handler** — provides an `activate_skill` handler compatible with both DSLs, returning formatted instructions on demand
- **Declarative integration** — `@SkillsToolBuilder` result builder and `SkillsAgent` wrapper for each DSL

## Quick Start

### Installation

SwiftOpenSkills ships as three library products. Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RichNasz/SwiftOpenSkills.git", branch: "main")
]
```

Then add the product you need to your target:

| Product | Use when |
|---|---|
| `SwiftOpenSkills` | Core only — no DSL dependency |
| `SwiftOpenSkillsResponses` | Integrating with `SwiftOpenResponsesDSL` *(recommended)* |
| `SwiftOpenSkillsChat` | Integrating with `SwiftChatCompletionsDSL` *(legacy Chat Completions API)* |

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftOpenSkillsResponses", package: "SwiftOpenSkills")
    ]
)
```

### Minimal Example

```swift
import SwiftOpenSkillsResponses

let store = SkillStore()
try await store.load()   // scans standard locations

let agent = try await Agent.withSkills(store, client: client, model: "gpt-4o")
let response = try await agent.send("Please review my code using best practices.")
// The LLM calls activate_skill(name: "code-review") automatically
```

## Usage Examples

### Declarative with SkillsAgent

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

### Manual Integration (Responses DSL)

```swift
import SwiftOpenSkillsResponses

let store = SkillStore()
try await store.load(.directory(myURL))

let skillTool = await store.responsesAgentTool()
let catalogSection = await store.catalog().systemPromptSection()

let agent = try Agent(
    client: client,
    model: "gpt-4o",
    instructions: "You are a coding assistant.\n\n" + catalogSection
) {
    skillTool
    AgentTool(tool: myOtherTool) { args in ... }
}
```

### Direct Skill Injection (No Tool Calling)

```swift
let skill = try await store.requireSkill(slug: "git-commit")
let systemPrompt = "You are a commit expert.\n\n" + skill.instructions
```

### Skill Discovery

`SkillDiscovery` and `SkillStore.load` accept an ordered array of `SkillSearchPath` values. Earlier entries take priority — if the same slug appears in multiple locations, the first occurrence wins.

```swift
// Standard locations only
SkillDiscovery()

// Custom directory only
SkillDiscovery(.directory(myURL))

// Custom first, then standard
SkillDiscovery(.directory(myURL), .standard)

// Standard first, then custom fallback
SkillDiscovery(.standard, .directory(fallbackURL))
```

`.standard` expands to the following locations in order, following the [agentskills.io](https://agentskills.io) specification:

| # | Path |
|---|---|
| 1 | `{cwd}/skills/` |
| 2 | `{cwd}/.skills/` |
| 3 | `~/.config/agent-skills/` |
| 4 | `~/agent-skills/` |
| 5 | `/usr/local/share/agent-skills/` (macOS/Linux) |

## Requirements

- Swift 6.2+
- macOS 13.0+ / iOS 16.0+
- Depends on [Yams](https://github.com/jpsim/Yams) 5.1+ for YAML frontmatter parsing (core target only)
- Optional: [SwiftOpenResponsesDSL](https://github.com/RichNasz/SwiftOpenResponsesDSL) for the recommended [Open Responses API](https://www.openresponses.org/) integration, or [SwiftChatCompletionsDSL](https://github.com/RichNasz/SwiftChatCompletionsDSL) for legacy Chat Completions API projects

## Spec-Driven Development

If you use an AI coding agent, consider writing WHAT and HOW specs before generating code. See [docs/SpecDrivenDevelopment.md](docs/SpecDrivenDevelopment.md) for the workflow guide and [`Spec/SwiftOpenSkills.md`](Spec/SwiftOpenSkills.md) for the full API specification.

## License

SwiftOpenSkills is available under the MIT License. See [LICENSE](LICENSE) for details.
