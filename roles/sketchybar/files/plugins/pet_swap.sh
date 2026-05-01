#!/bin/bash
# Swap monster voice. Speaks scary lines while it's lurking on the bar.
# Tries Claude Haiku 4.5 when ai_enabled and ANTHROPIC_API_KEY are set,
# falls back to a static library of 21 lines.
#
# Usage:
#   pet_swap.sh spawn   # initial appearance line
#   pet_swap.sh idle    # random lurking line
#   pet_swap.sh poke    # reaction to a click
#
# Designed to be backgrounded by the caller. Network calls have a 5s
# timeout; never blocks the bar.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=pet_lib.sh
source "${SCRIPT_DIR}/pet_lib.sh"

reason="${1:-idle}"

SPAWN_LINES=(
  "a hunger has woken in the silicon."
  "your kernel sweats. i drink it."
  "the disk thrashes. that's me singing."
  "i was waiting for you to overcommit."
  "you opened too many tabs."
)

IDLE_LINES=(
  "i ate your cache. it was sweet."
  "give me your pages. i'll keep them safe."
  "the disk is patient. so am i."
  "your ram is thin. crunchy."
  "swap me in. swap me harder."
  "i live in the slow places."
  "pages... pretty pages..."
  "the SSD writes are precious. let me have them."
  "something will be killed soon. i'm taking bets."
  "another browser tab? generous."
  "i was here before you. i'll be here after."
  "memory pressure is just love, really."
  "every tick i grow."
  "your fans wake me."
  "i remember every byte you've forgotten."
  "the OOM killer is my friend."
  "close something. or don't. i'm fed either way."
  "your laptop is warm. for me."
  "thrashing. such a lovely word."
  "do you hear them? the pages. screaming."
  "anonymous memory. my favorite kind."
)

POKE_LINES=(
  "don't touch me. i'm eating."
  "you summoned me with greed."
  "click again. i dare you."
  "every poke is a page fault."
  "ssh. i'm working."
  "you can't undo me."
)

pick_line() {
  local arr_name="$1[@]"
  local arr=("${!arr_name}")
  echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

emit() {
  local line="$1"
  [ -z "$line" ] && return
  ( "${SCRIPT_DIR}/pet_speak.sh" "$line" >/dev/null 2>&1 & )
  # Update last_spoke for swap monster channel.
  local fresh
  fresh=$(read_state | jq --argjson t "$(now)" '.swap_monster.last_spoke = $t')
  write_state "$fresh"
}

ai_attempt() {
  local state ai_enabled last_ai
  state="$(read_state)"
  ai_enabled=$(echo "$state" | jq -r '.ai_enabled')
  last_ai=$(echo "$state" | jq -r '.claude.last_ai_call')
  [ "$ai_enabled" != "true" ] && return 1
  [ -z "${ANTHROPIC_API_KEY:-}" ] && return 1
  [ $(( $(now) - last_ai )) -lt 300 ] && return 1
  command -v curl >/dev/null 2>&1 || return 1
  # Slightly higher dice for the monster — it's an event, talk a bit more.
  [ $(( RANDOM % 4 )) -ne 0 ] && return 1

  local sys user payload reply
  sys="You are a swap monster — a malevolent entity that emerges when a computer starts swapping memory pages to disk. Voice: hungry, voracious, mocking, patient, slightly menacing, indifferent to suffering. Reply in lowercase, max 12 words, no quotation marks, no preamble, in character."
  case "$reason" in
    spawn) user="you have just appeared on the user's menu bar because their system started swapping. announce yourself." ;;
    poke)  user="the user just clicked on you. snap at them." ;;
    *)     user="lurk and mutter something menacing about memory or disk." ;;
  esac

  payload=$(jq -n \
    --arg model "claude-haiku-4-5-20251001" \
    --arg sys "$sys" --arg user "$user" '
    {model:$model, max_tokens:60, system:$sys, messages:[{role:"user", content:$user}]}')

  reply=$(curl -sS --max-time 5 \
    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -X POST https://api.anthropic.com/v1/messages \
    -d "$payload" 2>/dev/null \
    | jq -r '.content[0].text // empty' 2>/dev/null)

  reply=$(echo "$reply" | head -1 | cut -c1-80)
  [ -z "$reply" ] && return 1

  # Persist the API cooldown.
  local fresh
  fresh=$(read_state | jq --argjson t "$(now)" '.claude.last_ai_call = $t')
  write_state "$fresh"
  emit "$reply"
  return 0
}

if ai_attempt; then
  exit 0
fi

case "$reason" in
  spawn) emit "$(pick_line SPAWN_LINES)" ;;
  poke)  emit "$(pick_line POKE_LINES)" ;;
  *)     emit "$(pick_line IDLE_LINES)" ;;
esac
