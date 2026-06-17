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
BAR_COLOR="0x00000000"

case "$MODE" in
    "move")
        COLOR="0xff35ff8a"
        BAR_COLOR="0xd40a1d15"
        LABEL="[ MOVE ]"
        ;;
    "resize")
        COLOR="0xffffd15c"
        BAR_COLOR="0xd41d1708"
        LABEL="[ RESIZE ]"
        ;;
    "join")
        COLOR="0xffff3f66"
        BAR_COLOR="0xd4200812"
        LABEL="[ JOIN ]"
        ;;
    "workspace")
        COLOR="0xffff2bd6"
        BAR_COLOR="0xd41d061c"
        LABEL="[ WORKSPACE ]"
        ;;
    *)
        COLOR="0xff00f5ff"
        BAR_COLOR="0x00000000"
        LABEL="[ MAIN ]"
        MODE="main"
        ;;
esac

# Update the mode indicator item
sketchybar --set mode_indicator \
           label="$LABEL" \
           label.color="$COLOR"

# Update the bar background color
sketchybar --bar color="$BAR_COLOR"
