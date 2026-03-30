# discover-skills CodeGen Overview

## Source specs

- `Examples/DiscoverSkills/specs/SPEC.md` — example behavior

---

## Generated files

| File                                        | Purpose                         |
|---------------------------------------------|---------------------------------|
| `Examples/DiscoverSkills/Sources/DiscoverSkills.swift` | Core logic struct    |
| `Examples/DiscoverSkills/CLI/DiscoverSkillsCLI.swift`  | CLI entry point      |

---

## Core struct

`public struct DiscoverSkills` — `Sendable`, no actor needed (all state is in `SkillStore`).

Stored properties:
- `directory: URL` — set at init, passed directly to `SkillStore.load`

The struct exists solely to separate testable core logic from CLI argument parsing.

---

## Init rules

1. Accept a `URL` (not a `String`) — path-to-URL conversion is the CLI's responsibility.
2. Store it as `directory`.

---

## run() rules

1. Create a fresh `SkillStore`.
2. Call `load` with `.directory(directory)` as the sole search path and capture the returned `DiscoveryResult`.
3. Return the `DiscoveryResult` to the caller — formatting is the CLI's responsibility.

---

## CLI rules

1. Conform to `AsyncParsableCommand`; set `commandName` to `"discover-skills"`.
2. Declare one `@Argument` for the directory path as a `String`.
3. In `run()`, convert the string argument to a `URL` using `URL(filePath:directoryHint:)`.
4. Instantiate `DiscoverSkills`, call `run()`, and receive the `DiscoveryResult`.
5. Print a header line with the skill count. For each skill, print slug, name, description, and conditional version and tags lines.
6. After the skill block, print failures with the directory name and error.
7. If both collections are empty, print a single informative message.
