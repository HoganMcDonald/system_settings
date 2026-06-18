#!/bin/bash

VM_STAT=$(vm_stat 2>/dev/null)
PAGE_SIZE=$(printf '%s\n' "$VM_STAT" | awk '/page size of/ { gsub(/[^0-9]/, "", $8); print $8 }')
TOTAL_BYTES=$(sysctl -n hw.memsize 2>/dev/null)

if [ -z "$PAGE_SIZE" ] || [ -z "$TOTAL_BYTES" ]; then
  sketchybar --set ram_usage label="--%"
  exit 0
fi

USED_PAGES=$(printf '%s\n' "$VM_STAT" | awk '
  /Pages active/ { gsub(/\./, "", $3); active=$3 }
  /Pages wired down/ { gsub(/\./, "", $4); wired=$4 }
  /Pages occupied by compressor/ { gsub(/\./, "", $5); compressor=$5 }
  END { print active + wired + compressor }
')

PERCENT=$(awk -v pages="$USED_PAGES" -v page_size="$PAGE_SIZE" -v total="$TOTAL_BYTES" 'BEGIN {
  if (total <= 0) print 0
  else printf "%.0f", (pages * page_size / total) * 100
}')

COLOR="0xff9b5cff"
BG="0x249b5cff"
BORDER="0x999b5cff"

if [ "$PERCENT" -ge 85 ]; then
  COLOR="0xffff3f66"
  BG="0x38ff3f66"
  BORDER="0xffff3f66"
elif [ "$PERCENT" -ge 70 ]; then
  COLOR="0xffff8a3d"
  BG="0x30ff8a3d"
  BORDER="0xffff8a3d"
fi

sketchybar --set ram_usage \
  icon.color="$COLOR" \
  label="$PERCENT%" \
  background.color="$BG" \
  background.border_color="$BORDER"
