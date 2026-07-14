#!/bin/bash

STATE_FILE="/tmp/sketchybar_pomodoro_end"
DONE_FILE="/tmp/sketchybar_pomodoro_done"
WARN_SECONDS=300
DONE_SECONDS=60

READY_COLOR="0xff9b5cff"
READY_TEXT="0xffe8fbff"
READY_BG="0x249b5cff"
READY_BORDER="0xaa9b5cff"
WARN_COLOR="0xffff3f66"
WARN_BG="0x40ff3f66"
WARN_BORDER="0xffff3f66"

complete_alarm() {
  (
    for sound in Ping Glass Ping; do
      afplay "/System/Library/Sounds/${sound}.aiff" >/dev/null 2>&1
      sleep 0.12
    done
    say -v Zarvox "Pomodoro complete" >/dev/null 2>&1
  ) &
}

if [ ! -f "$STATE_FILE" ]; then
  NOW=$(date +%s)
  DONE_AT=$(cat "$DONE_FILE" 2>/dev/null)

  if [ -n "$DONE_AT" ] && [ $((NOW - DONE_AT)) -lt "$DONE_SECONDS" ] 2>/dev/null; then
    sketchybar --set "$NAME" \
      icon.color="$WARN_COLOR" \
      label="Done" \
      label.color="$WARN_COLOR" \
      background.color="$WARN_BG" \
      background.border_color="$WARN_BORDER"
    exit 0
  fi

  rm -f "$DONE_FILE"
  sketchybar --set "$NAME" \
    icon.color="$READY_COLOR" \
    label="Ready" \
    label.color="$READY_TEXT" \
    background.color="$READY_BG" \
    background.border_color="$READY_BORDER"
  exit 0
fi

END_TIME=$(cat "$STATE_FILE" 2>/dev/null)
case "$END_TIME" in
  ''|*[!0-9]*)
    rm -f "$STATE_FILE"
    exit 0
    ;;
esac

NOW=$(date +%s)
REMAINING=$((END_TIME - NOW))

if [ "$REMAINING" -le 0 ]; then
  rm -f "$STATE_FILE"
  printf '%s\n' "$NOW" > "$DONE_FILE"
  sketchybar --set "$NAME" \
    icon.color="$WARN_COLOR" \
    label="Done" \
    label.color="$WARN_COLOR" \
    background.color="$WARN_BG" \
    background.border_color="$WARN_BORDER"
  complete_alarm
  exit 0
fi

MINUTES=$((REMAINING / 60))
SECONDS=$((REMAINING % 60))
LABEL=$(printf "%02d:%02d" "$MINUTES" "$SECONDS")

if [ "$REMAINING" -le "$WARN_SECONDS" ]; then
  sketchybar --set "$NAME" \
    icon.color="$WARN_COLOR" \
    label="$LABEL" \
    label.color="$WARN_COLOR" \
    background.color="$WARN_BG" \
    background.border_color="$WARN_BORDER"
else
  sketchybar --set "$NAME" \
    icon.color="$READY_COLOR" \
    label="$LABEL" \
    label.color="$READY_TEXT" \
    background.color="$READY_BG" \
    background.border_color="$READY_BORDER"
fi
