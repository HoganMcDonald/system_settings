---
name: feedback-accumulator
description: Use whenever review feedback (review threads, review summaries, PR comments) is loaded for a GitHub pull request authored by hoganmcdonald, including /feedback, addressing review comments, or a [feedback-loop] capture notice. Distills actionable lessons into the ~/.feedback memory with PR links, dedupes recurrences, and records how feedback was handled.
---

# Feedback Accumulator

Turn review feedback on Hogan's PRs into durable, searchable lessons. This
runs on autopilot: whenever open feedback on one of his PRs is loaded, capture
it as part of the task, then continue with what the user asked.

Tools: in OpenCode use `pr_context` and `feedback_*`; elsewhere use the
`pr-context` and `feedback` CLIs (`feedback --help`).

## Workflow

1. **Verify the source.** The PR author must be `hoganmcdonald` (shown by
   `pr_context op=threads`). If not, do not capture anything.
2. **Load the whole discussion** with `pr_context op=threads state=all`. Read
   each thread's replies and the code it points at before interpreting it.
3. **Classify each thread, review summary, and conversation comment:**
   - Actionable lesson or recurring concern → capture.
   - Praise, acknowledgements, "done", bot output, pure questions with no
     lesson, or one-off typos → skip.
   - Feedback already in the store (same `source_key`) → re-capture with its
     current `thread_state` and `disposition` so handling is tracked.
4. **Search before creating.** `feedback_search` with the lesson's concepts
   and synonyms. If the same lesson exists, capture with `merge_into=<id>`;
   this is a recurrence and strengthens the lesson.
5. **Capture** with `feedback_capture`. Entry fields and examples are in
   `reference/entry-format.md`; read it before your first capture in a
   session. If the tool returns `needs_decision`, choose `merge_into` for the
   same lesson or `force_new: true` for a genuinely different one.
6. If nothing qualifies, call `feedback_mark_reviewed` with the PR and a reason.
7. **Announce.** End the final response with the footer the tool returns
   (the plugin appends it if you forget):

   ```
   💡 feedback captured
   - <notice, at most 10 words>
   ```

## Judgement rules

- **Preserve scope.** A convention of one repository stays `repository`
  scope; only make it `global` when the reasoning applies to any codebase.
- **Open is not a verdict.** New feedback is `disposition: pending` and
  usually `status: active`. If Hogan pushed back and the reviewer has not
  agreed, use `disposition: disputed` (the entry becomes `disputed`).
- **Resolved does not mean fixed.** Set `disposition: addressed` only with
  evidence: a fixing commit, a reply confirming the fix, or code at the head
  that clearly addresses it. Put that link in `handled_url` and the PR in
  `handled_pr`. Use `declined` when Hogan explained why not and the reviewer
  accepted; `acknowledged` for "will do in a follow-up".
- **Phrase the lesson as reusable guidance**, not as a description of the
  diff: "Check authorization before serving cached results", not "Move line 80".
- **Write for search.** Include canonical concepts plus at least five
  aliases: synonyms, symptoms ("stale data", "flaky test"), abbreviations
  ("authz"), and the reviewer's own wording. Add symbols and path globs when
  the lesson is tied to code.
- **Never invent links.** Every URL must come from tool output.

## User-directed edits

When Hogan asks to change feedback ("that's too broad", "retire the one about
X"), find it with `feedback_search`, read it with `feedback_show`, then use
`feedback_revise` (with a `note` explaining why) or `feedback_retire`. Retired
sources are never re-captured.
