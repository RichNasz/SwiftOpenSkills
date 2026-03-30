# run-agent — WHAT Spec

## Goal

Let a developer send a single prompt to an Open Responses API endpoint with their skills directory pre-loaded, and see what the agent replies — including any skill the model chose to activate automatically.

---

## Who uses this

A developer who has written skills and wants to verify they work end-to-end with a real model before integrating the library into their application. They point the command at their server, their model, their skills directory, and a prompt — and watch the agent work.

---

## Invocation

```
swift run run-agent <prompt> --server-url <url> --model <model> [--skills-dir <path>] [--api-key <key>]
```

| Argument | Required | Description |
|---|---|---|
| `prompt` | Yes | The message to send to the agent. |
| `--server-url` | Yes | Full URL of an Open Responses API endpoint. |
| `--model` | Yes | Model identifier (e.g. `gpt-4o`, `llama3`). |
| `--skills-dir` | No | Path to a directory of skills. If omitted, standard locations are scanned. |
| `--api-key` | No | API key for authentication. Omit for local or unauthenticated endpoints. |

---

## Output

The agent's text reply, printed to stdout. If the model activated a skill during the response, the output reflects the reply produced after skill activation — the developer does not see the raw tool calls.

---

## Error behavior

- An invalid or unreachable server URL exits with an error message.
- An API error (network failure, authentication failure, bad model name) exits with an error message.
- If no skills are found in the specified or standard locations, the agent still runs — it simply has no skills to offer the model.

---

## Success criteria

- [ ] The agent's text reply is printed to stdout.
- [ ] Running with `--help` prints usage without requiring a live server.
- [ ] Omitting `--skills-dir` causes the command to scan standard locations.
- [ ] An unreachable server URL produces a clear error rather than a crash.
