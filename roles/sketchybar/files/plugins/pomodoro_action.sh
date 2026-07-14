#!/bin/bash

STATE_FILE="/tmp/sketchybar_pomodoro_end"
DONE_FILE="/tmp/sketchybar_pomodoro_done"
ACTION="$1"

if [ "$ACTION" = "stop" ]; then
  rm -f "$STATE_FILE" "$DONE_FILE"
  sketchybar --set pomodoro popup.drawing=off label="Ready"
  NAME=pomodoro ~/.config/sketchybar/plugins/pomodoro.sh
  exit 0
fi

case "$ACTION" in
  ''|*[!0-9]*)
    exit 1
    ;;
esac

END_TIME=$(($(date +%s) + ACTION * 60))
printf '%s\n' "$END_TIME" > "$STATE_FILE"
rm -f "$DONE_FILE"

sketchybar --set pomodoro popup.drawing=off
NAME=pomodoro ~/.config/sketchybar/plugins/pomodoro.sh
