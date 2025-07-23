#!/bin/bash

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
  # Get signal strength using airport utility or iwconfig alternative
  # Try to get RSSI (signal strength in dBm)
  SIGNAL_STRENGTH=$(system_profiler SPAirPortDataType | grep -A1 "Current Network Information:" | grep "Signal / Noise" | awk '{print $3}' | sed 's/dBm//')

  # If that doesn't work, try alternative method
  if [ -z "$SIGNAL_STRENGTH" ]; then
    # Use iwconfig-like approach via networksetup
    SIGNAL_STRENGTH=$(networksetup -getinfo "Wi-Fi" 2>/dev/null | grep -i signal | awk '{print $2}' | sed 's/%//')
  fi

  # If still no signal strength, try another method
  if [ -z "$SIGNAL_STRENGTH" ]; then
    # Get from system profiler with different parsing
    SIGNAL_STRENGTH=$(system_profiler SPAirPortDataType | awk '/Signal \/ Noise/{print $4}' | head -1)
  fi

  # Set icon and color based on signal strength
  # RSSI values: -30 to -50 dBm = Excellent, -50 to -60 = Good, -60 to -70 = Fair, -70+ = Weak
  if [ -n "$SIGNAL_STRENGTH" ] && [ "$SIGNAL_STRENGTH" -lt 0 ]; then
    # Convert negative dBm to positive for comparison
    ABS_SIGNAL=$((0 - SIGNAL_STRENGTH))

    if [ "$ABS_SIGNAL" -le 50 ]; then
      # Excellent signal (-30 to -50 dBm)
      ICON="󰤨"
      ICON_COLOR=0xff58d1fc
    elif [ "$ABS_SIGNAL" -le 60 ]; then
      # Good signal (-50 to -60 dBm)
      ICON="󰤥"
      ICON_COLOR=0xff58d1fc
    elif [ "$ABS_SIGNAL" -le 70 ]; then
      # Fair signal (-60 to -70 dBm)
      ICON="󰤢"
      ICON_COLOR=0xfff9e2af
    else
      # Weak signal (-70+ dBm)
      ICON="󰤟"
      ICON_COLOR=0xfff38ba8
    fi
  else
    # Default to good signal if we can't determine strength
    ICON="󰤨"
    ICON_COLOR=0xff58d1fc
  fi

  # Set the icon and remove label for clean look
  sketchybar --set wifi \
    icon="$ICON" icon.color="$ICON_COLOR" \
    label=""
fi
