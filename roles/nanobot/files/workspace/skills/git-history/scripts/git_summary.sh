#!/usr/bin/env bash
# git_summary.sh — summarize recent git activity across repos
# Usage: git_summary.sh [--since <duration>] [--repos <path1,path2,...>]
#
# --since: git log --since value (default: "24 hours ago")
# --repos: comma-separated list of repo paths (default: auto-discover from ~)
#
# Output: plain text summary per repo, skipped if no activity

set -euo pipefail

SINCE="24 hours ago"
REPOS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    --repos) REPOS="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Auto-discover repos if not provided
if [[ -z "$REPOS" ]]; then
  REPO_LIST=$(find ~ -maxdepth 2 -name ".git" -type d 2>/dev/null \
    | sed 's|/.git||' \
    | grep -v -E '(\.oh-my-zsh|\.asdf|\.cargo|agent-workspace)' \
    | sort)
else
  REPO_LIST=$(echo "$REPOS" | tr ',' '\n')
fi

FOUND=0

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue

  # Get recent commits on all local branches
  COMMITS=$(git -C "$repo" log \
    --all \
    --since="$SINCE" \
    --oneline \
    --format="%h %s (%ar, %an)" \
    --no-merges \
    2>/dev/null || true)

  # Check for uncommitted work even if no recent commits
  STAGED=$(git -C "$repo" diff --cached --stat 2>/dev/null | tail -1)
  UNSTAGED=$(git -C "$repo" diff --stat 2>/dev/null | tail -1)
  UNTRACKED=$(git -C "$repo" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  HAS_WIP=0
  [[ -n "$STAGED" ]] && HAS_WIP=1
  [[ -n "$UNSTAGED" ]] && HAS_WIP=1
  [[ "$UNTRACKED" -gt 0 ]] && HAS_WIP=1

  [[ -z "$COMMITS" && "$HAS_WIP" -eq 0 ]] && continue

  FOUND=1
  BRANCH=$(git -C "$repo" branch --show-current 2>/dev/null || echo "detached")
  echo "=== $(basename "$repo") [branch: $BRANCH] ==="

  if [[ -n "$COMMITS" ]]; then
    echo "$COMMITS"
  fi

  if [[ "$HAS_WIP" -eq 1 ]]; then
    echo "--- uncommitted work ---"
    [[ -n "$STAGED" ]] && echo "  staged:    $STAGED"
    [[ -n "$UNSTAGED" ]] && echo "  unstaged:  $UNSTAGED"
    [[ "$UNTRACKED" -gt 0 ]] && echo "  untracked: $UNTRACKED file(s)"
  fi

  echo ""
done <<< "$REPO_LIST"

if [[ $FOUND -eq 0 ]]; then
  echo "No git activity in the last period ($SINCE)."
fi
