#!/usr/bin/env bash

# AeroSpace Mode Indicator Script
# This script is triggered by aerospace mode changes

# Get the current mode from environment variable, command line arg, or default to main
if [ -n "$1" ]; then
  MODE="$1"
elif [ -n "$MODE" ]; then
  MODE="$MODE"
else
  MODE="main"
fi

# Set icon, color, and bar background based on mode
LABEL="[ MAIN ]"
COLOR="0xff00f5ff"
BG_COLOR="0x1f00f5ff"

case "$MODE" in
"move")
  COLOR="0xff35ff8a"
  BG_COLOR="0x1f35ff8a"
  LABEL="[ MOVE ]"
  ;;
"resize")
  COLOR="0xffffd15c"
  BG_COLOR="0x1fffd15c"
  LABEL="[ RESIZE ]"
  ;;
"join")
  COLOR="0xffff3f66"
  BG_COLOR="0x1fff3f66"
  LABEL="[ JOIN ]"
  ;;
"workspace")
  COLOR="0xffff2bd6"
  BG_COLOR="0x1fff2bd6"
  LABEL="[ WORKSPACE ]"
  ;;
*)
  COLOR="0xff00f5ff"
  BG_COLOR="0x1f00f5ff"
  LABEL="[ MAIN ]"
  MODE="main"
  ;;
esac

# Update the mode indicator item
sketchybar --set mode_indicator \
  background.drawing=on \
  background.color="$BG_COLOR" \
  background.border_color="$COLOR" \
  background.border_width=1 \
  label="$LABEL" \
  label.color="$COLOR"
