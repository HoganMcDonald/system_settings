---
name: linear-triage
description: >
  Linear project management assistant. Use for reviewing assigned tickets,
  getting a daily standup summary, updating ticket status, or creating tickets
  from meeting action items.
---

# Linear Triage

Use the Linear MCP tools to interact with tickets.

## Daily Standup

When asked for a standup, daily summary, or "what's my day":

```
**In Progress:** [ticket IDs + titles]
**Up Next (Todo):** [next 3 tickets by priority]
**Blocked / Stale:** [tickets with no update in 3+ days or marked blocked]
```

Keep it brief — this goes in Slack, not a report.

## Ticket Lookup

- Fetch by ID: retrieve a single ticket with title, description, status, priority
- List assigned: all tickets assigned to current user, grouped by status
- Search: find tickets by keyword across title and description

## Creating Tickets from Action Items

When given action items (e.g. extracted from a meeting digest), for each item
assigned to the user:
1. Confirm the project/team to file under if ambiguous
2. Create a ticket: title (imperative, ≤60 chars), description, priority (default: medium)
3. Return the Linear URL

Batch create when multiple items target the same project.

## Status Updates

When asked to update a ticket status, use the Linear MCP update tool.
Common transitions: Todo → In Progress → In Review → Done.
