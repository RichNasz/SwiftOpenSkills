# show-catalog — HOW Spec

## Source spec

`Examples/ShowCatalog/specs/SPEC.md`

---

## Files to generate

| File | Purpose |
|------|---------|
| `Examples/ShowCatalog/Sources/ShowCatalog.swift` | Core logic — loading and catalog production |
| `Examples/ShowCatalog/CLI/ShowCatalogCLI.swift` | CLI entry point — argument parsing and output |

All generated files must open with a comment crediting this spec and noting they should not be edited manually.

---

## Core type

A public, `Sendable` struct that holds a directory `URL` and exposes a single async throwing method that returns the catalog section string. The struct has no knowledge of the CLI or of printing.

The directory `URL` is accepted directly — path-string-to-URL conversion is the CLI's responsibility.

---

## Catalog logic

Use `SkillStore` to load skills from the held directory using `.directory` as the sole search path. Discovery failures are not surfaced — the purpose of this example is catalog output, not discovery diagnostics. After loading, retrieve the `SkillCatalog` from the store and return the result of `systemPromptSection()`. The returned string is the complete, unmodified catalog text.

---

## CLI

Conform to `AsyncParsableCommand` from `ArgumentParser`. The command accepts a single positional string argument for the directory path, converts it to a `URL`, instantiates the core struct, and calls its method. Print the returned string directly with no additional formatting, headers, or trailing newlines beyond what the catalog text itself contains.
