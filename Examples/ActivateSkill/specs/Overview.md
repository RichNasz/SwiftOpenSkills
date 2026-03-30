# activate-skill CodeGen Overview

## Source specs

- `Examples/ActivateSkill/specs/SPEC.md` — example behavior

---

## Generated files

| File                                           | Purpose                         |
|------------------------------------------------|---------------------------------|
| `Examples/ActivateSkill/Sources/ActivateSkill.swift` | Core logic struct         |
| `Examples/ActivateSkill/CLI/ActivateSkillCLI.swift`  | CLI entry point           |

---

## Core struct

`public struct ActivateSkill` — `Sendable`, no actor needed.

Stored properties:
- `directory: URL` — set at init, passed to `SkillStore.load`

The slug is not stored on the struct — it is passed per-call to `run(slug:)`.

---

## Init rules

1. Accept a `URL` — path-to-URL conversion is the CLI's responsibility.
2. Store it as `directory`.

---

## run(slug:) rules

1. Create a fresh `SkillStore`.
2. Call `load` with `.directory(directory)`.
3. Build the handler JSON argument string with the slug interpolated into `{"name":"<slug>"}`.
4. Call `activateSkillHandler(argumentsJSON:)` on the store and return the result.
5. Do not catch errors — let them propagate to `ArgumentParser` for user-facing error output.

---

## CLI rules

1. Conform to `AsyncParsableCommand`; set `commandName` to `"activate-skill"`.
2. Declare two `@Argument` properties: `directory` (path string) and `slug` (skill slug string), in that order.
3. In `run()`, convert the directory string to a `URL` and instantiate `ActivateSkill`.
4. Call `run(slug:)` with the slug argument and print the returned string directly.
