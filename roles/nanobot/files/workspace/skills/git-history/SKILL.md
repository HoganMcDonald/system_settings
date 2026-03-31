---
name: git-history
description: >
  Summarize recent git activity across the user's local repos. Use when asked what
  the user has been working on, for heartbeat context gathering, or when building a
  picture of recent development activity. Discovers repos automatically from ~ (depth 2),
  skipping noise dirs (.oh-my-zsh, .asdf, .cargo, agent-workspace). Can also target
  specific repos by path. Captures both recent commits and uncommitted work in progress
  (staged, unstaged, untracked). Never reads file contents or diffs — stat summaries only.
---

# Git History Skill

Runs `scripts/git_summary.sh` to collect recent commits across local repos, then
summarizes the output into a concise activity digest.

## Workflow

1. **Run the script** — use defaults or pass `--since` / `--repos` as needed
2. **Summarize** — distill output into a short narrative: what repos are active, what
   work is in progress, any notable patterns (e.g. lots of fix commits, a feature landing)
3. **Write to memory** — if running as part of a heartbeat, append a timestamped summary
   to `memory/HISTORY.md`; update `memory/MEMORY.md` if active repos have changed

## Script usage

```bash
# Default: all repos, last 24 hours
bash skills/git-history/scripts/git_summary.sh

# Custom window
bash skills/git-history/scripts/git_summary.sh --since "7 days ago"

# Specific repos only
bash skills/git-history/scripts/git_summary.sh --repos "~/repo-a,~/repo-b"
```

## Repo discovery

Auto-discovery finds `.git` dirs at `~` depth ≤ 2, excluding:
- `~/.oh-my-zsh`, `~/.asdf`, `~/.cargo` (tooling noise)
- `~/code/agent-workspace` (agent scratch space)

Known active repos are stored in `memory/MEMORY.md` under **Project Context**. Prefer
targeting those explicitly during heartbeat runs to keep output focused.

## Memory format

When writing to `HISTORY.md`:
```
[YYYY-MM-DD HH:MM] git-history: <1-2 sentence summary of activity>
```

When updating `MEMORY.md` active repos list, keep it to repo name + current focus, e.g.:
```
- my-app (~/my-app) — auth refactor
- my-cli (~/my-cli) — new subcommand
- dotfiles (~/dotfiles) — cleanup
```

## Rules

- **Stat summaries only** — never run `git diff` or read file contents; `--stat` tail lines only
- **No-merge commits** — `--no-merges` is set by default; keeps signal clean
- **Skip inactive repos** — repos with no commits and no uncommitted work are silently skipped
- **Don't push or commit** — read-only, always
