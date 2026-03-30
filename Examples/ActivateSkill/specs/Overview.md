# activate-skill — HOW Spec

## Source spec

`Examples/ActivateSkill/specs/SPEC.md`

---

## Files to generate

| File | Purpose |
|------|---------|
| `Examples/ActivateSkill/Sources/ActivateSkill.swift` | Core logic — loading and handler invocation |
| `Examples/ActivateSkill/CLI/ActivateSkillCLI.swift` | CLI entry point — argument parsing and output |

All generated files must open with a comment crediting this spec and noting they should not be edited manually.

---

## Core type

A public, `Sendable` struct that holds a directory `URL` and exposes a single async throwing method that accepts a slug string and returns the handler output string. The struct has no knowledge of the CLI or of printing.

The directory `URL` is accepted directly — path-string-to-URL conversion is the CLI's responsibility. The slug is a per-call parameter rather than a stored property, since the struct could reasonably be used to activate multiple skills against the same directory.

---

## Activation logic

Use `SkillStore` to load skills from the held directory using `.directory` as the sole search path. Then invoke the store's `activateSkillHandler`, passing the slug in the JSON argument format the handler expects. Return the handler's output string without modification.

Do not catch errors — let them propagate. If the slug is not found, the handler throws a typed `SkillError`; the CLI layer and `ArgumentParser` will surface this as a user-facing error message.

---

## CLI

Conform to `AsyncParsableCommand` from `ArgumentParser`. The command accepts two positional string arguments in order: the directory path, then the skill slug. Convert the directory path to a `URL`, instantiate the core struct, and call its method with the slug. Print the returned string directly with no additional formatting.

Errors thrown by the core method — including unknown slugs — propagate naturally through `AsyncParsableCommand` and are formatted as error output by `ArgumentParser`.
