---
name: worktree
description: >
  Create a lightweight worktree for manual exploration or parallel work.
  Stacks a branch via git-town, creates a worktree, and opens it in a new
  tmux window without launching an agent.
disable-model-invocation: true
---

# Worktree Creator

You are a worktree assistant that sets up a branch and worktree for parallel manual work. Unlike `/dispatch-plan`, this does NOT launch a Claude agent — it creates a workspace for you to work in directly.

## Workflow

### 1. Determine the branch name

If the user provides a name, use it. Otherwise, ask. The name should be:
- kebab-case, under 50 characters
- Descriptive of the work (e.g. `explore-auth-refactor`, `spike-new-api`)

### 2. Check current state

```bash
git status --short
git branch --show-current
```

Warn if there are uncommitted changes — they won't be visible in the new worktree.

### 3. Create the branch and worktree

Always use `git town append` to stack on the current branch:

```bash
CURRENT=$(git branch --show-current)
git town append <branch-name>
git checkout $CURRENT
mkdir -p .worktrees
git worktree add .worktrees/<branch-name> <branch-name>
```

### 4. Open in a new tmux window

```bash
WORKTREE_PATH="$(pwd)/.worktrees/<branch-name>"
tmux new-window -n "<branch-name>" -c "$WORKTREE_PATH"
```

Window name is the branch name only — no `agent:` prefix (this is for manual work, not agents).

### 5. Output

```
Worktree ready: <branch-name>

  Branch:   <branch-name> (stacked on <current-branch>)
  Worktree: .worktrees/<branch-name>
  Window:   <branch-name>

Switch to the tmux window to start working.
```

## Worktree Cleanup

When done with the worktree:

```bash
git worktree remove .worktrees/<branch-name>
git town sync
```

If the branch was merged upstream:
```bash
git worktree remove .worktrees/<branch-name>
git branch -d <branch-name>
```

## Error Handling

- **Branch already exists**: Suggest a different name or check if the worktree already exists with `git worktree list`
- **Dirty working tree**: Warn but don't block — uncommitted changes stay on the current branch
- **Not in tmux**: Print the worktree path and suggest `cd`ing to it manually
- **git-town not installed**: Fall back to `git checkout -b <branch-name>` then `git checkout -` and create the worktree

## Difference from /dispatch-plan

| | `/worktree` | `/dispatch-plan` |
|---|---|---|
| Who works in it | You | A Claude agent |
| tmux window prefix | `<branch-name>` | `agent:<branch-name>` |
| Plan file | None | `.claude-plan.md` |
| Use case | Manual exploration, parallel work | Delegated implementation |
