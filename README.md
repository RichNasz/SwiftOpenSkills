# SwiftOpenSkills

A Swift Package Manager library providing first-class, native Swift support for the open Agent Skills standard. SwiftOpenSkills handles discovery, parsing, catalog generation, and activation of skills so they can be used alongside tools during LLM inference calls.

It is the official skills integration companion to [SwiftOpenResponsesDSL](https://github.com/RichNasz/SwiftOpenResponsesDSL) and [SwiftChatCompletionsDSL](https://github.com/RichNasz/SwiftChatCompletionsDSL).

## Overview

Agent Skills are Markdown files with YAML frontmatter that live on the filesystem. Each skill provides a set of instructions the LLM activates on demand via an `activate_skill` tool call. SwiftOpenSkills:

- Discovers skills by scanning standard and custom filesystem locations
- Parses each `SKILL.md`, extracting frontmatter metadata and the instruction body
- Generates a compact skill catalog for injection into LLM system prompts
- Provides an `activate_skill` tool handler compatible with both DSLs
- Offers a declarative `@SkillsToolBuilder` and `SkillsAgent` for each DSL

## Skill Format

Skills live in named subdirectories. The directory name (lowercased) is the stable slug used when activating a skill.

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

## Installation

SwiftOpenSkills ships as three library products. Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/RichNasz/SwiftOpenSkills", branch: "main"),
```

Then add the product(s) you need to your target:

| Product | Use when |
|---|---|
| `SwiftOpenSkills` | Core only — no DSL dependency |
| `SwiftOpenSkillsResponses` | Integrating with `SwiftOpenResponsesDSL` |
| `SwiftOpenSkillsChat` | Integrating with `SwiftChatCompletionsDSL` |

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SwiftOpenSkillsResponses", package: "SwiftOpenSkills"),
    ]
)
```

## Quick Start

### Fully Automatic (Responses DSL)

```swift
import SwiftOpenSkillsResponses

let store = SkillStore()
try await store.load()   // scans standard locations

let agent = try await Agent.withSkills(store, client: client, model: "gpt-4o")
let response = try await agent.send("Please review my code using best practices.")
// The LLM calls activate_skill(name: "code-review") automatically
```

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

### Manual Integration (Chat DSL)

```swift
import SwiftOpenSkillsChat

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
let systemPrompt = "You are a commit expert.\n\n" + skill.instructions
```

## Skill Discovery

`SkillDiscovery` and `SkillStore.load` accept an ordered array of `SkillSearchPath` values. Earlier entries take priority — if the same slug appears in multiple locations, the first occurrence wins.

```swift
// Standard locations only (cwd/skills/, ~/.config/agent-skills/, etc.)
SkillDiscovery()

// Custom directory only
SkillDiscovery(.directory(myURL))

// Custom first, then standard
SkillDiscovery(.directory(myURL), .standard)

// Standard first, then custom fallback
SkillDiscovery(.standard, .directory(fallbackURL))
```

## Specification

See [`Spec/SwiftOpenSkills.md`](Spec/SwiftOpenSkills.md) for the full specification including all API signatures, acceptance criteria, and design rationale.

## License

Apache License 2.0
