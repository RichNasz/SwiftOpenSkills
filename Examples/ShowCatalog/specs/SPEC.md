# show-catalog Example Specification

## Purpose

Load skills from a directory and print the complete system prompt catalog section that SwiftOpenSkills would inject into an LLM — giving developers a way to preview exactly what the model sees before activation.

---

## Input

| Argument    | Type   | Required | Description |
|-------------|--------|----------|-------------|
| `directory` | String | Yes      | Filesystem path to a directory containing skill subdirectories. |

---

## Tasks

1. Convert the `directory` string argument to a `URL` with a directory hint.
2. Create a `SkillStore` and load skills using only the provided directory as the search path.
3. Retrieve the `SkillCatalog` from the store.
4. Return the result of `SkillCatalog.systemPromptSection()` — the full Markdown block that includes the skill listing and `activate_skill` usage guidance.

---

## Output

Printed to stdout: the complete string produced by `SkillCatalog.systemPromptSection()`, unmodified. This is the exact text a caller would prepend to an LLM system prompt.

---

## Constraints

- Must use `.directory(url)` as the sole search path — never `.standard`.
- Must print the `systemPromptSection()` output verbatim, with no additional formatting or headers added.
- Parse failures from discovery are silently absorbed by `SkillStore.load` — this example does not report them.

---

## Success Criteria

- [ ] Output matches `SkillCatalog.systemPromptSection()` exactly, character for character.
- [ ] Running against a directory with valid skills produces a non-empty catalog listing.
- [ ] Running against a directory with no valid skills produces the empty-state catalog output defined by `SkillCatalog`.
- [ ] Running against the project's test Fixtures directory lists the 4 valid skills.
