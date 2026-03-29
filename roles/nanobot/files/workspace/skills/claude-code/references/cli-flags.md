# Claude Code CLI Reference

## Core invocation

```bash
# Non-interactive (required for scripted use)
claude -p "prompt here"

# Bare mode — faster, deterministic, skips ~/.claude auto-discovery
claude --bare -p "prompt here"
```

## Key flags

| Flag | Values | Notes |
|---|---|---|
| `--bare` | — | Skip hooks, plugins, CLAUDE.md, MCP auto-discovery. Recommended for scripted calls. |
| `--allowedTools` | `Read,Edit,Bash,Glob,Grep` | Pre-approve tools to avoid permission prompts |
| `--permission-mode` | `acceptEdits`, `bypassPermissions`, `default`, `plan` | `acceptEdits` auto-approves file edits but still prompts for Bash |
| `--output-format` | `text`, `json`, `stream-json` | `json` returns `{ result, session_id, usage }` |
| `--model` | `haiku`, `sonnet`, `opus` | Route by task complexity |
| `--agent` | agent name | Use a sub-agent from `~/.claude/agents/` |
| `--add-dir` | path | Grant tool access to additional directories |
| `--append-system-prompt` | string | Inject extra system context |
| `--append-system-prompt-file` | path | Load system context from file |
| `--worktree` | optional name | Create isolated git worktree for this session |
| `-c` / `--continue` | — | Resume most recent session in cwd |
| `--resume` | session ID | Resume a specific session |
| `--max-budget-usd` | amount | Cap spend (only with `--print`) |

## Output format (json)

```json
{
  "result": "...",
  "session_id": "uuid",
  "usage": { "input_tokens": 0, "output_tokens": 0 }
}
```

## Existing sub-agents

Located at `~/.claude/agents/`:

- **researcher** — haiku, read-only (Read, Grep, Glob, Bash). Maps architecture, traces deps, returns structured summary.
- **reviewer** — sonnet, read-only. Reviews diffs for correctness, simplicity, patterns. Groups by Critical > Warnings > Suggestions.

## Model routing guide

| Task | Model |
|---|---|
| Exploration, research, reading | `haiku` |
| General edits, small fixes | `sonnet` |
| Complex reasoning, architecture | `opus` |

## Auth note

Auth is via keychain/OAuth. Do NOT use `--bare` — it skips keychain reads and will
always return "Not logged in" in this setup. Standard `claude -p` picks up auth automatically.
