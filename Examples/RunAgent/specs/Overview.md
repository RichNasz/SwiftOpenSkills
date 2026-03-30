# run-agent — HOW Spec

## Source spec

`Examples/RunAgent/specs/SPEC.md`

---

## Files to generate

| File | Purpose |
|---|---|
| `Examples/RunAgent/Sources/RunAgent.swift` | Core logic — skill loading, agent creation, prompt execution |
| `Examples/RunAgent/CLI/RunAgentCLI.swift` | CLI entry point — argument parsing and output |

All generated files must open with a comment crediting this spec and noting they should not be edited manually.

---

## Core type

A public, `Sendable` struct that holds everything needed to run one agent turn: the server URL, model name, optional API key, and optional skills directory URL. It exposes a single async throwing method that accepts the prompt string and returns the agent's reply.

The skills directory is an optional `URL` — if absent, the standard search locations are used. URL conversion from strings is the CLI's responsibility.

---

## Run logic

1. Create a `SkillStore` and load skills. Use the custom directory path if one was provided; otherwise use the standard search locations.
2. Create an `LLMClient` from `SwiftOpenResponsesDSL` using the server URL and API key.
3. Call `Agent.withSkills` from `SwiftOpenSkillsResponses`, passing the store, client, and model. This registers `activate_skill` automatically and injects the skill catalog into the agent's instructions.
4. Send the prompt to the agent and return the reply string.

Errors from any step propagate to the caller without being caught — the CLI layer handles user-facing error output.

---

## CLI

Conform to `AsyncParsableCommand`. Declare:
- One positional `@Argument` for the prompt string
- `@Option(name: .long)` for `--server-url` and `--model` (both required)
- `@Option(name: .long)` for `--skills-dir` and `--api-key` (both optional `String?`)

In `run()`, convert string arguments to the appropriate types (`URL` for server URL, `URL?` for skills dir), instantiate the core struct, call its method with the prompt, and print the returned string.
