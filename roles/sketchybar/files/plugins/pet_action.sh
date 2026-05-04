#!/bin/bash
# Mutate pet state based on a menu verb. Called by popup row click_scripts
# and by the npc click_script.
#
#   pet_action.sh feed|play|clean|pet|bury|npc

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=pet_lib.sh
source "${SCRIPT_DIR}/pet_lib.sh"

verb="${1:-}"
[ -z "$verb" ] && exit 0

state="$(read_state)"
t=$(now)
alive=$(echo "$state" | jq -r '.alive')

flash_row_red() {
  local row="$1"
  sketchybar --set "$row" icon.color="$PET_COLOR_RED" \
             --animate sin 30 --set "$row" icon.color="$PET_COLOR_TEXT" >/dev/null 2>&1
}

case "$verb" in
  feed)
    [ "$alive" = "true" ] || exit 0
    last=$(echo "$state" | jq -r '.last_fed')
    if [ $(( t - last )) -lt "$COOLDOWN_SECONDS" ]; then
      flash_row_red pet.feed; exit 0
    fi
    state=$(echo "$state" | jq --argjson t "$t" '.hunger = 100 | .last_fed = $t')
    ( "${SCRIPT_DIR}/pet_animate.sh" content >/dev/null 2>&1 & )
    ;;
  play)
    [ "$alive" = "true" ] || exit 0
    last=$(echo "$state" | jq -r '.last_played')
    if [ $(( t - last )) -lt "$COOLDOWN_SECONDS" ]; then
      flash_row_red pet.play; exit 0
    fi
    state=$(echo "$state" | jq --argjson t "$t" '.happiness = 100 | .last_played = $t')
    ( "${SCRIPT_DIR}/pet_animate.sh" content >/dev/null 2>&1 & )
    ;;
  clean)
    [ "$alive" = "true" ] || exit 0
    last=$(echo "$state" | jq -r '.last_cleaned')
    if [ $(( t - last )) -lt "$COOLDOWN_SECONDS" ]; then
      flash_row_red pet.clean; exit 0
    fi
    state=$(echo "$state" | jq --argjson t "$t" '.cleanliness = 100 | .last_cleaned = $t')
    ( "${SCRIPT_DIR}/pet_animate.sh" content >/dev/null 2>&1 & )
    ;;
  coffee)
    [ "$alive" = "true" ] || exit 0
    last=$(echo "$state" | jq -r '.last_coffee')
    if [ $(( t - last )) -lt "$COOLDOWN_SECONDS" ]; then
      flash_row_red pet.coffee; exit 0
    fi
    state=$(echo "$state" | jq --argjson t "$t" '.energy = 100 | .last_coffee = $t')
    ( "${SCRIPT_DIR}/pet_animate.sh" content >/dev/null 2>&1 & )
    ;;
  pet)
    [ "$alive" = "true" ] || exit 0
    state=$(echo "$state" | jq --argjson t "$t" '
      .happiness = ([.happiness + 10, 100] | min) |
      .last_petted = $t
    ')
    ( "${SCRIPT_DIR}/pet_animate.sh" content >/dev/null 2>&1 & )
    ;;
  bury)
    [ "$alive" = "false" ] || exit 0
    lineage=$(echo "$state" | jq -r '.lineage')
    state=$(default_state | jq --arg l "$lineage" '.lineage = $l')
    ;;
  toggle-ai)
    state=$(echo "$state" | jq '.ai_enabled = (.ai_enabled | not)')
    new=$(echo "$state" | jq -r '.ai_enabled')
    if [ "$new" = "true" ]; then
      sketchybar --set pet.ai label="  AI: on" >/dev/null 2>&1
    else
      sketchybar --set pet.ai label="  AI: off" >/dev/null 2>&1
    fi
    ;;
  npc)
    npc=$(echo "$state" | jq -r '.npc')
    [ "$npc" = "null" ] && exit 0
    claimed=$(echo "$state" | jq -r '.npc.claimed')
    if [ "$claimed" = "true" ]; then exit 0; fi
    species=$(echo "$state" | jq -r '.npc.species')
    effect=$(npc_effect "$species")
    stat="${effect%%:*}"; delta="${effect##*:}"
    state=$(echo "$state" | jq \
      --arg s "$stat" --argjson d "$delta" '
        def clamp: if . < 0 then 0 elif . > 100 then 100 else . end;
        .[$s] = ((.[$s] + $d) | clamp) |
        .npc.claimed = true |
        .npc.despawn_at = (now | floor) + 30
      ')
    flavor="$(echo "$state" | jq -r '.npc.flavor')"
    if [ "$delta" -ge 0 ]; then
      ( "${SCRIPT_DIR}/pet_animate.sh" content >/dev/null 2>&1 & )
      ( "${SCRIPT_DIR}/pet_speak.sh" "you and the ${species} share a moment." >/dev/null 2>&1 & )
    else
      ( "${SCRIPT_DIR}/pet_animate.sh" cleanliness >/dev/null 2>&1 & )
      ( "${SCRIPT_DIR}/pet_speak.sh" "the ${species} took something from you." >/dev/null 2>&1 & )
    fi
    state=$(echo "$state" | jq --argjson t "$t" '.last_spoke = $t')
    ;;
  *)
    exit 0
    ;;
esac

write_state "$state"
sketchybar --trigger pet_action >/dev/null 2>&1
