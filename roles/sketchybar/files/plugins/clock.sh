#!/bin/bash

# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

# Check if we should show UTC time
STATE_FILE="/tmp/sketchybar_clock_utc"

if [ -f "$STATE_FILE" ]; then
  # Show UTC time
  TIME=$(TZ=UTC date "+%a %b %-d   %-I:%M %p UTC")
else
  # Show local time
  TIME=$(date "+%a %b %-d   %-I:%M %p")
fi

sketchybar --set "$NAME" label="$TIME"
