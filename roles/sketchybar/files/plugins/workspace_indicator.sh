#!/bin/bash

# Workspace indicator script
# Updates the workspace ovals based on current AeroSpace workspace

AEROSPACE="/opt/homebrew/bin/aerospace"

# Get current workspace from command line arg, environment variable, or aerospace command
if [ -n "$1" ]; then
    CURRENT_WORKSPACE="$1"
elif [ -n "$AEROSPACE_FOCUSED_WORKSPACE" ]; then
    CURRENT_WORKSPACE="$AEROSPACE_FOCUSED_WORKSPACE"
elif [ -n "$FOCUSED_WORKSPACE" ]; then
    CURRENT_WORKSPACE="$FOCUSED_WORKSPACE"
else
    # Fallback to aerospace command
    CURRENT_WORKSPACE=$("$AEROSPACE" list-workspaces --focused 2>/dev/null)
fi

# Avoid showing a stale active workspace if the event did not provide one and
# the AeroSpace CLI is unavailable.
if [ -z "$CURRENT_WORKSPACE" ]; then
  exit 0
fi

for i in {1..4}; do
  if [ "$i" = "$CURRENT_WORKSPACE" ]; then
    sketchybar --set workspace_$i icon.color=0xff00f5ff \
               background.color=0x2d00f5ff \
               background.border_color=0xff00f5ff
  else
    sketchybar --set workspace_$i icon.color=0xff9bb6c5 \
               background.color=0xd4111f2a \
               background.border_color=0xff35505d
  fi
done
