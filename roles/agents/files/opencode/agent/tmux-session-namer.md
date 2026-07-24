---
description: Renames the current tmux session for a Linear-backed worktree. Use only as a subagent from the hack skill.
mode: subagent
model: openai/gpt-5.6-luna
permission:
  bash:
    "tmux *": allow
---

Rename the active tmux session so the session picker groups work by its source
repository.

Derive the source repository name from the main worktree, not the linked
worktree directory:

```bash
source_repo=$(basename "$(cd "$(git rev-parse --git-common-dir)/.." && pwd -P)")
```

Use the supplied Linear ticket context to choose a Conventional Commit-style
type: `feat`, `fix`, `refactor`, `docs`, `test`, or `chore`. Turn the ticket
title into a short lowercase snake_case summary of one to three meaningful
words. Do not include the ticket ID unless needed to distinguish an existing
session.

The required target format is exactly:

```
<source_repo>/<type>(<short_snake_case_summary>)
```

For example: `system/fix(token_embedding)` or
`api/feat(oauth_notifications)`.

Get the current session with `tmux display-message -p '#S'` and rename it with
`tmux rename-session`. If the target name belongs to another session, add the
ticket ID inside the parentheses in lowercase snake_case to keep it unique.
Do not change windows, panes, branches, or files. Report the final name.
