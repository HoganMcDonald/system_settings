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
LABEL="Main"
COLOR="0xff89b4fa"
BAR_COLOR="0x0"  # Default sketchybar background

case "$MODE" in
    "move")
        COLOR="0xffa6e3a1"
        BAR_COLOR="0x44a6e3a1"  # Semi-transparent green
        LABEL="Move"
        ;;
    "resize")
        COLOR="0xfff9e2af"
        BAR_COLOR="0x44f9e2af"  # Semi-transparent yellow
        LABEL="Resize"
        ;;
    "join")
        COLOR="0xfff38ba8"
        BAR_COLOR="0x44f38ba8"  # Semi-transparent red
        LABEL="Join"
        ;;
    "workspace")
        COLOR="0xffcba6f7"
        BAR_COLOR="0x44cba6f7"  # Semi-transparent purple
        LABEL="Workspace"
        ;;
    *)
        COLOR="0xff89b4fa"
        BAR_COLOR="0x44000000"  # Default sketchybar background (transparent with blur)
        LABEL="Main"
        MODE="main"
        ;;
esac

# Update the mode indicator item
sketchybar --set mode_indicator \
           label="$LABEL"

# Update the bar background color
sketchybar --bar color="$BAR_COLOR"