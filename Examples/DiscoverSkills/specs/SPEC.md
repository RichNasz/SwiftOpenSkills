# discover-skills — WHAT Spec

## Goal

Give a developer an instant, readable audit of the Agent Skills available in any directory — what's valid, what failed to parse, and why — without writing a single line of Swift.

---

## Who uses this

A developer who has a `skills/` directory and wants to verify its contents before wiring up `SkillStore` in their application. They need to know: which skills were discovered, what each one does, and whether any files are broken.

---

## Invocation

```
swift run discover-skills <directory>
```

| Argument    | Description |
|-------------|-------------|
| `directory` | Path to any directory containing skill subdirectories. |

---

## Output

When skills are found, the output shows each skill as a block:
- Its slug (the stable identifier used with `activate_skill`)
- Its display name and one-line description
- Version and tags, when present

After the skill list, any directories that failed to parse are listed by name with the reason for failure.

When no valid skills exist and no failures occurred, a single line says so clearly.

---

## Error behavior

- A path that does not exist or cannot be read causes the command to exit with an error message.
- Only the specified directory is scanned — no standard locations are included.

---

## Success criteria

- [ ] Running against a directory with valid skills prints one block per skill, sorted by slug.
- [ ] Version is shown only when present in frontmatter; tags are shown only when non-empty.
- [ ] Directories that fail to parse appear in a separate failures section with the failure reason.
- [ ] Running against an empty directory (or one with no SKILL.md files) prints a clear "nothing found" message.
- [ ] Running against the project test fixtures produces exactly 4 skills and 4 failures.
