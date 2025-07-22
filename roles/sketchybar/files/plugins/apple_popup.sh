#!/bin/bash

# Apple popup menu creation script
# This script gets called during bar initialization

# Create popup items with wider width and font size 12
sketchybar --add item apple.about popup.apple \
           --set apple.about icon="󰇄" \
                             label=" About This Mac" \
                             label.font="Hack Nerd Font:Bold:12.00" \
                             icon.font="Hack Nerd Font:Bold:12.00" \
                             padding_left=12 \
                             padding_right=12 \
                             width=150 \
                             click_script="open -a 'System Information'; sketchybar --set apple popup.drawing=off" \
           --add item apple.prefs popup.apple \
           --set apple.prefs icon="" \
                             label=" System Preferences" \
                             label.font="Hack Nerd Font:Bold:12.00" \
                             icon.font="Hack Nerd Font:Bold:12.00" \
                             padding_left=12 \
                             padding_right=12 \
                             width=150 \
                             click_script="open -a 'System Preferences'; sketchybar --set apple popup.drawing=off" \
           --add item apple.activity popup.apple \
           --set apple.activity icon="" \
                                label=" Activity Monitor" \
                                label.font="Hack Nerd Font:Bold:12.00" \
                                icon.font="Hack Nerd Font:Bold:12.00" \
                                padding_left=12 \
                                padding_right=12 \
                                width=150 \
                                click_script="open -a 'Activity Monitor'; sketchybar --set apple popup.drawing=off" \
           --add item apple.lock popup.apple \
           --set apple.lock icon="󰌾" \
                            label=" Lock Screen" \
                            label.font="Hack Nerd Font:Bold:12.00" \
                            icon.font="Hack Nerd Font:Bold:12.00" \
                            padding_left=12 \
                            padding_right=12 \
                            width=150 \
                            click_script="pmset displaysleepnow; sketchybar --set apple popup.drawing=off"
