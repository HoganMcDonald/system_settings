# Backfilling from merged PRs

Backfill reads review feedback on PRs that are already merged. The
discussion is finished, so the job is to recover the lessons and how each
one was handled. Everything in the main skill applies; these rules add to it.

## What to capture

- **Human feedback** that states or implies a reusable lesson, whether it
  was accepted, fixed, declined with an agreed reason, or left as a
  follow-up. Skip praise, "done", one-off typos, and questions that were
  answered without a lesson.
- **Bot feedback** (threads marked `raised by bot`, e.g. Cursor Bugbot) only
  when both are true:
  1. **Legitimate:** a real defect or risk in the code as written, not a
     false positive. If Hogan or another reviewer replied that it is fine,
     intended, or not applicable, skip it.
  2. **Incorporated:** a later commit in the PR actually fixed it. Find the
     commit after the comment that changes the flagged lines (`pr_context
     op=commit ref=<sha>`) and confirm the change addresses the finding.
     `resolved by @cursor[bot]` is a hint, not proof; Bugbot also resolves
     threads when the code merely moved.
  Capture it with `disposition: addressed` and `handled_url` set to the
  fixing commit URL (printed by `op=commit`). The tool rejects bot feedback
  without that evidence. The lesson is about the mistake ("check X before
  Y"), not about the bot.

## Handling state

Every source must say how the feedback ended:

| Evidence | `thread_state` | `disposition` | `handled_*` |
|---|---|---|---|
| A later commit fixes it | resolved/outdated | `addressed` | `handled_pr` = this PR, `handled_url` = commit URL |
| Hogan explained why not; reviewer accepted or did not object | resolved/none | `declined` | `handled_url` = the reply URL |
| Deferred ("follow-up", a ticket) | any | `acknowledged` | the reply or ticket URL |
| Disagreement left open at merge | any | `disputed` | the last reply URL |
| No visible outcome | any | `pending` | none |

Find fixes by comparing the comment's commit (the `@abc1234` next to it)
with later commits in the overview's commit list; open the likely ones with
`op=commit`, filtered by `path` when the PR is large.

## Confidence and scope

- New backfilled lessons are `likely` (the store downgrades `confirmed`).
  A recurrence on another PR upgrades them to `confirmed` when merged.
- Most lessons from one PR are `repository` or `subsystem` scope. Use
  `global` only when the reasoning clearly applies to any codebase.

## Recurrences

PRs are processed oldest first, so earlier lessons already exist. Always
`feedback_search` before creating. When the same lesson recurs, capture with
`merge_into`; do not create a near-duplicate.

## Effort

Read every thread, but spend verification effort where it changes the
outcome: bot findings and resolved human threads that look like fixes. A
short PR with only nits should take a minute; mark it reviewed and stop.
