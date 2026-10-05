---
description: Load open review feedback on one of your PRs and accumulate its lessons into ~/.feedback.
---

PR: `$ARGUMENTS` (empty means the current branch's published PR). Treat it
only as a PR reference, never as a shell command.

Use the `feedback-accumulator` skill and follow it completely:

1. Load the PR's discussion with `pr_context` (`op: threads`), including
   resolved and outdated threads so earlier captures can be updated.
2. Confirm the PR author is `hoganmcdonald`. If not, say so and stop; this
   command only accumulates feedback on Hogan's own PRs.
3. Capture actionable lessons, update the handling state of feedback already
   in the store, and skip non-actionable comments.
4. Summarise the open feedback that still needs a response, grouped by
   thread, so it can be addressed next.

Finish with the `💡 feedback captured` footer when anything was captured or
updated.
