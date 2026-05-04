#!/bin/bash
# Subtle shake / bounce patterns for the pet. Animates y_offset only so
# wandering (padding_left) can run independently.
#
# Usage: pet_animate.sh <pattern>
# Patterns: hunger, happiness, energy, cleanliness, content, death

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=pet_lib.sh
source "${SCRIPT_DIR}/pet_lib.sh"

pattern="${1:-content}"

# Single-flight: skip if another animation is already running.
if [ -e "$ANIM_LOCK" ]; then
  # Stale lock recovery: if older than 5s, take it.
  age=$(( $(now) - $(stat -f %m "$ANIM_LOCK" 2>/dev/null || echo 0) ))
  [ "$age" -lt 5 ] && exit 0
fi
echo $$ > "$ANIM_LOCK"
trap 'rm -f "$ANIM_LOCK"' EXIT

set_y() {
  sketchybar --animate sin "$2" --set pet y_offset="$1" >/dev/null 2>&1
}

set_size() {
  sketchybar --set pet icon.font="Apple Color Emoji:Regular:${1}" >/dev/null 2>&1
}

set_color() {
  sketchybar --animate sin "$2" --set pet icon.color="$1" >/dev/null 2>&1
}

case "$pattern" in
  hunger)
    # Rapid horizontal-feeling jitter via vertical micro-shakes.
    for _ in 1 2 3; do
      set_y -2 6; sleep 0.10
      set_y  2 6; sleep 0.10
    done
    set_y 0 8
    ;;
  happiness)
    # Bored wiggle: slow up/down, half-hearted.
    set_y  1 30; sleep 0.55
    set_y -1 30; sleep 0.55
    set_y  0 20
    ;;
  energy)
    # Sleepy droop: slow sag, pause, recover.
    set_y -3 60; sleep 1.2
    set_y -3 30; sleep 0.8
    set_y  0 40
    ;;
  cleanliness)
    # Shiver: rapid small vertical jitter.
    for _ in 1 2 3 4 5; do
      set_y -1 4; sleep 0.06
      set_y  1 4; sleep 0.06
    done
    set_y 0 6
    ;;
  content)
    # Loud, celebratory: grow, big bounce + overshoot, color flash, settle.
    set_size 24; set_color "$PET_COLOR_PINK" 6
    set_y  10 8;  sleep 0.18
    set_size 26
    set_y  -4 14; sleep 0.30
    set_color "$PET_COLOR_TEAL" 6
    set_y   8 8;  sleep 0.16
    set_y  -2 8;  sleep 0.14
    set_color "$PET_COLOR_GREEN" 6
    set_y   4 6;  sleep 0.10
    set_size 16
    set_y   0 10
    sleep 0.05
    # Reset color so next render picks back up the mood-based color.
    sketchybar --trigger pet_action >/dev/null 2>&1
    ;;
  death)
    # One last sigh.
    set_y -4 90; sleep 1.5
    set_y  0 60
    ;;
  *)
    set_y 0 10
    ;;
esac
