---
name: dispatch-plan
description: >
  Dispatch approved implementation plans to dedicated git worktrees. After a plan
  is approved via ExitPlanMode, use this skill to create a stacked branch, set up
  a worktree, write the plan to a file, and launch a Claude Code session in a new
  tmux window to execute it. This keeps the current session free as a dispatcher
  while background agents work concurrently.
user-invocable: false
---

# Plan Dispatcher

After a plan is approved via ExitPlanMode, dispatch it to a new worktree with its own Claude Code session in a tmux window. The current session stays free as a dispatcher.

## Workflow

### 1. Generate a branch name

From the plan title or description, create a kebab-case branch name:
- Lowercase, hyphens only, under 50 characters, truncate at word boundary
- "Add user authentication" -> `add-user-authentication`
- "Fix null pointer in user lookup" -> `fix-null-pointer-in-user-lookup`

### 2. Create branch and worktree

Always use `git town append` to stack on the current branch.

```bash
CURRENT=$(git branch --show-current)
git town append <branch-name>
git checkout $CURRENT
mkdir -p .worktrees
git worktree add .worktrees/<branch-name> <branch-name>
```

### 3. Write the plan

Write the full approved plan to `.worktrees/<branch-name>/.claude-plan.md`. The file must be completely self-contained — the receiving Claude session has no prior conversation history.

The plan file MUST include:

#### Context
- Plan title and summary
- Relevant codebase context (architecture, patterns, key file locations)
- Any constraints or decisions from the planning conversation
- The worktree root path for reference

#### Implementation steps
- The step-by-step implementation plan exactly as approved
- Concrete file paths, line numbers, and code changes
- Each step should be independently understandable

#### Verification
- Test commands to run
- Lint commands to run
- Any other validation steps

#### Cleanup
```markdown
## Cleanup

After all steps are complete and verified, delete this plan file.
```

### 4. Launch Claude in a tmux window

```bash
WORKTREE_PATH="$(pwd)/.worktrees/<branch-name>"
tmux new-window -n "agent:<branch-name>" -c "$WORKTREE_PATH" \
  "claude 'Read and execute the implementation plan in .claude-plan.md. Delete the file when you are done.'"
```

The tmux window name MUST be prefixed with `agent:` (e.g., `agent:add-user-authentication`).

### 5. Confirm to the user

```
Plan dispatched to agent:<branch-name>

  Branch:   <branch-name> (stacked on <current-branch>)
  Worktree: .worktrees/<branch-name>
  Window:   agent:<branch-name>

Switch to the tmux window to monitor progress, or continue working here.
```

## Error Handling

- **git-town not installed**: Tell the user to run `brew install git-town`
- **Branch already exists**: Pick a different name or delete the existing branch first
- **Dirty working tree**: Advise committing or stashing before creating new branches
- **git town append fails**: Show the error and suggest checking `git town status`
- **Not in tmux**: Tell the user to start a tmux session first

## Worktree Cleanup

When a dispatched plan's work is complete:

**Merged via PR (squash-merged on GitHub):**
```
git town sync
git worktree remove .worktrees/<branch-name>
git branch -d <branch-name>
```

**Local merge:**
```
git checkout <parent-branch>
git merge --squash <branch-name>
git commit
git worktree remove .worktrees/<branch-name>
git branch -d <branch-name>
```

## Rules

- ALWAYS use `git town append` — never `git town hack`
- ALWAYS checkout back to the original branch after `git town append`
- ALWAYS prefix tmux window names with `agent:`
- ALWAYS include enough context in the plan for a fresh agent with no conversation history
- NEVER execute an approved plan in the current session — always dispatch to a worktree
- Create worktrees in `.worktrees/<branch-name>` for consistent organization
