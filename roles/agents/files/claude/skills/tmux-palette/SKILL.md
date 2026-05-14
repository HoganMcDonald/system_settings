---
name: tmux-palette
description: >
  Add, edit, or remove custom actions in the user's tmux-palette
  (Raycast-style command palette for tmux). Use when the user asks to
  add a command/action/shortcut to their tmux palette, mentions
  tmux-palette, or wants to wire up a new entry in the popup that opens
  with `prefix + Space`.
---

# tmux-palette custom actions

User-defined entries live in `~/.config/tmux-palette/commands.json` — a
JSON array merged with the built-in commands. Theme lives at
`theme.json`, hidden built-ins at `hidden.json`, sizing at
`sizing.json` in the same directory.

The plugin is installed via TPM at `~/.tmux/plugins/tmux-palette/`. The
keybinding is `` ` `` (prefix) + `Space`, configured in
`roles/tmux/files/tmux/plugins.conf`.

## Entry schema

```json
{
  "icon": "󰍉",
  "title": "Edit nvim config",
  "description": "Open init.lua",
  "category": "Edit",
  "aliases": ["nvc"],
  "shortcut": "g d",
  "action": { "shell": "nvim ~/.config/nvim/init.lua" }
}
```

| Field | Required | Notes |
|---|---|---|
| `icon` | no | Nerd Font glyph |
| `title` | yes | Searchable item label |
| `description` | no | Dimmed text after title |
| `category` | no | Groups items under a header |
| `aliases` | no | Extra searchable strings; shown as chips |
| `shortcut` | no | Right-aligned label only (not a real binding) |
| `action` | yes | One of the action types below |

## Action types

| Type | Example | Use for |
|---|---|---|
| `tmux` | `{"tmux": "split-window -h"}` | Any tmux command |
| `shell` | `{"shell": "cursor ~/proj"}` | Shell command (runs after popup closes) |
| `popup` | `{"popup": "htop"}` | TUI launched in a centered popup |
| `palette` | `{"palette": "find-pane"}` | Chain into another palette mode |

## Workflow

1. Read `~/.config/tmux-palette/commands.json` (create if missing — must
   be a JSON array, even if empty: `[]`).
2. Append the new entry. Preserve existing entries.
3. Validate it's valid JSON (`jq . ~/.config/tmux-palette/commands.json`).
4. No reload needed — the palette reads the file on each invocation.

## Example library

Pre-built example bundles live at
`~/.tmux/plugins/tmux-palette/examples/`:

- `find-files.json` — fuzzy file open
- `git-branches.json` — branch switcher
- `github-prs.json` — open PR in browser
- `npm-scripts.json` — run package.json scripts
- `docker-containers.json` — docker exec into a container

If the user asks for something close to one of these, offer to copy/merge it.

## Conventions

- Default `category` to the verb domain ("Edit", "Open", "Run", "Git").
- Prefer `shell` over `tmux send-keys` for opening external apps.
- Keep titles imperative and short (under ~30 chars).
- Don't set `shortcut` unless an actual keybinding exists elsewhere —
  it's purely a label.
