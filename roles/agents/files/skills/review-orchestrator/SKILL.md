---
name: review-orchestrator
description: Use when asked to review one or more pull requests in separate worktrees or tmux sessions, to review the next PRs awaiting review, to check on or summarise agent review runs, or to stop, kill, cancel, or clean up reviews and their worktrees and tmux sessions.
---

# Review Orchestrator

Coordinate agent reviews from the main worktree. Each review runs in its own
detached worktree (`.worktrees/reviews/pr-<n>`) and tmux session, driven by
the `review` agent on Opus. You launch, track, and summarise; you do not
review the PRs yourself here.

Tools: in OpenCode use `review_start`, `review_status`, `review_result`,
`review_cleanup`. Elsewhere use the CLI: `review start <ref>... --json`,
`review status --json`, `review result <ref> --json [--full]`,
`review clear [ref] --stop`.

## Launch

- Explicit PRs: `review_start` with `refs` (numbers, URLs, branches, Linear ids).
- Queue requests ("next 3", "my reviews"): `review_start` with `next: N`.
- Combine both when asked. Deduplication is automatic.
- Never switch the user's tmux client; the tools never do.
- Report a short table: PR, action (`launched`, `queued`, `reused`,
  `already_reviewed`, `busy_stale`, `conflict`, `error`), session name, and any
  detail. Explain `busy_stale` (an older head is still under review; offer
  `review stop <pr>`) and `already_reviewed` (offer `force: true`).
- Mention `review attach <pr>` for watching or continuing a review.

## Track

- Finished runs are announced automatically in this session (toast plus a
  note in your context). When the user asks, or when you are told runs have
  finished, call `review_status` for the overview.
- `waiting` means a session is blocked on user input; tell the user which
  session to attach to. `interrupted` or `failed` runs can be relaunched with
  `review_start` for the same PR.

## Summarise

- `review_result <pr>` returns verdict, finding counts, summary, and captured
  feedback. Use `full: true` only when the user wants details or you need to
  compare findings across PRs.
- For a batch, give one line per PR (verdict, counts, top risk), then the
  details the user asks for. Note when a result covers an older head than the
  PR's current head.
- If results report captured feedback, end your response with the
  `💡 feedback captured` footer listing those items (deduplicated).

## Clean up

"Kill", "stop", "cancel", or "clean up" reviews means tearing down what
`review_start` created: call `review_cleanup` (no ref for all reviews in this
repository, or one PR). It cancels queued runs, stops running agents, kills
their tmux sessions, and removes their review worktrees; results and branches
are kept. Report what was stopped and removed.

- Worktrees with local changes are skipped. List them and ask before
  retrying with `force_dirty: true`.
- "Stop" without "clean up" or "remove" when the user wants to keep the
  sessions: `keep_worktrees: true`.
- Unsure what will go: `dry_run: true` first.
- Cleanup is per repository; say so if the user may have reviews elsewhere.
- Run from the main worktree; the tool refuses inside a review worktree.

## Limits

- Default concurrency is 3 running reviews; extra runs queue and start as
  others finish. Pass `max_active` only when the user asks.
- Inside a review run session, do not launch nested reviews.
