#!/bin/sh

# Try multiple methods to get WiFi SSID
SSID=$(networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //')

# If that fails, try system_profiler
if [ -z "$SSID" ] || [ "$SSID" = "You are not associated with an AirPort network." ]; then
  SSID=$(system_profiler SPAirPortDataType | awk '/Current Network Information:/{getline; print $1}' | sed 's/://g')
fi

if [ -z "$SSID" ] || [ "$SSID" = "You are not associated with an AirPort network." ]; then
  # No connection - use outline wifi icon
  sketchybar --set "$NAME" \
    icon="󰖪" icon.color=0xff6c7086 \
    label="Not Connected"
else
  # Connected - use filled wifi icon
  sketchybar --set "$NAME" \
    icon="󰖩" icon.color=0xffffffff \
    label=""
fi
