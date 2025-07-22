#!/bin/bash

# Apple click handler script
# Toggles the popup when the apple icon is clicked

# Ensure popup items exist before toggling
if ! sketchybar --query apple.about >/dev/null 2>&1; then
  ~/.config/sketchybar/plugins/apple_popup.sh
fi

sketchybar --set apple popup.drawing=toggle