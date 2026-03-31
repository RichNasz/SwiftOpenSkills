# SwiftOpenSkills

## Architecture

SwiftOpenSkills is a Swift Package Manager library providing first-class, native Swift support for the open Agent Skills standard. It discovers, parses, and activates skill files (`SKILL.md`) from the filesystem, generating LLM system prompt catalogs and `activate_skill` tool handlers compatible with both `SwiftOpenResponsesDSL` and `SwiftChatCompletionsDSL`.

### File Structure

```
Sources/
  SwiftOpenSkills/               ← Core target (Yams only)
    SkillErrors.swift            — Typed SkillError enum (all error cases)
    Skill.swift                  — Core Skill model (id = slug = directory name)
    SkillFrontmatter.swift       — Internal struct for decoded YAML fields
    SkillParser.swift            — Internal parser: CRLF-safe, Yams-based
    SkillSearchPath.swift        — Composable search path (.standard, .directory)
    SkillDiscovery.swift         — Actor: scans directories, collects failures
    SkillCatalog.swift           — System prompt catalog generation
    SkillStore.swift             — Primary actor entry point

  SwiftOpenSkillsResponses/      ← Responses DSL integration (`responses` trait)
    SkillStore+Responses.swift   — responsesAgentTool(strict:) extension
    Skills.swift                 — Skills struct (wraps SkillStore, provides AgentTool)
    Agent+Skills.swift           — Agent.withSkills static factory
    SkillsToolBuilder.swift      — @resultBuilder accepting AgentTool + Skills
    SkillsAgent.swift            — Actor wrapper around Agent

  SwiftOpenSkillsChat/           ← Chat DSL integration (`chat` trait)
    SkillStore+Chat.swift        — chatAgentTool() extension
    Skills+Chat.swift            — Skills struct + Agent.withSkills for Chat DSL
    SkillsAgent+Chat.swift       — Actor wrapper; uses streamSend not stream

Tests/
  SwiftOpenSkillsTests/          ← 36 tests across 6 suites (Swift Testing)
    Fixtures/                    — 9 fixture skill directories for parser/discovery tests
  SwiftOpenSkillsResponsesTests/ — Placeholder (integration tests)
  SwiftOpenSkillsChatTests/      — Placeholder (integration tests)

Examples/
  BasicUsage.swift               — Non-runnable code reference for all integration patterns
  DiscoverSkills/                — `swift run discover-skills <dir>` — lists discovered skills
  ShowCatalog/                   — `swift run show-catalog <dir>` — prints system prompt catalog
  ActivateSkill/                 — `swift run activate-skill <dir> <slug>` — prints handler output
  RunAgent/                      — `swift run run-agent <prompt> --server-url <url> --model <id>` — live LLM call (Responses DSL)
  RunAgentChat/                  — `swift run run-agent-chat <prompt> --server-url <url> --model <id>` — live LLM call (Chat DSL)

Spec/SwiftOpenSkills.md          — Full specification
```

### Design Patterns

- **Actor-safe, async-first**: `SkillStore` and `SkillDiscovery` are Swift actors. All mutating operations and filesystem I/O are async.
- **Slug = name = id**: `Skill.id` is the lowercased directory name. The YAML `name` field must equal the slug per the agentskills.io spec (slug-format, max 64 chars, lowercase alphanumeric + hyphens).
- **Traits-gated integrations**: `SwiftOpenSkillsResponses` and `SwiftOpenSkillsChat` are gated by the `responses` and `chat` SE-0450 traits respectively. Both are enabled by default in the package manifest so `swift build` and `swift test` work without flags. External consumers opt in by specifying `traits:` in their package dependency declaration.
- **Non-fatal discovery**: Parse failures are collected into `DiscoveryResult.failures` and do not abort the scan. The caller decides how to handle them.
- **First-occurrence wins**: When scanning multiple `SkillSearchPath` values in order, the first directory that provides a given slug takes priority.
- **No Yams in public API**: `SkillParser` is internal. `Yams.load(yaml:) -> [String: Any]` is used (not Codable) to avoid leaking Yams types into the public surface.
- **Array-based Agent.init**: Responses and Chat DSL `Agent.withSkills` use the array-based `Agent.init(tools:[]:toolHandlers:)` overload rather than `@AgentToolBuilder` closures, because `buildArray` is incompatible with the outer `buildBlock` in the DSL result builders.
- **`async` stream/streamSend**: Both `SkillsAgent` wrappers mark their streaming methods as `async` to satisfy Swift 6 actor isolation when calling into the underlying `Agent` actor.

### Dependencies

| Dependency | Role | Trait |
|---|---|---|
| [Yams](https://github.com/jpsim/Yams.git) (`from: "5.1.0"`) | YAML frontmatter parsing | always |
| [SwiftOpenResponsesDSL](https://github.com/RichNasz/SwiftOpenResponsesDSL) (`branch: "main"`) | [Open Responses API](https://www.openresponses.org/) agent integration *(recommended)* | `responses` |
| [SwiftChatCompletionsDSL](https://github.com/RichNasz/SwiftChatCompletionsDSL) (`branch: "main"`) | Legacy Chat Completions API agent integration | `chat` |
| [SwiftLLMToolMacros](https://github.com/RichNasz/SwiftLLMToolMacros) (`branch: "main"`) | `ToolDefinition` and `JSONSchemaValue` types | `responses` or `chat` |
| [swift-argument-parser](https://github.com/apple/swift-argument-parser) (`from: "1.5.0"`) | CLI argument parsing | always |

### Build & Test

```bash
swift build
swift test
```

All three targets must compile cleanly under Swift 6 strict concurrency. Both integration traits are enabled by default, so no additional flags are needed. The core test suite has 77 tests covering parser, discovery, store, handler, catalog, resources, aliases, catalog token estimation, variable substitution, and list-skills handler.

## Spec-Driven Development

This project follows a spec-first workflow. See `Spec/SwiftOpenSkills.md` for the current specification and `docs/SpecDrivenDevelopment.md` for the process.

Skills for AI coding agents will be added to `skills/` as features are defined.
