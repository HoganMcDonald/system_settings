---
name: notion
description: >
  Query Notion for recently modified pages — primarily meeting transcripts. Use during
  heartbeat runs to detect new meetings, extract action items and decisions, write
  summaries to memory, and optionally trigger follow-up work. Connects via mcp-remote
  over OAuth (one-time browser auth, then headless). If auth fails, surfaces a
  re-auth request to the user.
---

# Notion Skill

Uses `scripts/notion_query.js` to talk to Notion's MCP server via `mcp-remote`.
Designed to run as a subagent during heartbeat — the main agent spawns it, it queries
Notion, writes results to memory, and exits.

## One-time setup

The first run requires an OAuth flow in the browser. After that, tokens are cached at
`~/.mcp-auth/mcp-remote-<version>/` and reused headlessly.

To trigger the initial auth:
```bash
npx -y mcp-remote https://mcp.notion.com/mcp
```
Follow the browser prompt, then Ctrl-C once authenticated. Subsequent runs are headless.

## Workflow

### Heartbeat run
1. **Check for recent pages** — query pages modified in the last 30–60 minutes
2. **Filter for meetings** — look for pages in the meetings database (ID in MEMORY.md)
3. **Extract signal** — action items, decisions, follow-ups, names mentioned
4. **Write to memory** — append timestamped summary to `memory/HISTORY.md`
5. **Trigger work** — if action items look like coding tasks, note them for the main agent

### On-demand
Use when the user asks "what did we decide in my last meeting?" or "any action items
from today?" — query recent pages and summarize directly.

## Script usage

```bash
# Pages modified in last 60 minutes
node skills/notion/scripts/notion_query.js recent 60

# Search for a specific topic
node skills/notion/scripts/notion_query.js search "sprint planning"

# Get a specific page by ID
node skills/notion/scripts/notion_query.js get-page <page-id>

# Query a database
node skills/notion/scripts/notion_query.js query-database <database-id>
```

## Auth failure handling

The script exits with code 2 and prints `AUTH_REQUIRED: ...` to stderr when:
- mcp-remote times out (token expired or never set)
- An OAuth URL appears in stderr output

When this happens:
1. Notify the user: "Notion auth has expired — run `npx -y mcp-remote https://mcp.notion.com/mcp` to re-authenticate"
2. Skip the Notion step for this heartbeat run
3. Do not retry automatically — wait for user confirmation

## Memory format

When writing to `HISTORY.md`:
```
[YYYY-MM-DD HH:MM] notion: <meeting title> — <1-2 sentence summary of decisions/action items>
```

## Configuration

Store the following in `memory/MEMORY.md` under a **Notion** section:
- Meetings database ID (find it in the Notion URL when viewing the database)
- Any other databases worth monitoring

## Rules

- **Read-only** — never create, update, or delete Notion pages
- **Summarize, don't transcribe** — extract signal, not full transcript text
- **Skip empty meetings** — if a page has no meaningful content yet, skip it
- **Subagent only** — this skill is designed to run in a spawned subagent, not the main session
