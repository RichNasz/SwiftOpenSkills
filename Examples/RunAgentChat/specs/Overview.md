# run-agent-chat — HOW Spec

## Source spec

`Examples/RunAgentChat/specs/SPEC.md`

---

## Files to generate

| File | Purpose |
|---|---|
| `Examples/RunAgentChat/Sources/RunAgentChat.swift` | Core logic — skill loading, agent creation, prompt execution |
| `Examples/RunAgentChat/CLI/RunAgentChatCLI.swift` | CLI entry point — argument parsing and output |

All generated files must open with a comment crediting this spec and noting they should not be edited manually.

---

## Core type

Identical shape to `RunAgent` — a public, `Sendable` struct holding server URL, model name, optional API key, and optional skills directory URL, with a single async throwing method accepting a prompt string and returning the reply.

The only difference from `RunAgent` is the integration target: this struct uses `SwiftOpenSkillsChat` types instead of `SwiftOpenResponsesDSL` types.

---

## Run logic

1. Create a `SkillStore` and load skills using the same conditional path logic as `RunAgent`.
2. Create an `LLMClient` from `SwiftChatCompletionsDSL` using the server URL and API key.
3. Call `Agent.withSkills` from `SwiftOpenSkillsChat`, passing the store, client, and model. This registers `activate_skill` and injects the catalog into the system prompt.
4. Send the prompt and return the reply string.

Errors propagate without being caught.

---

## CLI

Identical structure to `RunAgentCLI` — same arguments, same conversion logic, same output behavior. The only difference is instantiating `RunAgentChat` instead of `RunAgent`.

`commandName` is `"run-agent-chat"` to distinguish it from the Responses DSL variant.
