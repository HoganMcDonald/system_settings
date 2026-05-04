#!/bin/bash
# Lazy-init of the pet popup menu. Mirrors apple_popup.sh.

ROW_FONT="Hack Nerd Font:Bold:12.00"
ROW_WIDTH=240
ACTION="${HOME}/.config/sketchybar/plugins/pet_action.sh"
# Close the popup first so it disappears instantly, then run the action
# in the background. Sketchybar serializes click_scripts, so anything
# blocking here makes the click feel laggy.
CLOSE='sketchybar --set pet popup.drawing=off'

sketchybar \
  --add item pet.feed popup.pet \
  --set pet.feed icon="🍖" \
                 label="  Feed" \
                 label.font="$ROW_FONT" \
                 icon.font="$ROW_FONT" \
                 padding_left=12 \
                 padding_right=12 \
                 width=$ROW_WIDTH \
                 click_script="$CLOSE; $ACTION feed &" \
  --add item pet.play popup.pet \
  --set pet.play icon="🎈" \
                 label="  Play" \
                 label.font="$ROW_FONT" \
                 icon.font="$ROW_FONT" \
                 padding_left=12 \
                 padding_right=12 \
                 width=$ROW_WIDTH \
                 click_script="$CLOSE; $ACTION play &" \
  --add item pet.clean popup.pet \
  --set pet.clean icon="🧼" \
                  label="  Clean" \
                  label.font="$ROW_FONT" \
                  icon.font="$ROW_FONT" \
                  padding_left=12 \
                  padding_right=12 \
                  width=$ROW_WIDTH \
                  click_script="$CLOSE; $ACTION clean &" \
  --add item pet.coffee popup.pet \
  --set pet.coffee icon="☕" \
                   label="  Coffee" \
                   label.font="$ROW_FONT" \
                   icon.font="$ROW_FONT" \
                   padding_left=12 \
                   padding_right=12 \
                   width=$ROW_WIDTH \
                   click_script="$CLOSE; $ACTION coffee &" \
  --add item pet.pet popup.pet \
  --set pet.pet icon="💖" \
                label="  Pet" \
                label.font="$ROW_FONT" \
                icon.font="$ROW_FONT" \
                padding_left=12 \
                padding_right=12 \
                width=$ROW_WIDTH \
                click_script="$CLOSE; $ACTION pet &" \
  --add item pet.ai popup.pet \
  --set pet.ai icon="🤖" \
               label="  AI: on" \
               label.font="$ROW_FONT" \
               icon.font="$ROW_FONT" \
               padding_left=12 \
               padding_right=12 \
               width=$ROW_WIDTH \
               click_script="$ACTION toggle-ai" \
  --add item pet.status popup.pet \
  --set pet.status icon="👁" \
                   label="  ░░░░░ ░░░░░ ░░░░░ ░░░░░" \
                   label.font="$ROW_FONT" \
                   icon.font="$ROW_FONT" \
                   padding_left=12 \
                   padding_right=12 \
                   width=$ROW_WIDTH \
  --add item pet.bury popup.pet \
  --set pet.bury icon="🪦" \
                 label="  Bury" \
                 label.font="$ROW_FONT" \
                 icon.font="$ROW_FONT" \
                 padding_left=12 \
                 padding_right=12 \
                 width=$ROW_WIDTH \
                 drawing=off \
                 click_script="$CLOSE; $ACTION bury &"
