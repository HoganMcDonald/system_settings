#!/bin/bash
# Auto-open the popup, show a single speech row, then close after a beat.
#
# Usage: pet_speak.sh "the message"
#   or:  pet_speak.sh --close   (called by the scheduled hide)

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=pet_lib.sh
source "${SCRIPT_DIR}/pet_lib.sh"

ROW_FONT="Hack Nerd Font:Bold:12.00"
ROW_WIDTH=240

ensure_speech_row() {
  if ! sketchybar --query pet.speech >/dev/null 2>&1; then
    sketchybar --add item pet.speech popup.pet \
               --set pet.speech icon="💬" \
                                 label="" \
                                 label.font="$ROW_FONT" \
                                 icon.font="$ROW_FONT" \
                                 padding_left=12 \
                                 padding_right=12 \
                                 width=$ROW_WIDTH \
                                 drawing=off
  fi
}

ensure_popup_mounted() {
  if ! sketchybar --query pet.feed >/dev/null 2>&1; then
    "${SCRIPT_DIR}/pet_popup.sh"
  fi
  ensure_speech_row
}

hide_action_rows() {
  sketchybar \
    --set pet.feed   drawing=off \
    --set pet.play   drawing=off \
    --set pet.clean  drawing=off \
    --set pet.pet    drawing=off \
    --set pet.status drawing=off \
    --set pet.bury   drawing=off
}

restore_action_rows() {
  local alive
  alive=$(read_state | jq -r '.alive')
  sketchybar \
    --set pet.feed   drawing=on \
    --set pet.play   drawing=on \
    --set pet.clean  drawing=on \
    --set pet.pet    drawing=on \
    --set pet.status drawing=on \
    --set pet.speech drawing=off
  if [ "$alive" = "true" ]; then
    sketchybar --set pet.bury drawing=off
  else
    sketchybar --set pet.bury drawing=on
  fi
}

if [ "${1:-}" = "--close" ]; then
  sketchybar --set pet popup.drawing=off
  restore_action_rows
  exit 0
fi

msg="${1:-}"
[ -z "$msg" ] && exit 0

ensure_popup_mounted
hide_action_rows
sketchybar --set pet.speech label="  ${msg}" drawing=on
sketchybar --set pet popup.drawing=on

# Schedule the close. Detach so this script returns immediately.
( sleep 6; "${SCRIPT_DIR}/pet_speak.sh" --close ) >/dev/null 2>&1 &
disown
