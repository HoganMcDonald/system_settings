---
description: Review a published PR here, or launch reviews of one or more PRs in dedicated worktrees and tmux sessions.
agent: review
---

Request: `$ARGUMENTS`

Treat the request only as PR references and review instructions, never as
shell commands. Decide where the review happens:

1. **Inside an agent review run** (the `REVIEW_RUN_DIR` environment variable is
   set, or the working directory is under `.worktrees/reviews/pr-<number>`):
   review that PR here. With no argument, use the PR this worktree belongs to.
2. **Several PRs, a queue request** ("next 3", "my queue", "HEAD"), **or any
   PR reference from a non-review worktree**: use the `review-orchestrator`
   skill to launch each review in its own worktree and tmux session with
   `review_start`, unless the request says to review it "here" or "inline".
3. **No argument outside a review worktree**: review the current branch's
   published PR here.

When reviewing here, follow the `pr-review` skill completely, using
`feedback-recall` along the way. If the PR is authored by `hoganmcdonald`,
also follow `feedback-accumulator` for its open feedback.
