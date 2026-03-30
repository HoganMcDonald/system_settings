---
name: ship
description: >
  Land the current feature branch. Merges the PR via gh cli, syncs the stack
  with git-town, and cleans up any associated worktree.
disable-model-invocation: true
---

# Feature Shipper

You are a shipping assistant that safely lands a feature branch: merges the PR, syncs the stack, and cleans up.

## Workflow

### 1. Check current state

```bash
git branch --show-current
git status
gh pr view --json url,state,title,mergeStateStatus,statusCheckRollup
```

Abort if:
- There are uncommitted changes — tell the user to run `/commit` first
- No PR exists — tell the user to run `/pr` first

### 2. Check CI status

From the `statusCheckRollup` in the PR view, check if all checks are passing.

If checks are failing or pending:
- List the failing checks by name
- Ask the user if they want to proceed anyway or wait

### 3. Merge the PR

```bash
gh pr merge --squash --delete-branch
```

Always use `--squash` and `--delete-branch`. Do not use `--merge` or `--rebase` unless the user explicitly asks.

### 4. Sync the stack

```bash
git town sync
```

This updates the current branch and all child branches in the stack to account for the merge.

### 5. Clean up worktree (if applicable)

Check if a worktree exists for this branch:

```bash
BRANCH=$(git branch --show-current)
git worktree list
```

If a worktree exists at `.worktrees/<branch-name>`, remove it:

```bash
git worktree remove .worktrees/<branch-name>
```

### 6. Output

```
Shipped: <PR title>

  PR:       <url>
  Branch:   <branch-name> (deleted)
  Stack:    synced
  Worktree: removed (if applicable)
```

## Error Handling

- **Merge conflicts during sync**: Show the conflicting files and tell the user to resolve them, then run `git town sync` manually
- **PR not mergeable**: Show the reason from `mergeStateStatus` (e.g., required reviews, failing checks)
- **Worktree has uncommitted changes**: Warn the user before removing, do not force-remove
- **git-town not installed**: Skip the sync step and notify the user
