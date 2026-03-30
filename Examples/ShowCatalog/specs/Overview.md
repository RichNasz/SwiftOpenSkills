# show-catalog CodeGen Overview

## Source specs

- `Examples/ShowCatalog/specs/SPEC.md` — example behavior

---

## Generated files

| File                                       | Purpose                         |
|--------------------------------------------|---------------------------------|
| `Examples/ShowCatalog/Sources/ShowCatalog.swift` | Core logic struct         |
| `Examples/ShowCatalog/CLI/ShowCatalogCLI.swift`  | CLI entry point           |

---

## Core struct

`public struct ShowCatalog` — `Sendable`, no actor needed.

Stored properties:
- `directory: URL` — set at init, passed to `SkillStore.load`

---

## Init rules

1. Accept a `URL` — path-to-URL conversion is the CLI's responsibility.
2. Store it as `directory`.

---

## run() rules

1. Create a fresh `SkillStore`.
2. Call `load` with `.directory(directory)` and discard the returned `DiscoveryResult` (failures are not surfaced by this example).
3. Call `catalog()` on the store to obtain a `SkillCatalog`.
4. Return `catalog.systemPromptSection()` as a `String`.

---

## CLI rules

1. Conform to `AsyncParsableCommand`; set `commandName` to `"show-catalog"`.
2. Declare one `@Argument` for the directory path as a `String`.
3. In `run()`, convert the string to a `URL` and instantiate `ShowCatalog`.
4. Call `run()` and print the returned string directly — no additional formatting.
