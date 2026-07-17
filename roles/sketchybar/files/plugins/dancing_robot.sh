#!/bin/bash

sketchybar --animate sin 12 --set "$NAME" icon.y_offset=3 >/dev/null 2>&1
sleep 0.18
sketchybar --animate sin 12 --set "$NAME" icon.y_offset=0 >/dev/null 2>&1
