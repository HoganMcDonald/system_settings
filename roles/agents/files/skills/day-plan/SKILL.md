---
name: day-plan
description: >
  Use when Hogan asks to plan his day, asks for today's plan or "what should I
  do next", wants to amend, reshuffle, or extend the day's plan (new reviews
  assigned, a meeting moved, a fire drill, running late, wrapping up), or
  references ~/.day_plans. Builds the plan from the last 5 days of Notion
  meeting notes, Notion Calendar, the Linear board, open GitHub review
  requests, and past plans, and stores one small markdown file per day in
  ~/.day_plans/. Works from any session and any directory.
---

# Day Plan

One plan file per day at `~/.day_plans/YYYY-MM-DD.md`. The file is the source of
truth. Any session can read it, show it, or amend it. Never keep the plan only in
chat.

Use `~/.config/opencode/skills/day-plan/template.md` as the exact shape of a new
file. Frontmatter keys and section headings must stay identical from day to day so
past plans can be parsed and diffed.

## Pick the mode first

Run `date '+%Y-%m-%d %A %H:%M %Z %z'` and `ls ~/.day_plans | tail -7` before anything
else. Never assume the date, the time, or the time zone. The system clock is the
source of truth for "local time". Get the IANA zone name for frontmatter and
calendar calls with `readlink /etc/localtime | sed 's|.*/zoneinfo/||'`.

| Request | Mode |
| --- | --- |
| "plan my day", "what's today look like", no file for today | **create** |
| "show the plan", "what's next", file for today exists | **show** |
| "add/remove/move X", "I got N new reviews", "meeting got moved", "I'm behind", "reprioritize" | **amend** |
| "wrap up", "end of day", "close out the plan" | **wrap** |
| "plan tomorrow" / "plan Monday" | **create** for that date (skip weekends unless asked) |

If today's file exists and the user asks to "plan my day", do **show**, then offer
to refresh. Do not silently regenerate. Regenerating is **amend** with a full
refresh.

## Mode: create

Gather in parallel, then synthesize. All sources are read-only. Do not mutate
Linear, GitHub, or the calendar while planning unless asked.

### 1. Past plans (read first, cheap)
Read the last 5 files in `~/.day_plans/` (by filename). Pull from each:
unchecked `- [ ]` items, the `## Deferred` section, and `## Notes`. Anything
deferred two days in a row is **stale**. Call it out and ask whether to drop,
schedule, or hand off. Do not carry it silently.

### 2. Notion meeting notes, last 5 days
`notion_notion-query-meeting-notes` with a `created_time` filter of
`date_is_within`, relative, custom, past, 5 days. Then `notion_notion-fetch` each
result (most recent 8 at most) with `include_transcript: false`. The notes and
summary are enough. Only fetch the transcript when the summary is ambiguous about
something that affects today's plan.

Extract only what changes today:
- action items assigned to Hogan or "me" that are not yet done
- decisions or deadlines that touch current tickets
- people waiting on him

Record these in `## Notes` as one-line bullets with the meeting title and date.
Skip everything else. Do not paste summaries.

### 3. Calendar (Notion Calendar)
`notion_notion-calendar-list-events` for the target day in the system time zone
from the step above. Calendar results can come back in another zone, so convert
every event to system local time before writing it down.

The response includes many calendars (PTO, teammates, shared). Keep only events
on Hogan's primary calendar (`hmcdonald@hex.tech`) where he is an attendee with
`responseStatus` of `accepted`, `tentative`, or `needsAction`. Drop declined
events, other people's calendars, and PTO events that are not his. Use PTO
calendar entries only to note that a teammate is out when a review or question
depends on them.

For interviews and debriefs, add a prep line ("fill scorecard before 4:30").

### 4. Linear
- `linear_list_issues` with `assignee: me`, the current cycle of the NOVA team
  (`linear_list_cycles` with `type: current`), `limit: 100`.
- `linear_list_issues` with `assignee: me` and `state: triage` for anything not in
  the cycle but assigned.
- Pass `fields: ["id", "title", "status", "statusType", "priority", "cycleId", "url", "gitBranchName"]`
  on both calls (add `team` if useful). `url` is the link to show and
  `gitBranchName` is the branch name Linear suggests. Use them verbatim. Never
  build either by hand.
- For anything In Review, check the linked PR state with `gh pr view`.
- **Branches to create.** For each ticket that is going to be worked on today and
  has not started (`statusType` of `unstarted`, `backlog`, or `triage`), check
  whether the branch already exists or a PR is open for it:
  `git ls-remote --heads origin <gitBranchName>` and
  `gh pr list --state open --search "<TICKET-ID>"`. If neither exists, record
  `gitBranchName` as the branch to create. Do not show a branch for tickets
  already started or In Review, or that only appear in Deferred.

Linear notes: moving a triage issue into a cycle also moves it to Upcoming. Saving
an issue sometimes fails silently, so re-fetch to verify after any write.

### 5. GitHub review requests
```bash
gh search prs --review-requested=@me --state=open \
  --json number,title,author,repository,url,updatedAt,isDraft --limit 50
gh search prs --author=@me --state=open \
  --json number,title,repository,url,updatedAt,isDraft --limit 30
```
Also run `review_status`. If an agent review already exists for a PR, say so and
point at `review_result` instead of planning a from-scratch review.

Classify each review request: **fresh** (updated in last 48h), **stale** (older),
**draft** (skip unless asked), **security** (title or label mentions SEC or
security). Record each as `owner/repo#number` in `reviews_seen` so later runs can
detect new ones.

### 6. Prioritize and schedule
Build the plan with these defaults:

1. Fixed meetings are immovable. Add 5 minutes of buffer before any interview
   debrief or external call.
2. Anything already In Review on Hogan's own PRs comes first, because it is cheap
   to close and unblocks others.
3. Live user impact (customer-facing breakage, expiring credentials) beats planned
   work. Do a short first pass early.
4. Fresh and security-related reviews go in the first hour so authors are not
   blocked. Stale reviews go in a lower-energy slot and should use any existing
   agent review output.
5. Deep work blocks are 60 to 90 minutes in the longest uninterrupted stretch,
   ideally the morning. Never schedule deep work in a gap shorter than 45 minutes.
6. Group related tickets into one block (for example two tickets touching the same
   file or flow).
7. Include lunch (45 min), a 15 minute buffer in the afternoon, and a 15 minute
   wrap-up at the end.
8. Fridays and the last day before a break: do not start large items. Scope only.
9. If it is already mid-day, plan only the remaining time. Do not schedule blocks
   in the past.
10. Anything that does not fit goes in `## Deferred` with a reason. Do not
    overpack. If total demand exceeds available time, say so and show what you cut.

Keep the file under about 80 lines. Do not paste descriptions, summaries, or agent
review text into the file. Tickets and PRs are always written as links (see
Rules).

### 7. Write and present
`mkdir -p ~/.day_plans`, write the file from the template, set `revision: 1`, then
show the plan in chat (the schedule table plus anything stale or cut) and the file
path. Do not paste the whole file. Every ticket and PR in the chat output is a
link, and any branches to create are listed in a copyable block (see Rules).

## Mode: show

Read today's file and print it compactly. If asked "what's next", compute the next
unchecked block from the current time and give only that plus the one after it.

## Mode: amend

Always read the current file first. Then:

1. Re-query only the source the change implies, not all of them:
   - "new reviews" → rerun the `gh search prs --review-requested=@me` query and
     diff against `reviews_seen`. List the new PRs, classify them, and add them to
     `reviews_seen`.
   - "meeting moved/added" → rerun the calendar read.
   - "new ticket / urgent bug" → rerun the Linear read or fetch the single issue.
   - "I'm behind / I lost two hours" → no query. Re-time the remaining blocks.
2. Rebuild only the blocks from the current time forward. Past blocks are history.
   Do not rewrite them. Mark completed work `[x]`, and leave anything the user did
   not confirm as `[ ]`.
3. When something must give, move the lowest-priority future block to
   `## Deferred` with a one-line reason. Never delete it.
4. Bump `revision`, update `updated_at`, and append one line to `## Changelog`:
   `- H:MM am/pm rN: <what changed and why>`.
5. Show a short diff in chat: what was added, moved, and deferred. Do not reprint
   the whole plan unless asked.

For a batch of new reviews: group them by author or repo, order fresh and security
first, and fit them into one or two review blocks instead of one block each. If
there are more than about 4, propose a cut and ask before bumping tickets.

## Mode: wrap

Mark finished blocks `[x]`, move unfinished items to `## Deferred` with the reason,
set `status: done`, and append a Changelog line. Add 1 to 3 bullets under
`## Notes` for anything tomorrow's plan should know (stale reviews, a blocked PR,
a promise made).

## Rules

- Show every time in the local system time zone, in 12-hour format with am/pm,
  like `10:30–11:15 am` or `1:30–1:55 pm`. Never use 24-hour ("military") time
  in the plan body, the changelog, or chat replies. If a range crosses noon, put
  am/pm on both ends (`11:30 am–12:30 pm`). Convert times from any other zone
  (calendar, meeting notes, Slack) to local before using them.
- Frontmatter timestamps (`created_at`, `updated_at`) stay ISO 8601 with offset
  so they remain machine-readable. That is the only place 24-hour time belongs.
- Changelog lines use the same 12-hour format: `- 11:09 am r2: ...`.
- The file stays small. Reference by ID, never paste bodies.
- **Always link tickets and PRs**, in the plan file and in every chat reply, in
  every mode (create, show, amend, wrap). Write tickets as
  `[NOVA-1234](<linear url>)` and PRs as `[owner/repo#123](<github url>)`. Take
  the URL from the tool output (Linear `url` field, `gh` `url` field). Never
  guess or construct a URL. If a URL is not on hand, fetch it (`linear_get_issue`
  or `gh pr view --json url`) before writing the entry. This applies to the plan
  body, tables, Deferred, Notes, and Changelog. Frontmatter lists (`tickets`,
  `reviews_seen`, `own_prs`, `focus`) stay plain IDs so they remain parseable.
- **Branch names for unstarted tickets.** When the plan includes a ticket that has
  not started and needs a new branch (see the Linear step), show the branch name
  Linear suggests (`gitBranchName`) exactly as returned. In the file, put it in
  the `Branch` column of the Tickets table in backticks (`—` when none needed).
  In chat, list them in one fenced code block, one per line as
  `TICKET-ID  branch-name`, so they can be copied directly. Do not run
  `git checkout -b`, and do not create the branch unless asked.
- Ask before changing Linear (assignee, cycle, status, priority) or posting to
  GitHub or Slack. Suggest it in the plan instead.
- If a source fails (MCP not authenticated, `gh` not logged in), say which one,
  plan from the rest, and record it in frontmatter `sources_failed`.
- Be honest about capacity. If the day is already overbooked, say so.
- Keep chat replies short. The file holds the detail.
