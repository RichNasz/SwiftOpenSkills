# run-agent-chat — WHAT Spec

## Goal

The same end-to-end skill verification as `run-agent`, but targeting a Chat Completions API endpoint instead of an Open Responses API endpoint — for developers working with models or providers that expose the Chat Completions interface.

---

## Who uses this

A developer whose LLM provider or local model server exposes a Chat Completions endpoint (`/v1/chat/completions`) rather than a Responses endpoint. They want the same skill-aware agent behavior as `run-agent` against the API they already have.

---

## Invocation

```
swift run run-agent-chat <prompt> --server-url <url> --model <model> [--skills-dir <path>] [--api-key <key>]
```

| Argument | Required | Description |
|---|---|---|
| `prompt` | Yes | The message to send to the agent. |
| `--server-url` | Yes | Full URL of a Chat Completions API endpoint. |
| `--model` | Yes | Model identifier (e.g. `gpt-4o`, `llama3`). |
| `--skills-dir` | No | Path to a directory of skills. If omitted, standard locations are scanned. |
| `--api-key` | No | API key for authentication. Omit for local or unauthenticated endpoints. |

---

## Output

The agent's text reply, printed to stdout. Behavior is identical to `run-agent` from the user's perspective — the difference is only which API standard is used under the hood.

---

## Error behavior

Identical to `run-agent`: invalid URLs, API errors, and authentication failures exit with error messages.

---

## Success criteria

- [ ] The agent's text reply is printed to stdout.
- [ ] Running with `--help` prints usage without requiring a live server.
- [ ] Omitting `--skills-dir` causes the command to scan standard locations.
- [ ] An unreachable server URL produces a clear error rather than a crash.
- [ ] This example does not exist without the `run-agent` (Responses DSL) example also existing.
