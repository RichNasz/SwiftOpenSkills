# discover-skills Example Specification

## Purpose

Scan a directory for Agent Skills and print a human-readable summary of every skill found, including any parse failures encountered during discovery.

---

## Input

| Argument    | Type   | Required | Description |
|-------------|--------|----------|-------------|
| `directory` | String | Yes      | Filesystem path to a directory containing skill subdirectories. |

---

## Tasks

1. Convert the `directory` string argument to a `URL` with a directory hint.
2. Create a `SkillStore` and load skills using only the provided directory as the search path — do not include `.standard` locations.
3. For each discovered skill, print its slug, display name, description, and any optional fields (version, tags) that are present.
4. After the skill list, print a count and details of any parse failures encountered during discovery.
5. If no skills were found and no failures occurred, print a message indicating the directory was empty or contained no valid skills.

---

## Output

Printed to stdout:

- A header line with the total number of skills found.
- One block per skill: slug, name, description, and optional version and tags on separate labeled lines.
- A failure section listing each failure's directory name and the error description.
- If the directory is empty or yields nothing, a single informative line.

---

## Constraints

- Must use `.directory(url)` as the sole search path — never `.standard`.
- Must not throw to the user; all `SkillStore.load` errors propagate naturally via `AsyncParsableCommand`.
- Discovery failures are non-fatal and must be reported separately, not mixed with the skill list.
- Output must be readable at a glance without requiring a pager.

---

## Success Criteria

- [ ] Valid skills are listed with slug, name, and description.
- [ ] Optional fields (version, tags) are shown only when present.
- [ ] Parse failures are reported in a clearly labeled section after the skill list.
- [ ] Running against an empty directory prints an informative message rather than crashing or printing nothing.
- [ ] Running against the project's test Fixtures directory produces the expected 4 skills and 4 failures.
