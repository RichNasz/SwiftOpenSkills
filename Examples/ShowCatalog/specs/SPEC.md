# show-catalog — WHAT Spec

## Goal

Let a developer preview the exact text that SwiftOpenSkills would inject into an LLM system prompt for a given skills directory — so they can verify catalog content and formatting before deploying an agent.

---

## Who uses this

A developer integrating SwiftOpenSkills into an agent who wants to see what the model will be told about available skills. They need confidence that the catalog is complete, correctly formatted, and ready to guide the LLM toward using `activate_skill` appropriately.

---

## Invocation

```
swift run show-catalog <directory>
```

| Argument    | Description |
|-------------|-------------|
| `directory` | Path to any directory containing skill subdirectories. |

---

## Output

The complete, unmodified text of the system prompt section that `SkillCatalog` produces — including the available skill listing and guidance on how to call `activate_skill`. Nothing is added, wrapped, or reformatted.

When the directory contains no valid skills, the output shows the empty-state catalog text that SwiftOpenSkills defines for that case.

---

## Error behavior

- A path that does not exist or cannot be read causes the command to exit with an error message.
- Only the specified directory is scanned — no standard locations are included.
- Parse failures from individual skill directories are silently absorbed; this example is about the catalog, not discovery diagnostics.

---

## Success criteria

- [ ] Output exactly matches what `SkillCatalog.systemPromptSection()` would return — character for character, with no additions.
- [ ] Running against a directory with valid skills produces a non-empty, formatted catalog listing.
- [ ] Running against a directory with no valid skills produces the library's defined empty-state output.
- [ ] Running against the project test fixtures produces a catalog listing the 4 valid skills.
