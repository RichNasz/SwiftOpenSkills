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

SwiftOpenSkills uses SE-0450 package traits to make DSL integrations opt-in. Add the package and specify which integrations you need:

| Traits | What's enabled |
|---|---|
| *(default — both)* | Core + Responses + Chat |
| `["responses"]` | Core + `SwiftOpenSkillsResponses` *(recommended)* |
| `["chat"]` | Core + `SwiftOpenSkillsChat` *(legacy Chat Completions API)* |
| `[]` | Core only — no DSL packages fetched |

```swift
// Responses integration (recommended)
dependencies: [
    .package(url: "https://github.com/RichNasz/SwiftOpenSkills.git", branch: "main",
        traits: ["responses"])
]

// Core only — no DSL dependency
dependencies: [
    .package(url: "https://github.com/RichNasz/SwiftOpenSkills.git", branch: "main",
        traits: [])
]
```

Then add the product to your target as usual:

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

## Runnable Examples

Five command-line examples are included under `Examples/`. Each is a self-contained executable you can run with `swift run`. Examples 1–3 work entirely against the local filesystem. Examples 4–5 make live calls to an LLM endpoint.

### `discover-skills` — Audit a skills directory

Scans a directory and prints a summary of every discovered skill (slug, name, description, version, tags) plus a report of any parse failures. Use this to verify a `skills/` directory before wiring it into your application.

```bash
swift run discover-skills path/to/skills/
```

### `show-catalog` — Preview the system prompt section

Loads skills from a directory and prints the exact Markdown text that SwiftOpenSkills would inject into an LLM system prompt — the catalog listing plus `activate_skill` usage guidance. Use this to confirm the model will see what you expect.

```bash
swift run show-catalog path/to/skills/
```

### `activate-skill` — Inspect handler output for a single skill

Loads skills from a directory, activates one by slug, and prints the formatted response the LLM would receive — activation header, display name, full instruction body, and resource listing if present. Use this to verify skill content before a live call.

```bash
swift run activate-skill path/to/skills/ git-commit
```

### `run-agent` — Live agent call (Open Responses API) *(recommended)*

Sends a prompt to an [Open Responses API](https://www.openresponses.org/) endpoint with a skills directory pre-loaded. The model can call `activate_skill` automatically during its response. Uses `SwiftOpenSkillsResponses`.

```bash
swift run run-agent "Help me write a conventional commit message." \
    --server-url http://127.0.0.1:1234/v1/responses \
    --model llama3 \
    --skills-dir path/to/skills/
```

If `--skills-dir` is omitted, standard platform locations are scanned automatically. `--api-key` is optional for local or unauthenticated endpoints.

### `run-agent-chat` — Live agent call (Chat Completions API)

The companion to `run-agent` for providers that expose a Chat Completions endpoint. Same arguments and behavior; the difference is the API standard used under the hood. Uses `SwiftOpenSkillsChat`.

```bash
swift run run-agent-chat "Help me write a conventional commit message." \
    --server-url http://127.0.0.1:1234/v1/chat/completions \
    --model llama3 \
    --skills-dir path/to/skills/
```

## Requirements

- Swift 6.2+
- macOS 13.0+ / iOS 16.0+
- Depends on [Yams](https://github.com/jpsim/Yams) 5.1+ for YAML frontmatter parsing (core target only)
- `responses` trait: [SwiftOpenResponsesDSL](https://github.com/RichNasz/SwiftOpenResponsesDSL) for the recommended [Open Responses API](https://www.openresponses.org/) integration
- `chat` trait: [SwiftChatCompletionsDSL](https://github.com/RichNasz/SwiftChatCompletionsDSL) for legacy Chat Completions API projects

## Spec-Driven Development

If you use an AI coding agent, consider writing WHAT and HOW specs before generating code. See [docs/SpecDrivenDevelopment.md](docs/SpecDrivenDevelopment.md) for the workflow guide and [`Spec/SwiftOpenSkills.md`](Spec/SwiftOpenSkills.md) for the full API specification.

## License

SwiftOpenSkills is available under the MIT License. See [LICENSE](LICENSE) for details.
