#!/bin/sh

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case ${PERCENTAGE} in
  [8-9][0-9] | 100)
    ICON="􀛨"
    ICON_COLOR=0xffa6e3a1
    ;;
  7[0-9])
    ICON="􀺸"
    ICON_COLOR=0xfff9e2af
    ;;
  [4-6][0-9])
    ICON="􀺶"
    ICON_COLOR=0xfffab387
    ;;
  [1-3][0-9])
    ICON="􀛩"
    ICON_COLOR=0xfff38ba8
    ;;
  [0-9])
    ICON="􀛪"
    ICON_COLOR=0xffeba0ac
    ;;
esac

if [[ "$CHARGING" != "" ]]; then
  ICON="􀢋"
  ICON_COLOR=0xffe2f9af
fi

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
sketchybar --set battery icon="$ICON" label="${PERCENTAGE}%" icon.color=${ICON_COLOR} icon.padding_right=5
