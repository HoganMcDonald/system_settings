---
date: 2026-10-30
weekday: Friday
timezone: America/Chicago  # IANA zone of the system clock
status: active            # draft | active | done
revision: 1
created_at: 2026-10-30T10:30:00-05:00
updated_at: 2026-10-30T10:30:00-05:00
cycle: NOVA-118           # current Linear cycle, or none
focus: [NOVA-4973, NOVA-4976, SEC-9112]   # the 1-3 things that make the day a win (plain IDs, no links)
tickets: [NOVA-4987, NOVA-4973, NOVA-4976, NOVA-4986]   # plain IDs, no links
reviews_seen: [hex-inc/hex#50123, hex-inc/hex#51663]   # every review request known at last refresh (plain IDs, no links)
own_prs: [hex-inc/hex#48327]
meetings: 3
sources: [notion-meetings, calendar, linear, github, past-plans]
sources_failed: []
---

# Friday 2026-10-30

<!-- In the body, every ticket and PR is a link: [NOVA-1234](<linear url>) and
     [hex-inc/hex#123](<github url>). URLs come from tool output, never guessed. -->

## Fixed commitments
- 2:30–2:55 pm Hogan / Claire
- 3:00–3:30 pm Nihar / Hogan
- 4:30–5:00 pm Remi Gabillet debrief (fill scorecard first)

## Plan
- [ ] 10:30–11:15 am Reviews: [hex-inc/hex#50123](https://github.com/hex-inc/hex/pull/50123) (security, fresh), [hex-inc/hex#51663](https://github.com/hex-inc/hex/pull/51663)
- [ ] 11:15–11:30 am [NOVA-4987](<linear url>) first pass, post status in Slack thread
- [ ] 11:30 am–1:00 pm Deep: [NOVA-4973](<linear url>) + [NOVA-4976](<linear url>) (shared OAuth callback)
- [ ] 1:00–1:45 pm Lunch
- [ ] 1:45–2:30 pm Reviews (stale): [hex-inc/hex#48777](https://github.com/hex-inc/hex/pull/48777), [hex-inc/hex#48247](https://github.com/hex-inc/hex/pull/48247)
- [ ] 3:30–4:15 pm Finish OAuth PR, Remi scorecard
- [ ] 4:15–4:30 pm Buffer
- [ ] 5:00–5:15 pm Wrap-up

## Reviews
| PR | Author | Class | Note |
| --- | --- | --- | --- |
| [hex-inc/hex#50123](https://github.com/hex-inc/hex/pull/50123) | glentakahashi | fresh, security | |
| [hex-inc/hex#48777](https://github.com/hex-inc/hex/pull/48777) | sukwanlee | stale | agent review exists (review_result) |

## Tickets
| Ticket | Status | Why today | Branch |
| --- | --- | --- | --- |
| [NOVA-4987](<linear url>) | Todo | live impact, credential expiring | `hogan/nova-4987-short-title` |
| [NOVA-4973](<linear url>) | In Progress | medium security, concrete fix | — |

<!-- Branch: the gitBranchName Linear returns, in backticks, only for tickets that
     have not started and have no branch or PR yet. Otherwise —. -->

## Deferred
- [NOVA-4975](<linear url>) / [NOVA-4974](<linear url>): Friday, scope only. Start Monday.

## Notes
- From <meeting title> (YYYY-MM-DD): <one-line action item for me>

## Changelog
- 10:30 am r1: created
