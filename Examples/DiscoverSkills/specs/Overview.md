# discover-skills — HOW Spec

## Source spec

`Examples/DiscoverSkills/specs/SPEC.md`

---

## Files to generate

| File | Purpose |
|------|---------|
| `Examples/DiscoverSkills/Sources/DiscoverSkills.swift` | Core logic — discovery and result production |
| `Examples/DiscoverSkills/CLI/DiscoverSkillsCLI.swift` | CLI entry point — argument parsing and output formatting |

All generated files must open with a comment crediting this spec and noting they should not be edited manually.

---

## Core type

A public, `Sendable` struct that holds a directory `URL` and exposes a single async throwing method that runs the discovery and returns a `DiscoveryResult`. The struct has no knowledge of the CLI or of output formatting.

The directory `URL` is accepted directly — path-string-to-URL conversion is the CLI's responsibility, keeping this type usable in non-CLI contexts.

---

## Discovery logic

Use `SkillStore` to load skills from the held directory using `.directory` as the sole search path. The async load call returns a `DiscoveryResult` containing both the successfully parsed skills and any non-fatal failures. Return the full result — the CLI decides what to display.

---

## CLI

Conform to `AsyncParsableCommand` from `ArgumentParser`. The command accepts a single positional string argument for the directory path and is responsible for converting it to a `URL` before passing it to the core struct.

After receiving the `DiscoveryResult`, format output as follows:

- If skills were found: open with a count line, then print each skill as a self-contained block with slug, name, description, and conditional version and tags lines. Skills should be presented in the order returned by the store (already sorted by slug).
- If failures occurred: print them in a clearly separated section, identifying each failed directory by name and showing the error description.
- If both collections are empty: print a single informative line rather than silence.

Use blank lines between skill blocks for readability. Keep the failures section visually distinct from the skills section.
