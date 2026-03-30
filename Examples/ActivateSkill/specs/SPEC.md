# activate-skill Example Specification

## Purpose

Load skills from a directory and activate one by slug, printing the formatted output the LLM would receive in response to an `activate_skill` tool call — so developers can verify skill content and resource listings before deploying.

---

## Input

| Argument    | Type   | Required | Description |
|-------------|--------|----------|-------------|
| `directory` | String | Yes      | Filesystem path to a directory containing skill subdirectories. |
| `slug`      | String | Yes      | The skill slug (lowercased directory name) to activate. |

---

## Tasks

1. Convert the `directory` string argument to a `URL` with a directory hint.
2. Create a `SkillStore` and load skills using only the provided directory as the search path.
3. Construct the JSON arguments string `{"name":"<slug>"}` expected by the handler.
4. Call `SkillStore.activateSkillHandler(argumentsJSON:)` with the constructed JSON.
5. Return the formatted handler output string.

---

## Output

Printed to stdout: the exact string produced by `SkillStore.activateSkillHandler`, which includes:

- An activation header: `[Skill Activated: <slug>]`
- The skill's display name as a Markdown heading
- The full instruction body
- A `Resources:` line listing filenames if a `resources/` subdirectory exists

---

## Constraints

- Must use `.directory(url)` as the sole search path — never `.standard`.
- Must not hand-construct the handler output — `activateSkillHandler` is the authoritative source of the formatted response.
- If the slug is not found, `activateSkillHandler` throws `SkillError.skillNotFound`; this propagates naturally to the CLI and prints an error message.
- The JSON arguments string must match the exact format expected by the handler: `{"name":"<slug>"}`.

---

## Success Criteria

- [ ] Output matches `activateSkillHandler` output exactly for a valid slug.
- [ ] The header line `[Skill Activated: <slug>]` is present.
- [ ] A skill with a `resources/` directory includes a `Resources:` line with filenames.
- [ ] An unknown slug exits with a non-zero status and a meaningful error message from `ArgumentParser`.
- [ ] Running against the Fixtures directory with `valid-skill` produces the expected instruction body.
