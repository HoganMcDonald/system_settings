#!/bin/bash
# Toggle the pet popup. Lazy-mounts rows on first click.

if ! sketchybar --query pet.feed >/dev/null 2>&1; then
  ~/.config/sketchybar/plugins/pet_popup.sh
  # Force an immediate label refresh so rows aren't blank.
  ~/.config/sketchybar/plugins/pet_tick.sh
fi

sketchybar --set pet popup.drawing=toggle
