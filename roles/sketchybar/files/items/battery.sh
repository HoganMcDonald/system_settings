#!/usr/bin/env sh

sketchybar --add item     battery right                     \
           --set battery  update_freq=3                     \
           --set battery  script="$PLUGIN_DIR/power.sh"     \
                          background.padding_left=15        \
           --set battery  icon=
