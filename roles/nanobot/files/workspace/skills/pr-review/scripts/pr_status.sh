#!/usr/bin/env bash
# Usage: pr_status.sh <owner/repo> [pr_number]
# Outputs a JSON summary of open PRs and their review/CI state.
# If pr_number is provided, outputs detail for that PR only.

set -e

REPO="$1"
PR_NUM="$2"

if [ -z "$REPO" ]; then
  echo "Usage: pr_status.sh <owner/repo> [pr_number]" >&2
  exit 1
fi

if [ -n "$PR_NUM" ]; then
  # Single PR detail: title, state, reviews, comments, checks
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
  # All open PRs summary
  gh pr list --repo "$REPO" --state open \
    --json number,title,headRefName,reviewDecision,isDraft,url \
    --jq '.[] | "PR #\(.number) [\(if .isDraft then "DRAFT" else .reviewDecision // "PENDING" end)] \(.title) (\(.headRefName))\n  \(.url)"'
fi
