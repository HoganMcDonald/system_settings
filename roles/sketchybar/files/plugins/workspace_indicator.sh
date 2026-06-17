#!/bin/bash

# Workspace indicator script
# Updates the workspace ovals based on current AeroSpace workspace

# Get current workspace from command line arg, environment variable, or aerospace command
if [ -n "$1" ]; then
    CURRENT_WORKSPACE="$1"
elif [ -n "$AEROSPACE_FOCUSED_WORKSPACE" ]; then
    CURRENT_WORKSPACE="$AEROSPACE_FOCUSED_WORKSPACE"
else
    # Fallback to aerospace command
    CURRENT_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)
fi

# If still no workspace, default to 1
if [ -z "$CURRENT_WORKSPACE" ]; then
  CURRENT_WORKSPACE="1"
fi

# Update all workspace indicators
for i in {1..4}; do
  if [ "$i" = "$CURRENT_WORKSPACE" ]; then
    # Active workspace - make it twice as wide with faster animation
    sketchybar --animate tanh 8 \
               --set workspace_$i width=34 \
               background.color=0xff00f5ff \
               background.border_color=0xffe8fbff
  else
    # Inactive workspace - normal width with faster animation
    sketchybar --animate tanh 8 \
               --set workspace_$i width=9 \
               background.color=0xff233743 \
               background.border_color=0xff35505d
  fi
done
