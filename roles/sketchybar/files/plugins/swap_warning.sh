#!/bin/bash

SWAP_USAGE=$(sysctl -n vm.swapusage 2>/dev/null)
USED=$(printf '%s\n' "$SWAP_USAGE" | sed -n 's/.*used = \([0-9.]*[MGT]\).*/\1/p')

if [ -z "$USED" ]; then
  sketchybar --set swap_alert drawing=off --set swap_detail drawing=off
  exit 0
fi

VALUE=${USED%?}
UNIT=${USED: -1}

if ! awk -v value="$VALUE" 'BEGIN { exit !(value > 0) }'; then
  sketchybar --set swap_alert drawing=off --set swap_detail drawing=off
  exit 0
fi

DISPLAY=$(awk -v value="$VALUE" -v unit="$UNIT" 'BEGIN {
  if (unit == "M" && value >= 1024) printf "%.1fG", value / 1024
  else if (unit == "M") printf "%.0fM", value
  else printf "%.1f%s", value, unit
}')

sketchybar --set swap_alert drawing=on \
           --set swap_detail drawing=on label="FAULT $DISPLAY"
