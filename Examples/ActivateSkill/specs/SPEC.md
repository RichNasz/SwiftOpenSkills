# activate-skill — WHAT Spec

## Goal

Show a developer exactly what an LLM receives when it activates a skill — the full instruction body, the activation header, and any resource file listing — so they can verify skill content before it reaches the model.

---

## Who uses this

A developer who has written a skill and wants to inspect the handler output for that skill without standing up an LLM or making API calls. They need to see what the model will be given when it calls `activate_skill`.

---

## Invocation

```
swift run activate-skill <directory> <slug>
```

| Argument    | Description |
|-------------|-------------|
| `directory` | Path to any directory containing skill subdirectories. |
| `slug`      | The slug of the skill to activate (the directory name, lowercased). |

---

## Output

The complete, unmodified text of the `activate_skill` handler response for the named skill, which includes:

- An activation header identifying the skill
- The skill's display name as a heading
- The full instruction body
- A resource file listing, if the skill has a `resources/` subdirectory

Nothing is added, wrapped, or reformatted — the output is exactly what the LLM would receive.

---

## Error behavior

- A slug that does not match any loaded skill exits with a clear error message naming the unknown slug.
- A path that does not exist or cannot be read causes the command to exit with an error message.
- Only the specified directory is scanned — no standard locations are included.

---

## Success criteria

- [ ] Output exactly matches the `activateSkillHandler` response — character for character.
- [ ] A skill with a `resources/` directory includes a resource file listing in the output.
- [ ] An unknown slug exits with a non-zero status and a meaningful error message.
- [ ] Running against the test fixtures with `valid-skill` produces the expected instruction body.
- [ ] Running against the test fixtures with `with-resources` produces output that includes a `Resources:` line.
