---
name: tmux
description: >
  Capture tmux pane activity and build a picture of what the user is actively working
  on. Use for heartbeat context gathering, or when asked what is running in the terminal.
  Uses a snapshot+diff model — only panes that have changed since the last run produce
  output, so idle panes generate zero noise. Summarizes deltas and writes to memory
  over time. Never reads file contents — terminal output only.
---

# tmux Skill

Runs `scripts/tmux_snapshot.sh` to capture changed pane output across all sessions,
then summarizes the deltas into a short activity digest and writes it to memory.

## Workflow

1. **Run the script** — captures all pane deltas since last snapshot
2. **Summarize** — for each changed pane, distill what's happening:
   - What command is running (`nvim`, `tsc --watch`, a build tool, a dev server, etc.)
   - What repo/path the pane is in
   - Any errors, build output, or notable activity in the delta
3. **Write to memory** — append a timestamped entry to `memory/HISTORY.md`
4. **Update MEMORY.md** — if the set of active sessions/repos has meaningfully changed

Refer to `memory/MEMORY.md` for user-specific session layout and project context.

## Script usage

```bash
# Default: ~/.nanobot/tmux-snapshots, 200 lines scrollback
bash skills/tmux/scripts/tmux_snapshot.sh

# Custom snapshot dir or scrollback depth
bash skills/tmux/scripts/tmux_snapshot.sh --snapshot-dir ~/.nanobot/tmux-snapshots --lines 300
```

## Snapshot storage

Snapshots live at `~/.nanobot/tmux-snapshots/` — one `.txt` + `.hash` file per pane,
named `<session>:<window>.<pane>` (with `/` replaced by `_`). These are local state
only — never committed, never sent to the LLM in full.

## Memory format

When writing to `HISTORY.md`:
```
[YYYY-MM-DD HH:MM] tmux: <1-2 sentence summary of active pane changes>
```

## Filtering (handled by script)

The script already:
- Skips the `nanobot` session
- Strips lines matching secret/token patterns
- Strips blank lines and bare prompt lines
- Only emits panes whose content hash has changed

When summarizing, additionally ignore:
- Repetitive log lines from long-running services — note presence of errors, not full traces
- Environment/shell init noise (`direnv`, shell hooks, etc.)
- Build tool boilerplate — summarize as "build running" or "build complete"

## Rules

- **Terminal output only** — never read file contents or run `git diff`
- **Snapshots are state, not memory** — never write raw snapshot content to HISTORY.md
- **Summarize errors, don't transcribe them** — "service has build warnings" not the full trace
- **Read-only** — never send keystrokes or interact with panes
