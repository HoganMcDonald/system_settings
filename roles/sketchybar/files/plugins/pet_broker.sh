#!/bin/bash
# Hook dispatcher. Called by Claude Code hooks via settings.json.
# Reads JSON from stdin, mutates pet state, optionally fires speech.
#
# Usage: pet_broker.sh <verb>
#   verb ∈ {session-start, session-end, prompt-submit, tool-start,
#           tool-end-ok, tool-end-fail, stop}
#
# Exits 0 within ~200ms. Never blocks Claude. Never modifies action.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=pet_lib.sh
source "${SCRIPT_DIR}/pet_lib.sh"

verb="${1:-}"
[ -z "$verb" ] && exit 0

# Read stdin (Claude hook JSON). Skip if stdin is a tty (manual run).
hook_json=""
if [ ! -t 0 ]; then
  hook_json=$(cat 2>/dev/null || true)
fi
[ -z "$hook_json" ] && hook_json='{}'

tool_name=$(echo "$hook_json" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
cwd=$(echo "$hook_json" | jq -r '.cwd // ""' 2>/dev/null || echo "")

t=$(now)
state="$(read_state)"
state=$(prune_failures "$state" "$t")

# ─── Tool category for personality routing ──────────────────────────

tool_category() {
  case "$1" in
    Bash)                                echo "shell" ;;
    Edit|Write|NotebookEdit)             echo "code" ;;
    Read|Grep|Glob)                      echo "search" ;;
    WebFetch|WebSearch)                  echo "web" ;;
    Task|Agent)                          echo "task" ;;
    *)                                   echo "" ;;
  esac
}

# ─── Verb dispatch ──────────────────────────────────────────────────

speak_event=""
speak_tool=""
speak_prob=0  # out of 100; 0 = never roll, 100 = always

case "$verb" in
  session-start)
    state=$(echo "$state" | jq --argjson t "$t" '
      .claude.session_active = true |
      .claude.session_started_at = $t |
      .claude.last_event_at = $t |
      .claude.events_this_session = 0 |
      .claude.long_session_announced = false |
      .claude.idle_announced = false
    ')
    speak_event="session-start"; speak_prob=100
    ;;
  session-end)
    state=$(echo "$state" | jq --argjson t "$t" '
      .claude.session_active = false |
      .claude.last_event_at = $t |
      .claude.current_tool = null
    ')
    speak_event="session-end"; speak_prob=50
    ;;
  prompt-submit)
    state=$(echo "$state" | jq --argjson t "$t" '
      .claude.last_event_at = $t |
      .claude.session_active = true |
      .claude.idle_announced = false |
      .claude.events_this_session += 1
    ')
    speak_event="prompt-submit"; speak_prob=10
    # Subtle attention shake.
    ( "${SCRIPT_DIR}/pet_animate.sh" content >/dev/null 2>&1 & )
    ;;
  tool-start)
    cat=$(tool_category "$tool_name")
    state=$(echo "$state" | jq --argjson t "$t" --arg tn "$tool_name" '
      .claude.last_event_at = $t |
      .claude.current_tool = $tn |
      .claude.events_this_session += 1 |
      .claude.session_active = true |
      .claude.idle_announced = false
    ')
    if [ -n "$cat" ]; then
      speak_event="tool-start-${cat}"; speak_tool="$tool_name"; speak_prob=5
    fi
    ;;
  tool-end-ok)
    state=$(echo "$state" | jq --argjson t "$t" '
      .claude.last_event_at = $t |
      .claude.current_tool = null
    ')
    ;;
  tool-end-fail)
    state=$(echo "$state" | jq --argjson t "$t" '
      .claude.last_event_at = $t |
      .claude.current_tool = null |
      .claude.recent_failures += [$t]
    ')
    fails=$(echo "$state" | jq -r '.claude.recent_failures | length')
    if [ "$fails" -ge 3 ]; then
      # Cluster: stronger response, drop cleanliness.
      state=$(echo "$state" | jq '
        def clamp: if . < 0 then 0 elif . > 100 then 100 else . end;
        .cleanliness = ((.cleanliness - 10) | clamp) |
        .claude.recent_failures = []
      ')
      speak_event="failure-cluster"; speak_tool="$tool_name"; speak_prob=100
      ( "${SCRIPT_DIR}/pet_animate.sh" cleanliness >/dev/null 2>&1 & )
    else
      speak_event="tool-end-fail"; speak_tool="$tool_name"; speak_prob=30
      ( "${SCRIPT_DIR}/pet_animate.sh" happiness >/dev/null 2>&1 & )
    fi
    ;;
  stop)
    state=$(echo "$state" | jq --argjson t "$t" '
      .claude.last_event_at = $t |
      .claude.current_tool = null
    ')
    ;;
  *)
    exit 0
    ;;
esac

# ─── Long-session milestone ─────────────────────────────────────────

session_started=$(echo "$state" | jq -r '.claude.session_started_at')
long_announced=$(echo "$state" | jq -r '.claude.long_session_announced')
if [ "$long_announced" = "false" ] && [ "$session_started" -gt 0 ] \
   && [ $(( t - session_started )) -ge 1800 ]; then
  state=$(echo "$state" | jq '.claude.long_session_announced = true')
  # Override speech selection for this tick.
  speak_event="long-session"; speak_prob=100
fi

# ─── Persist & maybe speak ──────────────────────────────────────────

write_state "$state"
sketchybar --trigger pet_action >/dev/null 2>&1

# Append to events log (capped at 100 lines).
EVENTS_LOG="${STATE_DIR}/events.jsonl"
jq -nc \
  --argjson t "$t" --arg v "$verb" --arg tn "$tool_name" --arg c "$cwd" \
  '{t:$t, verb:$v, tool:$tn, cwd:$c}' >> "$EVENTS_LOG"
if [ -f "$EVENTS_LOG" ]; then
  tail -n 100 "$EVENTS_LOG" > "${EVENTS_LOG}.tmp" && mv "${EVENTS_LOG}.tmp" "$EVENTS_LOG"
fi

# Roll the dice and speak.
if [ -n "$speak_event" ] && [ "$speak_prob" -gt 0 ]; then
  if [ "$speak_prob" -ge 100 ] || [ $(( RANDOM % 100 )) -lt "$speak_prob" ]; then
    last_spoke=$(echo "$state" | jq -r '.last_spoke')
    # Throttle except for milestones (always allowed).
    is_milestone=false
    case "$speak_event" in
      session-start|failure-cluster|long-session|idle) is_milestone=true ;;
    esac
    if [ "$is_milestone" = "true" ] || [ $(( t - last_spoke )) -ge "$SPEECH_THROTTLE_SECONDS" ]; then
      PET_CWD="$cwd" "${SCRIPT_DIR}/pet_voice.sh" "$speak_event" "$speak_tool" >/dev/null 2>&1 &
      disown
      # Note: pet_voice.sh re-reads state to update last_ai_call.
      # We update last_spoke here for static path; AI path will overwrite via emit.
      fresh=$(read_state | jq --argjson t "$t" '.last_spoke = $t')
      write_state "$fresh"
    fi
  fi
fi

exit 0
