#!/bin/bash

set -euo pipefail

LOCATION="${WEATHER_LOCATION:-}"
LOCATION_ESCAPED="${LOCATION// /+}"
URL="https://wttr.in/${LOCATION_ESCAPED}?format=%t%7C%C&u"

WEATHER=$(curl --fail --silent --show-error --max-time 5 "$URL" 2>/dev/null || true)

if [ -z "$WEATHER" ] || [ "$WEATHER" = "Unknown location" ]; then
  sketchybar --set "$NAME" icon="󰖐" label="Weather unavailable"
  exit 0
fi

IFS='|' read -r TEMPERATURE CONDITION <<< "$WEATHER"
CONDITION=${CONDITION:-Unknown}
CONDITION_LOWER=$(printf '%s' "$CONDITION" | tr '[:upper:]' '[:lower:]')

case "$CONDITION_LOWER" in
  *thunder*|*storm*) ICON="󰖓" ;;
  *snow*|*sleet*|*blizzard*) ICON="󰖘" ;;
  *rain*|*drizzle*|*shower*) ICON="󰖗" ;;
  *fog*|*mist*|*haze*) ICON="󰖑" ;;
  *cloud*|*overcast*) ICON="󰖐" ;;
  *clear*|*sunny*) ICON="󰖙" ;;
  *) ICON="󰖕" ;;
esac

sketchybar --set "$NAME" \
  icon="$ICON" \
  label="$TEMPERATURE • $CONDITION"
