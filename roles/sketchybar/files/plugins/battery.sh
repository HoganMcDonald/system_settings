#!/bin/bash

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case ${PERCENTAGE} in
  [8-9][0-9] | 100)
    ICON="􀛨"
    ICON_COLOR=0xff5eff6b
    ;;
  7[0-9])
    ICON="􀺸"
    ICON_COLOR=0xfff1ff5e
    ;;
  [4-6][0-9])
    ICON="􀺶"
    ICON_COLOR=0xffffbd5e
    ;;
  [1-3][0-9])
    ICON="􀛩"
    ICON_COLOR=0xffff6e5e
    ;;
  [0-9])
    ICON="􀛪"
    ICON_COLOR=0xffff6e5e
    ;;
esac

if [[ "$CHARGING" != "" ]]; then
  ICON="􀢋"
  ICON_COLOR=0xfff1ff5e
fi

# Check if we should show time instead of percentage
STATE_FILE="/tmp/sketchybar_battery_time"

if [ -f "$STATE_FILE" ]; then
  # Show time remaining
  if [[ "$CHARGING" != "" ]]; then
    # When charging, show time until full
    TIME_INFO="$(pmset -g batt | grep -Eo "\d+:\d+ remaining to full charge" | cut -d' ' -f1)"
    if [ "$TIME_INFO" != "" ]; then
      LABEL="$TIME_INFO"
    else
      LABEL="Charging"
    fi
  else
    # When on battery, show time until empty
    TIME_INFO="$(pmset -g batt | grep -Eo "\d+:\d+ remaining" | cut -d' ' -f1)"
    if [ "$TIME_INFO" != "" ]; then
      LABEL="$TIME_INFO"
    else
      LABEL="Calculating..."
    fi
  fi
else
  # Show percentage
  LABEL="${PERCENTAGE}%"
fi

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
sketchybar --set battery icon="$ICON" label="$LABEL" icon.color=${ICON_COLOR} icon.padding_right=5
