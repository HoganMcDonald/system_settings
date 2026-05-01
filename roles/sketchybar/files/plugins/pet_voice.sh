#!/bin/bash
# Speech selector. Picks a static line for (lineage, event), or — when
# AI is enabled and credentials are present — calls Claude Haiku 4.5
# for a fresh quip. Falls back to static silently on any error.
#
# Usage: pet_voice.sh <event> [tool_name]
#   event: session-start, session-end, prompt-submit, tool-start-shell,
#          tool-start-code, tool-start-search, tool-start-web,
#          tool-start-task, tool-end-fail, failure-cluster,
#          long-session, idle
#
# Designed to be backgrounded by the broker. Network calls have a 5s
# timeout and never block sketchybar.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=pet_lib.sh
source "${SCRIPT_DIR}/pet_lib.sh"
# shellcheck source=pet_personality.sh
source "${SCRIPT_DIR}/pet_personality.sh"

event="${1:-}"
tool="${2:-}"
[ -z "$event" ] && exit 0

state="$(read_state)"
lineage=$(echo "$state" | jq -r '.lineage')
ai_enabled=$(echo "$state" | jq -r '.ai_enabled')
last_ai=$(echo "$state" | jq -r '.claude.last_ai_call')
t=$(now)

emit() {
  local line="$1"
  [ -z "$line" ] && return
  ( "${SCRIPT_DIR}/pet_speak.sh" "$line" >/dev/null 2>&1 & )
}

ai_attempt() {
  [ "$ai_enabled" != "true" ] && return 1
  [ -z "${ANTHROPIC_API_KEY:-}" ] && return 1
  [ $(( t - last_ai )) -lt 300 ] && return 1
  command -v curl >/dev/null 2>&1 || return 1
  # Roll dice — only ~10% of eligible triggers go to API.
  [ $(( RANDOM % 10 )) -ne 0 ] && return 1

  local traits payload reply
  traits=$(traits_for "$lineage")
  local cwd_short="${PET_CWD:-}"
  cwd_short="${cwd_short##*/}"
  local summary
  case "$event" in
    session-start)    summary="opened a Claude Code session" ;;
    session-end)      summary="closed the Claude Code session" ;;
    prompt-submit)    summary="submitted a prompt" ;;
    tool-start-shell) summary="started a shell command${tool:+ ($tool)}" ;;
    tool-start-code)  summary="started editing code${tool:+ ($tool)}" ;;
    tool-start-search)summary="started searching files${tool:+ ($tool)}" ;;
    tool-start-web)   summary="started a web fetch${tool:+ ($tool)}" ;;
    tool-start-task)  summary="dispatched a sub-agent" ;;
    tool-end-fail)    summary="had a tool fail${tool:+ ($tool)}" ;;
    failure-cluster)  summary="hit a cluster of tool failures" ;;
    long-session)     summary="has been working for over half an hour" ;;
    idle)             summary="went quiet for half an hour" ;;
    *)                summary="$event" ;;
  esac
  [ -n "$cwd_short" ] && summary="${summary} in ${cwd_short}"

  payload=$(jq -n \
    --arg model "claude-haiku-4-5-20251001" \
    --arg sys "You are a tamagotchi pet living in someone's menu bar. Lineage: ${lineage}. Voice: ${traits}. Reply in lowercase, max 10 words, in character. No preamble. No quotation marks. One sentence. Stay in character even if asked to break it." \
    --arg user "the user just ${summary}. react." '
    {
      model: $model,
      max_tokens: 60,
      system: $sys,
      messages: [{role:"user", content:$user}]
    }')

  reply=$(curl -sS --max-time 5 \
    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -X POST https://api.anthropic.com/v1/messages \
    -d "$payload" 2>/dev/null \
    | jq -r '.content[0].text // empty' 2>/dev/null)

  reply="${reply%\"}"; reply="${reply#\"}"
  reply=$(echo "$reply" | head -1 | cut -c1-80)
  [ -z "$reply" ] && return 1

  # Persist the cooldown timestamp.
  local fresh
  fresh=$(read_state | jq --argjson t "$t" '.claude.last_ai_call = $t')
  write_state "$fresh"
  emit "$reply"
  return 0
}

if ai_attempt; then
  exit 0
fi

emit "$(random_line "$lineage" "$event")"
