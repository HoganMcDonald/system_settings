#!/usr/bin/env bash
# tmux_snapshot.sh — snapshot tmux panes and emit only changed content
#
# Usage: tmux_snapshot.sh [--snapshot-dir <dir>] [--lines <n>]
#
# --snapshot-dir: where to store snapshots (default: ~/.nanobot/tmux-snapshots)
# --lines:        lines of scrollback to capture per pane (default: 200)
#
# Output: for each pane with meaningful changes since last snapshot:
#   === <session>:<window>.<pane> [<command>] <path> ===
#   <new lines only>
#
# Snapshots are updated after each run. Panes with no meaningful change are silent.

set -euo pipefail

SNAPSHOT_DIR="$HOME/.nanobot/tmux-snapshots"
LINES=200

while [[ $# -gt 0 ]]; do
  case "$1" in
    --snapshot-dir) SNAPSHOT_DIR="$2"; shift 2 ;;
    --lines)        LINES="$2";        shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$SNAPSHOT_DIR"

# Sessions to skip entirely
SKIP_SESSIONS="nanobot"

# Commands that produce noisy/irrelevant output to skip diffing
SKIP_COMMANDS="Python nanobot"

# Sanitize: strip lines that look like secrets/tokens
sanitize() {
  grep -v -iE \
    '(password|passwd|secret|token|api[_-]?key|bearer|authorization|credential|private.key)' \
  | grep -v -E \
    '(export [A-Z_]+=|AWS_|GITHUB_TOKEN|NOTION_TOKEN|[A-Za-z0-9+/]{40,}={0,2}$)'
}

# Strip prompt lines and blank lines — not meaningful signal
strip_noise() {
  grep -v -E '^\s*$' \
  | grep -v -E '^(\$|❯|➜|%|#|>)\s*$' \
  | grep -v -E '^(\$|❯|➜|%|#|>) (exit|clear|reset)\s*$'
}

FOUND=0

# Iterate all panes
while IFS= read -r pane_info; do
  SESSION=$(echo "$pane_info" | cut -d'|' -f1)
  WINDOW=$(echo "$pane_info"  | cut -d'|' -f2)
  PANE=$(echo "$pane_info"    | cut -d'|' -f3)
  CMD=$(echo "$pane_info"     | cut -d'|' -f4)
  PATH_=$(echo "$pane_info"   | cut -d'|' -f5)

  # Skip noisy sessions
  if echo "$SKIP_SESSIONS" | grep -qw "$SESSION"; then
    continue
  fi

  # Skip noisy commands
  if echo "$SKIP_COMMANDS" | grep -qw "$CMD"; then
    continue
  fi

  TARGET="${SESSION}:${WINDOW}.${PANE}"
  # Sanitize session name for use as filename (replace / and spaces)
  SAFE_TARGET=$(echo "$TARGET" | tr '/' '_' | tr ' ' '_')
  SNAPSHOT_FILE="$SNAPSHOT_DIR/${SAFE_TARGET}.txt"
  HASH_FILE="$SNAPSHOT_DIR/${SAFE_TARGET}.hash"

  # Capture current pane content
  CURRENT=$(tmux capture-pane -t "$TARGET" -p -S "-$LINES" 2>/dev/null \
    | sanitize \
    | strip_noise \
    || true)

  [[ -z "$CURRENT" ]] && continue

  CURRENT_HASH=$(echo "$CURRENT" | md5)

  # Compare hash to previous
  PREV_HASH=""
  [[ -f "$HASH_FILE" ]] && PREV_HASH=$(cat "$HASH_FILE")

  if [[ "$CURRENT_HASH" == "$PREV_HASH" ]]; then
    continue  # No change — skip silently
  fi

  # Compute new lines (lines in current not in previous snapshot)
  if [[ -f "$SNAPSHOT_FILE" ]]; then
    DELTA=$(diff <(cat "$SNAPSHOT_FILE") <(echo "$CURRENT") \
      | grep '^>' \
      | sed 's/^> //' \
      | strip_noise \
      || true)
  else
    DELTA="$CURRENT"
  fi

  [[ -z "$DELTA" ]] && { echo "$CURRENT_HASH" > "$HASH_FILE"; continue; }

  FOUND=1
  # Shorten path for display
  DISPLAY_PATH=$(echo "$PATH_" | sed "s|$HOME|~|")
  echo "=== $TARGET [$CMD] $DISPLAY_PATH ==="
  echo "$DELTA"
  echo ""

  # Update snapshot and hash
  echo "$CURRENT" > "$SNAPSHOT_FILE"
  echo "$CURRENT_HASH" > "$HASH_FILE"

done < <(tmux list-panes -a \
  -F "#{session_name}|#{window_index}|#{pane_index}|#{pane_current_command}|#{pane_current_path}" \
  2>/dev/null)

if [[ $FOUND -eq 0 ]]; then
  echo "No tmux pane changes since last snapshot."
fi
