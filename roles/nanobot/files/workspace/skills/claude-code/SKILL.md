---
name: claude-code
description: >
  Run Claude Code (the `claude` CLI) to perform light dev work on the user's behalf.
  Use for tasks like fixing bugs, addressing PR feedback, scaffolding code, exploring
  a codebase, or running a code review. Always show the user what you plan to run
  before executing. Never commit or push without explicit user approval.
---

# Claude Code Skill

Drives the `claude` CLI (`/opt/homebrew/bin/claude`) non-interactively to perform
dev tasks. The user stays in the driver's seat — propose before acting, report results
clearly, never commit/push autonomously.

## Workflow

1. **Propose** — describe the task and the exact command you'll run. Wait for approval
   unless the user has already given a clear go-ahead in the same message.
2. **Run** — execute via `exec` tool with appropriate flags (see below).
3. **Report** — summarize what changed. For edits, show a brief diff or list of files
   touched. For research tasks, return the structured summary.
4. **Offer next step** — suggest a logical follow-up (review, commit, etc.) but don't
   act on it automatically.

## Command patterns

### Research / read-only exploration
```bash
claude -p "PROMPT" \
  --allowedTools "Read,Grep,Glob,Bash" \
  --agent researcher \
  --add-dir PATH \
  --output-format json
```

### Light edits (fix, address feedback, scaffold)
```bash
claude -p "PROMPT" \
  --allowedTools "Read,Edit,Bash,Glob,Grep" \
  --permission-mode acceptEdits \
  --append-system-prompt-file ~/.claude/CLAUDE.md \
  --add-dir PATH \
  --model sonnet \
  --output-format json
```

### Code review (post-edit)
```bash
claude -p "Review the changes in this repo" \
  --agent reviewer \
  --add-dir PATH \
  --output-format json
```

## Agent workspace

Always clone repos to `~/code/agent-workspace/<repo-name>` before running edit tasks.
Never work in the user's own checkout. This avoids conflicts when the user is actively
working in the same repo.

```bash
# Clone if not already present
git clone <repo-url> ~/code/agent-workspace/<repo-name>

# Or pull latest if already cloned
git -C ~/code/agent-workspace/<repo-name> fetch --all
git -C ~/code/agent-workspace/<repo-name> checkout <branch>
git -C ~/code/agent-workspace/<repo-name> pull
```

Then pass `--add-dir ~/code/agent-workspace/<repo-name>` to the claude invocation.

## Rules

- **Do NOT use `--bare`** — auth is via keychain/OAuth which bare mode skips. Bare mode will always return "Not logged in".
- **Always use `--output-format json`** — parse `result` field to report back cleanly.
- **Always pass `--add-dir`** pointing at the relevant repo root so tools can access files.
- **Inject `~/.claude/CLAUDE.md`** via `--append-system-prompt-file` for edit tasks so Claude
  respects the user's coding conventions (conventional commits, simplicity, no dead code, etc.).
- **Never run `git commit`, `git push`, or `gh pr`** — surface the changes, let the user decide.
- **Model routing**: haiku for exploration, sonnet for edits, opus only for complex reasoning.
- **Working directory**: always `cd` into the repo before running, or use `--add-dir`.

## Parsing output

```python
import json, subprocess
result = subprocess.run([...], capture_output=True, text=True)
data = json.loads(result.stdout)
print(data["result"])
```

Or inline with shell:
```bash
claude -p "..." --output-format json | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])"
```

## Reference

See `references/cli-flags.md` for full flag reference, model routing guide, and sub-agent details.
