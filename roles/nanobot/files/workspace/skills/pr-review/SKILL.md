---
name: pr-review
description: >
  Monitor and address pull request feedback. Use for checking open PRs, triaging
  review comments, addressing small feedback via Claude Code, and re-running failed
  CI. Also used by the heartbeat to proactively surface PRs that need attention.
  Never comments on PRs or pushes commits on the user's behalf.
---

# PR Review Skill

Monitors open PRs, triages review feedback, and coordinates with the claude-code
skill to address small changes. The user always reviews and ships — never autonomous.

## Workflow

### Heartbeat / proactive check
1. Run `scripts/pr_status.sh OWNER/REPO` for each known repo
2. For any PR with new review comments or failed CI, summarize and notify
3. Log findings to memory/history even if no notification channel is available

### Addressing feedback (on request)
1. **Fetch** — run `pr_status.sh OWNER/REPO PR_NUM` to get full PR detail + CI state
2. **Triage** — categorize each comment:
   - ✅ **Addressable** — nits, naming, small logic, formatting (claude-code can handle)
   - 🧠 **Needs you** — design decisions, architectural questions, subjective calls
3. **Propose** — show the user the triage, confirm which items to address
4. **Clone** — ensure repo is cloned/updated in `~/code/agent-workspace/` (see claude-code skill)
5. **Edit** — invoke claude-code skill with a focused prompt listing only the approved items
6. **Report** — summarize files changed, show diff, flag anything claude-code was uncertain about
7. **Offer review** — offer to run the `reviewer` sub-agent on the diff before the user commits

### Re-running CI
1. Get the branch name from the PR
2. Find the latest run ID: `gh run list --repo OWNER/REPO --branch BRANCH --limit 1`
3. Rerun failed jobs: `gh run rerun RUN_ID --repo OWNER/REPO --failed`
4. Report the new run URL

## Rules

- **Never comment on PRs** — not even to say "addressed" or "done"
- **Never push commits** — stage changes in the agent workspace, let the user push
- **Never address ambiguous feedback** — if a comment could be interpreted multiple ways, flag it for the user
- **Scope edits tightly** — pass only the specific feedback items to claude-code, not the whole PR
- **One PR at a time** — don't batch edits across multiple PRs in a single claude-code run
- **Always work in `~/code/agent-workspace/`** — never touch the user's own checkout

## Triage heuristics

Addressable without user input:
- Typos, grammar, comment wording
- Rename a variable/function to match reviewer's suggestion
- Add/remove a blank line, fix indentation
- Add a missing error case that's clearly implied
- Reorder imports

Needs the user:
- "Should this be async?" / "Why not use X instead?"
- Any comment phrased as a question without a clear answer
- Suggestions that conflict with existing patterns
- Anything touching public API surface or types

## Known repos

Add repos to monitor here as they become relevant. Format: `owner/repo`.

<!-- repos -->

## Reference

- `scripts/pr_status.sh` — fetch open PRs or single PR detail + CI state
- `references/gh-commands.md` — full gh CLI reference for PR/CI operations
