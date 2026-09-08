#!/usr/bin/env bash
#
# Tests for the pure helpers in roles/zsh/files/bin/review.
#
# Usage: roles/zsh/tests/test_review.sh

set -uo pipefail

# Business-time math depends on the local zone, so pin it for determinism.
export TZ=America/Los_Angeles

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
REVIEW_BIN="$SCRIPT_DIR/../files/bin/review"

if [ ! -f "$REVIEW_BIN" ]; then
  echo "Error: cannot find review at $REVIEW_BIN" >&2
  exit 1
fi

# shellcheck source=../files/bin/review
REVIEW_LIB_ONLY=1 source "$REVIEW_BIN"

PASS=0
FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"

  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf '  ok    %s\n' "$label"
  else
    FAIL=$((FAIL + 1))
    printf '  FAIL  %s\n' "$label"
    printf '        expected: %q\n' "$expected"
    printf '        actual:   %q\n' "$actual"
  fi
}

section() {
  printf '\n%s\n' "$1"
}

# Use the library's portable wrappers so the suite runs under BSD and GNU date.
epoch_at() {
  localtime_to_epoch "$1"
}

# --- date portability --------------------------------------------------------

section "date flavor (BSD vs GNU)"
printf '  info  detected flavor: %s (%s)\n' "$REVIEW_DATE_FLAVOR" "$(command -v date)"
assert_eq "detects a supported date(1)" "supported" \
  "$([ "$REVIEW_DATE_FLAVOR" != unknown ] && echo supported || echo unknown)"

# A nix-shell or devbox puts GNU coreutils ahead of /bin, so an unsupported
# date must fail loudly rather than silently returning an empty timestamp.
DATE_STATUS=0
(
  REVIEW_DATE_FLAVOR=unknown
  iso_to_epoch '2026-08-03T10:00:00Z'
) > /dev/null 2>&1 || DATE_STATUS=$?
assert_eq "unknown flavor fails instead of returning empty" "1" "$DATE_STATUS"

DATE_STATUS=0
(
  REVIEW_DATE_FLAVOR=unknown
  epoch_format 0 '%Y'
) > /dev/null 2>&1 || DATE_STATUS=$?
assert_eq "epoch_format guards too" "1" "$DATE_STATUS"

# --- classify_ref ------------------------------------------------------------

section "classify_ref"
assert_eq "HEAD" "head" "$(classify_ref HEAD)"
assert_eq "lowercase head" "head" "$(classify_ref head)"
assert_eq "bare number" "pr" "$(classify_ref 1234)"
assert_eq "hash number" "pr" "$(classify_ref '#1234')"
assert_eq "pr url" "pr-url" "$(classify_ref 'https://github.com/hex-inc/hex/pull/47781')"
assert_eq "pr url with files tab" "pr-url" "$(classify_ref 'https://github.com/o/r/pull/9/files')"
assert_eq "linear url" "linear" "$(classify_ref 'https://linear.app/hex/issue/HEX-4821/fix-it')"
assert_eq "linear bare id" "linear" "$(classify_ref 'HEX-4821')"
assert_eq "branch" "branch" "$(classify_ref 'feat/add-auth')"
assert_eq "branch that looks numeric-ish" "branch" "$(classify_ref 'release-2024-01')"
assert_eq "linear-style branch is a branch" "branch" "$(classify_ref 'hogan/hex-4821-fix')"

# --- linear_ticket_from_ref --------------------------------------------------

section "linear_ticket_from_ref"
assert_eq "from url" "HEX-4821" "$(linear_ticket_from_ref 'https://linear.app/hex/issue/HEX-4821/fix-it')"
assert_eq "from lowercase url" "HEX-4821" "$(linear_ticket_from_ref 'https://linear.app/hex/issue/hex-4821/fix-it')"
assert_eq "from bare id" "HEX-4821" "$(linear_ticket_from_ref 'HEX-4821')"
linear_ticket_from_ref 'feat/add-auth' > /dev/null 2>&1
assert_eq "rejects a branch" "1" "$?"

# --- parse_pr_url ------------------------------------------------------------

section "parse_pr_url"
assert_eq "splits repo and number" "hex-inc/hex 47781" \
  "$(parse_pr_url 'https://github.com/hex-inc/hex/pull/47781')"
assert_eq "ignores trailing path" "o/r 9" \
  "$(parse_pr_url 'https://github.com/o/r/pull/9/files#diff-abc')"
parse_pr_url 'https://github.com/o/r/issues/9' > /dev/null 2>&1
assert_eq "rejects issue url" "1" "$?"

# --- normalize_pr_number -----------------------------------------------------

section "normalize_pr_number"
assert_eq "strips hash" "1234" "$(normalize_pr_number '#1234')"
assert_eq "passes through" "1234" "$(normalize_pr_number '1234')"

# --- business_seconds --------------------------------------------------------

section "business_seconds (weekends excluded)"

# Friday 15:00 -> Monday 15:00 is 72 wall hours but exactly 24 business hours.
fri=$(epoch_at '2026-08-28 15:00:00')
mon=$(epoch_at '2026-08-31 15:00:00')
assert_eq "Fri 15:00 -> Mon 15:00 is 24h" "86400" "$(business_seconds "$fri" "$mon")"

# Same weekday window counts in full.
tue_am=$(epoch_at '2026-08-25 09:00:00')
tue_pm=$(epoch_at '2026-08-25 17:30:00')
assert_eq "Tue 09:00 -> 17:30 is 8h30m" "30600" "$(business_seconds "$tue_am" "$tue_pm")"

# A window entirely inside the weekend contributes nothing.
sat=$(epoch_at '2026-08-29 01:00:00')
sun=$(epoch_at '2026-08-30 23:00:00')
assert_eq "Sat -> Sun is 0" "0" "$(business_seconds "$sat" "$sun")"

# Friday noon into Saturday only counts the Friday remainder.
fri_noon=$(epoch_at '2026-08-28 12:00:00')
sat_noon=$(epoch_at '2026-08-29 12:00:00')
assert_eq "Fri 12:00 -> Sat 12:00 is 12h" "43200" "$(business_seconds "$fri_noon" "$sat_noon")"

# A full business week is five days.
mon_start=$(epoch_at '2026-08-24 00:00:00')
next_mon=$(epoch_at '2026-08-31 00:00:00')
assert_eq "one calendar week is 5 business days" "432000" "$(business_seconds "$mon_start" "$next_mon")"

assert_eq "end before start is 0" "0" "$(business_seconds "$mon" "$fri")"
assert_eq "equal bounds is 0" "0" "$(business_seconds "$fri" "$fri")"

# Spring-forward Sunday must not leak an hour into the Monday count.
dst=$(epoch_at '2026-03-06 15:00:00')
dst_mon=$(epoch_at '2026-03-09 15:00:00')
assert_eq "DST weekend still yields 24h" "86400" "$(business_seconds "$dst" "$dst_mon")"

# --- format_duration ---------------------------------------------------------

section "format_duration"
assert_eq "minutes" "45m" "$(format_duration 2700)"
assert_eq "hours and minutes" "3h 30m" "$(format_duration 12600)"
assert_eq "days and hours" "2d 3h" "$(format_duration 183600)"
assert_eq "negative is absolute" "1h 0m" "$(format_duration -3600)"
assert_eq "zero" "0m" "$(format_duration 0)"

# --- sla_cell ----------------------------------------------------------------

section "sla_cell"
assert_eq "within sla" "6h 0m left" "$(sla_cell 64800 86400)"
assert_eq "at the boundary" "0m left" "$(sla_cell 86400 86400)"
assert_eq "breached" "OVER by 2h 0m" "$(sla_cell 93600 86400)"
assert_eq "fresh request" "1d 0h left" "$(sla_cell 0 86400)"

# --- end_of_day_epoch --------------------------------------------------------

section "end_of_day_epoch"
midday=$(epoch_at '2026-08-31 13:37:00')
assert_eq "rolls to next midnight" "2026-09-01 00:00:00" \
  "$(epoch_format "$(end_of_day_epoch "$midday")" '%Y-%m-%d %H:%M:%S')"
late=$(epoch_at '2026-08-31 23:59:59')
assert_eq "just before midnight" "2026-09-01 00:00:00" \
  "$(epoch_format "$(end_of_day_epoch "$late")" '%Y-%m-%d %H:%M:%S')"
assert_eq "snooze is in the future" "future" \
  "$([ "$(end_of_day_epoch "$midday")" -gt "$midday" ] && echo future || echo past)"

# --- sanitize_cell / truncate_cell -------------------------------------------

section "sanitize_cell"
assert_eq "strips emoji and em dash" "Add zoxide smart cd" \
  "$(sanitize_cell '🚀 Add zoxide — smart cd')"
assert_eq "keeps ascii punctuation" "SEC-6088: require confirmation" \
  "$(sanitize_cell 'SEC-6088: require confirmation')"
assert_eq "collapses whitespace" "a b" "$(sanitize_cell 'a    b')"

section "truncate_cell"
assert_eq "leaves short text" "short" "$(truncate_cell 'short' 10)"
assert_eq "truncates with ellipsis" "abcdefg..." "$(truncate_cell 'abcdefghijklmno' 10)"
assert_eq "exact length untouched" "abcde" "$(truncate_cell 'abcde' 5)"

# --- render_table ------------------------------------------------------------

section "render_table"

# Force a deterministic style; auto-detection depends on the ambient locale.
REVIEW_BORDER=ascii setup_borders
REVIEW_COLOR=never setup_colors

TABLE=$(printf 'PR\tAUTHOR\tTITLE\n#1\tbob\thello\n#22\talice\t\n' | render_table)
assert_eq "ascii borders align and keep empty cells" \
  "+-----+--------+-------+
| PR  | AUTHOR | TITLE |
+-----+--------+-------+
| #1  | bob    | hello |
| #22 | alice  |       |
+-----+--------+-------+" \
  "$TABLE"
assert_eq "empty input renders nothing" "" "$(printf '' | render_table)"

REVIEW_BORDER=utf8 setup_borders
TABLE=$(printf 'PR\tAUTHOR\tTITLE\n#1\tbob\thello\n#22\talice\t\n' | render_table)
assert_eq "box-drawing borders align" \
  "┌─────┬────────┬───────┐
│ PR  │ AUTHOR │ TITLE │
├─────┼────────┼───────┤
│ #1  │ bob    │ hello │
│ #22 │ alice  │       │
└─────┴────────┴───────┘" \
  "$TABLE"

# The whole point of the \001colour\002 marker: escapes must not reach the
# width calculation, so a painted table must align exactly like a plain one.
PLAIN=$(printf 'PR\tSLA\n#1\tOVER by 2h\n#22\t5h left\n' | render_table)
MARKED=$(
  {
    printf 'PR\tSLA\n'
    printf '%s\t%s\n' "$(paint cyan '#1')" "$(paint red 'OVER by 2h')"
    printf '%s\t%s\n' "$(paint cyan '#22')" "$(paint green '5h left')"
  } | render_table
)
assert_eq "colour markers are stripped when colour is off" "$PLAIN" "$MARKED"

REVIEW_COLOR=always setup_colors
COLORED=$(
  {
    printf 'PR\tSLA\n'
    printf '%s\t%s\n' "$(paint cyan '#1')" "$(paint red 'OVER by 2h')"
    printf '%s\t%s\n' "$(paint cyan '#22')" "$(paint green '5h left')"
  } | render_table
)
assert_eq "colour output emits ANSI" "yes" \
  "$(printf '%s' "$COLORED" | grep -q $'\033\[31m' && echo yes || echo no)"
assert_eq "no sentinel markers leak into output" "clean" \
  "$(printf '%s' "$COLORED" | grep -q $'[\001\002]' && echo leaked || echo clean)"
# Widths must match the uncoloured render once escapes are stripped back out.
assert_eq "coloured rows keep plain widths" "$PLAIN" \
  "$(printf '%s' "$COLORED" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')"
REVIEW_COLOR=never setup_colors

section "sla_color"
assert_eq "comfortable is green" "green" "$(sla_color 3600 86400)"
assert_eq "under 4h remaining is yellow" "yellow" "$(sla_color 79200 86400)"
assert_eq "breached is red" "red" "$(sla_color 90000 86400)"
assert_eq "exactly at target is yellow" "yellow" "$(sla_color 86400 86400)"

# --- snooze state ------------------------------------------------------------

section "snooze state"

# The state helpers only need GIT_COMMON_DIR, so they can run against a temp dir.
STATE_DIR=$(mktemp -d)
GIT_COMMON_DIR="$STATE_DIR"
NOW=$(date '+%s')

assert_eq "starts with no snoozes" "" "$(state_snoozed_prs)"
assert_eq "missing state file reads as empty" "{}" "$(state_read | jq -c '.snoozes')"

state_snooze 202 "$((NOW + 7200))"
state_snooze 101 "$((NOW + 3600))"
assert_eq "lists snoozed, soonest expiry first" "101
202" "$(state_snoozed_prs)"
assert_eq "snoozed_until returns the epoch" "$((NOW + 3600))" "$(state_snoozed_until 101)"

state_unsnooze 101
assert_eq "unsnooze removes only its target" "202" "$(state_snoozed_prs)"
assert_eq "unsnoozed PR has no expiry" "" "$(state_snoozed_until 101)"

state_snooze 303 "$((NOW + 60))"
state_clear_snoozes
assert_eq "clear_snoozes empties the map" "" "$(state_snoozed_prs)"

# Expiry is enforced on read, so an elapsed snooze needs no cleanup pass.
state_snooze 404 "$((NOW - 60))"
assert_eq "expired snooze is pruned on read" "" "$(state_snoozed_prs)"
assert_eq "expired snooze has no expiry" "" "$(state_snoozed_until 404)"

state_snooze 505 "$((NOW + 3600))"
state_snooze 606 "$((NOW - 60))"
assert_eq "prune keeps live entries" "505" "$(state_snoozed_prs)"
state_clear_snoozes

# --- worktree state ----------------------------------------------------------

section "worktree state"

assert_eq "starts with no worktrees" "" "$(state_worktree_rows)"

state_register_worktree 707 "/tmp/wt-707" "review/pr-707" "o/r" \
  "https://github.com/o/r/pull/707" "A title with	a tab" "alice"

assert_eq "records the path" "/tmp/wt-707" "$(state_worktree_field 707 path)"
assert_eq "records the session" "review/pr-707" "$(state_worktree_field 707 session)"
assert_eq "row has 7 fields" "7" \
  "$(state_worktree_rows | awk -F"$REVIEW_FS" '{print NF}')"
assert_eq "tabs in the title are neutralised" "A title with a tab" \
  "$(state_worktree_rows | cut -d "$REVIEW_FS" -f6)"

state_set_session 707 "renamed/session"
assert_eq "session can be updated" "renamed/session" "$(state_worktree_field 707 session)"

state_register_worktree 808 "/tmp/wt-808" "s" "o/r" "u" "t" "bob"
assert_eq "rows sort numerically by PR" "707
808" "$(state_worktree_rows | cut -d "$REVIEW_FS" -f1)"

state_forget_worktree 707
assert_eq "forget removes only its target" "808" \
  "$(state_worktree_rows | cut -d "$REVIEW_FS" -f1)"

# Snoozes and worktrees are independent: clearing a worktree keeps the snooze.
state_snooze 808 "$((NOW + 3600))"
state_forget_worktree 808
assert_eq "clearing a worktree keeps its snooze" "808" "$(state_snoozed_prs)"

rm -rf "$STATE_DIR"
unset GIT_COMMON_DIR

# --- queue_transform ---------------------------------------------------------

section "queue_transform"

FIXTURE=$(
  cat << 'JSON'
{
  "data": {
    "repository": {
      "p0": {
        "number": 101,
        "title": "Oldest pending",
        "url": "https://github.com/o/r/pull/101",
        "isDraft": false,
        "additions": 10,
        "deletions": 2,
        "changedFiles": 3,
        "createdAt": "2026-08-01T00:00:00Z",
        "headRefName": "feat/a",
        "baseRefName": "main",
        "author": { "login": "alice" },
        "timelineItems": { "nodes": [
          { "createdAt": "2026-08-02T10:00:00Z", "requestedReviewer": { "login": "someone-else" } },
          { "createdAt": "2026-08-03T10:00:00Z", "requestedReviewer": { "login": "me" } }
        ] },
        "reviews": { "nodes": [] }
      },
      "p1": {
        "number": 102,
        "title": "Already reviewed",
        "url": "https://github.com/o/r/pull/102",
        "isDraft": false,
        "additions": 1,
        "deletions": 1,
        "changedFiles": 1,
        "createdAt": "2026-08-01T00:00:00Z",
        "headRefName": "feat/b",
        "baseRefName": "main",
        "author": { "login": "bob" },
        "timelineItems": { "nodes": [
          { "createdAt": "2026-08-02T10:00:00Z", "requestedReviewer": { "login": "me" } }
        ] },
        "reviews": { "nodes": [
          { "state": "APPROVED", "submittedAt": "2026-08-02T12:00:00Z", "author": { "login": "me" } }
        ] }
      },
      "p2": {
        "number": 103,
        "title": "Re-requested after my review",
        "url": "https://github.com/o/r/pull/103",
        "isDraft": false,
        "additions": 5,
        "deletions": 5,
        "changedFiles": 2,
        "createdAt": "2026-08-01T00:00:00Z",
        "headRefName": "feat/c",
        "baseRefName": "main",
        "author": { "login": "carol" },
        "timelineItems": { "nodes": [
          { "createdAt": "2026-08-02T10:00:00Z", "requestedReviewer": { "login": "me" } },
          { "createdAt": "2026-08-05T10:00:00Z", "requestedReviewer": { "login": "me" } }
        ] },
        "reviews": { "nodes": [
          { "state": "CHANGES_REQUESTED", "submittedAt": "2026-08-02T12:00:00Z", "author": { "login": "me" } }
        ] }
      },
      "p3": {
        "number": 104,
        "title": "Draft from a bot",
        "url": "https://github.com/o/r/pull/104",
        "isDraft": true,
        "additions": 7,
        "deletions": 0,
        "changedFiles": 1,
        "createdAt": "2026-08-04T00:00:00Z",
        "headRefName": "feat/d",
        "baseRefName": "main",
        "author": null,
        "timelineItems": { "nodes": [] },
        "reviews": { "nodes": [] }
      }
    }
  }
}
JSON
)

QUEUE=$(printf '%s' "$FIXTURE" | queue_transform me)

# 102 is gone (reviewed); the rest are ordered by when review was requested:
# 101 on 08-03, 104 on 08-04 (falls back to createdAt), 103 re-requested 08-05.
assert_eq "drops reviewed PRs and orders by request time" "101 104 103" \
  "$(printf '%s' "$QUEUE" | jq -r '[.[].number] | join(" ")')"
assert_eq "sorted oldest request first" "101" \
  "$(printf '%s' "$QUEUE" | jq -r '.[0].number')"
assert_eq "uses my request event, not someone else's" "2026-08-03T10:00:00Z" \
  "$(printf '%s' "$QUEUE" | jq -r '.[] | select(.number == 101) | .requested_at')"
assert_eq "re-request reopens the clock" "2026-08-05T10:00:00Z" \
  "$(printf '%s' "$QUEUE" | jq -r '.[] | select(.number == 103) | .requested_at')"
assert_eq "falls back to PR creation when no event" "2026-08-04T00:00:00Z" \
  "$(printf '%s' "$QUEUE" | jq -r '.[] | select(.number == 104) | .requested_at')"
assert_eq "null author becomes unknown" "unknown" \
  "$(printf '%s' "$QUEUE" | jq -r '.[] | select(.number == 104) | .author')"
assert_eq "draft flag preserved" "true" \
  "$(printf '%s' "$QUEUE" | jq -r '.[] | select(.number == 104) | .draft')"
assert_eq "loc carried through" "10 2" \
  "$(printf '%s' "$QUEUE" | jq -r '.[] | select(.number == 101) | "\(.additions) \(.deletions)"')"

section "queue_transform (HEAD selection)"

# HEAD skips drafts, and skips anything snoozed.
head_pick() {
  local snoozes="$1"
  printf '%s' "$QUEUE" | jq -r --argjson snoozes "$snoozes" '
    map(select(.draft == false))
    | map(select((.number | tostring) as $n | ($snoozes | index($n)) == null))
    | .[0].number // empty
  '
}

assert_eq "picks oldest non-draft" "101" "$(head_pick '[]')"
assert_eq "skips snoozed PR" "103" "$(head_pick '["101"]')"
assert_eq "never picks a draft" "" "$(head_pick '["101","103"]')"

# --- iso_to_epoch ------------------------------------------------------------

section "iso_to_epoch"
assert_eq "parses github timestamp" "$(TZ=UTC epoch_at '2026-08-03 10:00:00')" \
  "$(iso_to_epoch '2026-08-03T10:00:00Z')"

# --- Summary -----------------------------------------------------------------

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
