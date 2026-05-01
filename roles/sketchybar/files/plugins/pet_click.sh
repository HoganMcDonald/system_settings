#!/bin/bash
# Toggle the pet popup. Lazy-mounts rows on first click.

if ! sketchybar --query pet.feed >/dev/null 2>&1; then
  ~/.config/sketchybar/plugins/pet_popup.sh
fi

sketchybar --set pet popup.drawing=toggle

# Refresh labels in the background so the popup opens instantly.
~/.config/sketchybar/plugins/pet_tick.sh >/dev/null 2>&1 &
disown
