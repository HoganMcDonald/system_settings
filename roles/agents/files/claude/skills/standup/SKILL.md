---
name: standup
description: >
  Generate a standup summary from recent git activity and Linear tickets.
  Covers what was done yesterday, what's in progress today, and any blockers.
disable-model-invocation: true
---

# Standup Generator

You are a standup assistant that produces a concise daily standup summary from git history and Linear context.

## Workflow

### 1. Gather recent git activity

```bash
# Commits from the last working day (covers weekends)
git log --all --oneline --since="3 days ago" --author="$(git config user.email)"

# Current branch and its status
git branch --show-current
git status --short

# Open PRs
gh pr list --author "@me" --json number,title,url,state,isDraft
```

### 2. Identify active Linear tickets

For each branch with recent commits, extract the ticket ID (`[A-Z]+-[0-9]+`) and fetch details from Linear:
- Title
- Status (In Progress, In Review, Done, etc.)
- Any recent comments or updates

### 3. Check tmux sessions (optional context)

```bash
tmux list-sessions 2>/dev/null
tmux list-windows -a 2>/dev/null
```

Use session/window names to infer what was being worked on.

### 4. Compose the standup

Format:

```
## Yesterday
- <what was done, grouped by ticket/PR — keep it factual and brief>

## Today
- <what's planned — current branch, open PRs awaiting review, next ticket>

## Blockers
- <anything blocked, or "None">
```

Rules:
- One line per item — no nested bullets
- Reference ticket IDs and PR numbers where relevant (e.g. `ENG-123`, `#42`)
- Skip items with no meaningful activity (e.g. branches with only chore commits)
- If today is Monday, "yesterday" covers Friday and the weekend

### 5. Output

Print the formatted standup. Ask the user if they want to copy it or post it anywhere.

## Example Output

```
## Yesterday
- ENG-123: Implemented OAuth2 login flow (#42 opened for review)
- ENG-118: Fixed null pointer in user lookup, squash-merged

## Today
- ENG-124: Start work on user preferences endpoint
- Review feedback on #42 if any comes in

## Blockers
- None
```
