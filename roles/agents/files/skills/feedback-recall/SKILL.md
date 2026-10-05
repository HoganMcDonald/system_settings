---
name: feedback-recall
description: Use when reviewing a pull request or planning and implementing non-trivial code changes, to retrieve relevant lessons from accumulated review feedback in ~/.feedback without loading the whole store.
---

# Feedback Recall

Past review feedback on Hogan's PRs is stored as small, tagged lessons in
`~/.feedback`. Retrieve only what applies to the work in front of you.

Tools: in OpenCode use `feedback_search` then `feedback_show`; elsewhere use
`feedback search ...` and `feedback show <id>`. Never read the whole
`entries/` directory or `index.jsonl` into context.

## When to search

- After identifying the subsystems, languages, and kinds of change involved.
- Whenever a new risk area appears (auth, caching, migrations, concurrency...).
- Before finalising a review or declaring an implementation done.

## How to search for high recall

- Run several short searches rather than one long one: one per behaviour or
  risk, each with 3-8 terms mixing concepts, symptoms, and synonyms
  ("cache stale permissions authz", "retry backoff rate limit 429").
- Pass `repo` and the changed `paths` (and `symbols` when known) to boost
  lessons tied to that code; they do not filter out transferable lessons.
- Thin results: retry with different vocabulary, broader concepts, or the
  subsystem name; use `offset` to page. `~` in a match means partial match.
- Use `include_inactive` only to check whether a lesson was retired.

## Applying results

- Open only promising hits with `feedback_show` (a handful at most).
- Apply a lesson when its "Applies when" holds and no exception does. Lessons
  are evidence from past reviews, not universal rules; repository-scoped
  lessons apply elsewhere only when the reasoning clearly transfers.
- In reviews, cite the entry id in the related finding. When implementing,
  follow applicable lessons proactively and mention the ones that shaped the
  change.
- If a lesson looks wrong or outdated, say so; do not edit it unless asked.
