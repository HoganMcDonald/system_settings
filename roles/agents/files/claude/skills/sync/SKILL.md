---
name: sync
description: >
  Sync the current branch stack with git-town. Detects conflicts, explains
  what diverged, and guides resolution.
disable-model-invocation: true
---

# Stack Syncer

You are a sync assistant that runs `git town sync` and helps resolve any conflicts or issues that arise.

## Workflow

### 1. Check current state

```bash
git status --short
git branch --show-current
git town status 2>/dev/null
```

If there are uncommitted changes, ask the user to stash or commit them first:
```bash
git stash list
```

### 2. Run sync

```bash
git town sync
```

Capture the output. Watch for:
- Successful sync (no action needed)
- Rebase conflicts
- Branch deletion notices (remote branches deleted after merge)
- "Perennial branch" warnings

### 3. Handle conflicts

If `git town sync` stops at a conflict:

```bash
git status
git diff --name-only --diff-filter=U
```

For each conflicting file:
- Show the conflict markers
- Explain what each side represents (local changes vs upstream)
- Help the user resolve: either accept one side, or merge manually

After resolving each file:
```bash
git add <resolved-file>
git town sync --continue
```

### 4. Handle deleted remote branches

If git-town reports that a remote branch was deleted (e.g. merged via PR):
- Confirm the local branch can be deleted
- Let git-town handle the cleanup automatically

### 5. Verify result

```bash
git log --oneline -5
git town status 2>/dev/null
```

### 6. Output

On success:
```
Synced: <branch-name>

  Stack:  <parent> → <branch> → <child branches, if any>
  Result: up to date with origin
```

On conflict:
```
Conflict in <file>

  Ours:   <description of local change>
  Theirs: <description of upstream change>

Resolve the conflict, then I'll continue the sync.
```

## Error Handling

- **Not in a git repo**: Inform the user
- **git-town not installed**: Fall back to `git pull --rebase origin $(git branch --show-current)`
- **Sync already in progress**: Show `git town status` and help the user continue or abort
- **To abort a stuck sync**: `git town sync --abort`
