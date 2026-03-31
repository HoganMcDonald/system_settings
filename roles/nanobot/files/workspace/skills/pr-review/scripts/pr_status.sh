#!/usr/bin/env bash
# pr_status.sh — fetch PR status across repos
#
# Usage:
#   pr_status.sh --mine                    # open PRs authored by you
#   pr_status.sh --review-requested        # PRs waiting on your review
#   pr_status.sh <owner/repo>              # all open PRs in a repo
#   pr_status.sh <owner/repo> <pr_number>  # single PR detail + CI

set -e

MODE="$1"

# ── cross-repo: my open PRs ──────────────────────────────────────────────────
if [ "$MODE" = "--mine" ]; then
  echo "=== Your Open PRs ==="
  gh search prs --author=@me --state open \
    --json number,title,repository,url,isDraft,updatedAt \
    --limit 30 \
    --jq '.[] | "[\(if .isDraft then "DRAFT" else "OPEN" end)] \(.repository.nameWithOwner) #\(.number): \(.title)\n  \(.url)\n  updated: \(.updatedAt)"'
  exit 0
fi

# ── cross-repo: review requested ────────────────────────────────────────────
if [ "$MODE" = "--review-requested" ]; then
  echo "=== PRs Waiting on Your Review ==="
  gh search prs --review-requested=@me --state open \
    --json number,title,repository,url,author,isDraft,updatedAt \
    --limit 30 \
    --jq '.[] | "[\(if .isDraft then "DRAFT" else "OPEN" end)] \(.repository.nameWithOwner) #\(.number): \(.title)\n  author: \(.author.login) · updated: \(.updatedAt)\n  \(.url)"'
  exit 0
fi

# ── per-repo ─────────────────────────────────────────────────────────────────
REPO="$1"
PR_NUM="$2"

if [ -z "$REPO" ]; then
  echo "Usage:" >&2
  echo "  pr_status.sh --mine" >&2
  echo "  pr_status.sh --review-requested" >&2
  echo "  pr_status.sh <owner/repo> [pr_number]" >&2
  exit 1
fi

if [ -n "$PR_NUM" ]; then
  echo "=== PR #$PR_NUM ==="
  gh pr view "$PR_NUM" --repo "$REPO" \
    --json number,title,state,url,headRefName,reviewDecision,reviews,comments \
    --jq '{
      number: .number,
      title: .title,
      branch: .headRefName,
      url: .url,
      reviewDecision: .reviewDecision,
      reviews: [.reviews[] | {author: .author.login, state: .state, body: .body}],
      comments: [.comments[] | {author: .author.login, body: .body}]
    }'

  echo ""
  echo "=== CI Checks ==="
  gh pr checks "$PR_NUM" --repo "$REPO" 2>/dev/null || echo "No checks found"

else
  echo "=== Open PRs: $REPO ==="
  gh pr list --repo "$REPO" --state open \
    --json number,title,headRefName,reviewDecision,isDraft,url \
    --jq '.[] | "PR #\(.number) [\(if .isDraft then "DRAFT" else .reviewDecision // "PENDING" end)] \(.title) (\(.headRefName))\n  \(.url)"'
fi
