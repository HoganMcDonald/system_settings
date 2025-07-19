#!/usr/bin/env bash

echo \$FOCUSED_WORKSPACE: $FOCUSED_WORKSPACE, \$NAME: $NAME \$1: $1 >> ~/aaaa

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME background.drawing=on
else
    sketchybar --set $NAME background.drawing=off
fi

# Commented out sections include additional logic for handling window and workspace changes