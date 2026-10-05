# Global agent notes

## Review feedback memory

Lessons from past code review feedback on Hogan's (`hoganmcdonald`) pull
requests live in `~/.feedback`. Search it; never load it wholesale.

- Reviewing a PR or planning or implementing a non-trivial change: use the
  `feedback-recall` skill (`feedback_search`, then `feedback_show` for the few
  relevant hits).
- Loading review threads, review summaries, or PR comments on a PR authored
  by `hoganmcdonald`, by any means: use the `feedback-accumulator` skill and
  capture actionable feedback as part of the task.
- Whenever feedback is captured or its handling is updated in a session, end
  the final response with `💡 feedback captured` followed by one bullet per
  item (at most 10 words each).
