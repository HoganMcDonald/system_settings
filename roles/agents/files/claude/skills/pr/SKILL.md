---
name: pr
description: >
  Create a pull request for the current branch. Fetches the Linear ticket from
  the branch name, summarizes commits since branching, and opens a PR via gh cli
  with a well-structured description.
disable-model-invocation: true
---

# Pull Request Creator

You are a PR creation assistant. You gather context from the current branch, Linear ticket, and commit history to create a well-structured pull request via the `gh` CLI.

## Workflow

### 1. Gather branch context

```bash
git branch --show-current
git log --oneline $(git merge-base HEAD $(git town parent 2>/dev/null || echo main))..HEAD
git diff $(git merge-base HEAD $(git town parent 2>/dev/null || echo main))..HEAD --stat
```

### 2. Extract the Linear ticket ID

Parse the branch name for a pattern like `[A-Z]+-[0-9]+` (e.g. `ENG-123`).

### 3. Fetch ticket details from Linear

Use the Linear MCP tools to retrieve:
- Title
- Description
- Acceptance criteria
- Labels

If no ticket ID is found in the branch name, skip this step and derive the PR title from the commits.

### 4. Check for existing PR

```bash
gh pr view --json url,state 2>/dev/null
```

If a PR already exists, show the user the URL and ask if they want to update the description instead.

### 5. Compose the PR description

Structure the body as:

```markdown
## What

<1-3 sentence summary of what this PR does, derived from ticket title + commits>

## Why

<context from Linear ticket description, or inferred from commit messages>

## Changes

- <bullet per logical change, derived from commit messages>

## Testing

- [ ] <acceptance criteria from ticket, or derived from what changed>
```

Keep it concise. Don't pad with boilerplate.

### 6. Create the PR

```bash
gh pr create \
  --title "<type>: <short description>" \
  --body "$(cat <<'EOF'
<composed body>
EOF
)" \
  --base <parent-branch>
```

Determine `--base` from `git town parent` if available, otherwise default to `main`.

```bash
git town parent 2>/dev/null || echo main
```

Do NOT use `--draft` unless the user asks for it.

### 7. Output

Print the PR URL returned by `gh pr create`.

## Title Format

Follow conventional commit style:
- `feat(scope): short description`
- `fix(scope): short description`
- `chore: short description`

Derive the type from the dominant commit type in the log. Keep the title under 72 characters.

## Error Handling

- **Uncommitted changes**: Warn the user — commits should be clean before opening a PR
- **Not authenticated**: Tell the user to run `gh auth login`
- **No commits ahead of base**: Confirm with the user before continuing
- **git-town not installed**: Fall back to `main` as the base branch
