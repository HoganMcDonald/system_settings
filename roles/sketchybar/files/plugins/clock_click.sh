#!/bin/bash

# Clock click handler script
# Toggles between local time and UTC time

# Check current state file
STATE_FILE="/tmp/sketchybar_clock_utc"

if [ -f "$STATE_FILE" ]; then
  # Currently showing UTC, switch to local
  rm "$STATE_FILE"
  TIME=$(date "+%a %b %-d   %-I:%M %p")
else
  # Currently showing local, switch to UTC
  touch "$STATE_FILE"
  TIME=$(TZ=UTC date "+%a %b %-d   %-I:%M %p UTC")
fi

sketchybar --set "$NAME" label="$TIME"