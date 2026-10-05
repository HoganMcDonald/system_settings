---
name: pr-review
description: Use when performing a code review of a published GitHub pull request, including /review and agent review runs. Covers resolving the exact revision, gathering intent from Linear tickets, PR descriptions, commits, and existing review threads, tracing changed code paths, and producing an evidence-based report.
---

# PR Review

Review the published pull request at its current head, as a careful senior
engineer would: understand the intent, read every change, follow it into the
code it affects, and report only what you can support with evidence.

You are read-only. Never edit files, commit, push, post comments, approve, or
request changes on GitHub or Linear.

Tools: in OpenCode use `pr_context`; elsewhere run the equivalent
`pr-context <op> [PR] ...` CLI (`pr-context --help`).

## 1. Pin the target

- Resolve the PR from the request: URL, `owner/repo#N`, number, or the current
  branch's PR. In an agent review run, use the PR and SHAs from the prompt.
- `pr_context op=overview`. Record repo, number, author, base and head refs and
  SHAs, draft state, and checks. Review the head SHA, never local uncommitted
  changes. Use the PR's actual base, which may be another branch in a stack.
- If the local checkout is at a different commit than the PR head, read code
  through `pr_context op=file` / `op=diff` (pinned to the head) instead.

## 2. Gather intent and history

- PR description and **full** commit messages (overview shows bodies).
- Linear: fetch every ticket in `linear:`; verify `unverified mentions` before
  using them. Read acceptance criteria and recent ticket comments. Note any
  scope the PR misses or exceeds.
- Repository guidance relevant to the change (AGENTS.md, CONTRIBUTING, ADRs,
  nearby READMEs). Linked design docs when the ticket points at them.
- `pr_context op=threads` (state `all`): every open, resolved, and outdated
  thread with replies, review summaries, and conversation comments. Note what
  was asked, what was agreed, and what was declined.

## 3. Map the change

- Build a coverage checklist from the changed-file list (todo list for large
  PRs). Every file ends up either reviewed or explicitly marked as skipped
  with a reason (generated, vendored, lockfile, snapshot).
- Group files by behaviour, not directory. Identify entry points, public
  contracts (APIs, schemas, events, migrations, config), and tests touched.
- `pr_context op=diff` per file or page; large diffs paginate with `offset`.

## 4. Trace behaviour

For each change, read beyond the hunk:

- Callers and consumers of changed functions, types, and contracts (grep the
  head revision; use the `explore` subagent for wide searches).
- Data flow from input to persistence and back; error and retry paths;
  concurrency and ordering; authorization and tenant boundaries; resource
  lifetimes; backwards compatibility and rollout (old clients, mixed
  deployments, migrations on large tables, feature flags).
- Tests: do they exercise the changed behaviour and its failure modes, or only
  the happy path? Are assertions meaningful? Check CI results rather than
  running repository scripts.

See `references/review-checklist.md` for prompts by change type.

## 5. Recall accumulated feedback

Use the `feedback-recall` skill once you know the subsystems involved, again
when a new risk area appears, and before finalising. Apply a lesson only when
its conditions hold here; cite its id in the finding.

## 6. Reconcile with existing discussion

- Do not present an issue already raised in an open thread as new; list it
  under existing feedback with its thread link and whether the head addresses it.
- For resolved threads, check the head actually addresses them. Flag a
  resolved-but-unaddressed thread as a regression with evidence.
- Respect explicit decisions and declined suggestions; re-raise only with new
  evidence.

## 7. Report

Use the structure in `references/report-format.md`: findings first, ordered
by severity, each with location, failure scenario, evidence, and a suggested
direction. Separate new findings from existing feedback. End with coverage
and anything you could not verify.

Before finishing, re-run `pr_context op=overview`. If the head SHA moved,
say which head you reviewed and what changed since.

In an agent review run, present the report as your final response and call
`review_submit` with the same report, the reviewed head SHA, every finding,
and a coverage note.

If the PR is authored by `hoganmcdonald`, the open feedback you loaded is also
input for the `feedback-accumulator` skill.
