---
name: gh-workflow
description: >
  GitHub workflow assistant. Use for reviewing open PRs, checking notifications,
  summarizing what needs attention on GitHub, or drafting PR descriptions from
  current branch context.
---

# GitHub Workflow

Use the `gh` CLI (already installed) to surface what needs attention.

## Common Commands

```bash
# My open PRs
gh pr list --author @me

# PRs awaiting my review
gh pr list --review-requested @me

# Unread notifications
gh notifications

# Current branch PR
gh pr view
```

## Status Summary

When asked for a GitHub summary or "what needs my attention", run all three
list commands and format as:

```
**PRs open:** [count] — [titles]
**Needs review:** [count] — [titles with repo]
**Notifications:** [count unread, grouped by repo]
```

Keep it Slack-friendly: short lines, no markdown tables.

## PR Description Drafting

When asked to draft a PR description for the current branch:
1. `git branch --show-current` — get branch name
2. `git log --oneline main...HEAD` — recent commits
3. `git diff main...HEAD --stat` — files changed

Produce a description following conventional commit style:
- **What**: one-sentence summary
- **Why**: context or ticket reference (extract Linear ID from branch if present)
- **Changes**: bullet list of key modifications
