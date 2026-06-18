#!/bin/bash

if ! command -v macmon >/dev/null 2>&1; then
  sketchybar --set cpu_temp label="--C"
  exit 0
fi

METRICS=$(macmon pipe --samples 1 --interval 1000 2>/dev/null)
TEMP=$(printf '%s\n' "$METRICS" | sed -n 's/.*"cpu_temp_avg":\([0-9.][0-9.]*\).*/\1/p')

if [ -z "$TEMP" ] || ! awk -v temp="$TEMP" 'BEGIN { exit !(temp > 0) }'; then
  sketchybar --set cpu_temp label="--C"
  exit 0
fi

TEMP_ROUNDED=$(awk -v temp="$TEMP" 'BEGIN { printf "%.0f", temp }')

COLOR="0xff47a7ff"
BG="0x2447a7ff"
BORDER="0x9947a7ff"

if awk -v temp="$TEMP" 'BEGIN { exit !(temp >= 85) }'; then
  COLOR="0xffff3f66"
  BG="0x38ff3f66"
  BORDER="0xffff3f66"
elif awk -v temp="$TEMP" 'BEGIN { exit !(temp >= 70) }'; then
  COLOR="0xffff8a3d"
  BG="0x30ff8a3d"
  BORDER="0xffff8a3d"
fi

sketchybar --set cpu_temp \
  icon.color="$COLOR" \
  label="${TEMP_ROUNDED}C" \
  background.color="$BG" \
  background.border_color="$BORDER"
