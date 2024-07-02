#!/bin/bash

# Replace 'com.apple.Calculator' with your app's bundle identifier
BUNDLE_ID="com.openai.chat"
APP_WINDOW=$(yabai -m query --windows | jq -r ".[] | select(.app == \"${BUNDLE_ID}\") | .id")

if [ -n "$APP_WINDOW" ]; then
    # Toggle the window's floating status and visibility
    yabai -m window $APP_WINDOW --toggle float
    yabai -m window $APP_WINDOW --toggle visible
else
    # Open the app if it's not open
    open -b $BUNDLE_ID
fi
