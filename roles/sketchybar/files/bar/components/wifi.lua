local Bracket = require('lib').Bracket
local Item = require('lib').Item
local colors = require('colors')

local function wifi()
  local wifi_widget = Item:new('item', 'wifi', 'right')
  wifi_widget
    :label_color(colors.text)
    :label_font('SF Pro Display', 14)
    :icon_color(colors.sky)
    :padding(5, 10)
    :script('~/.config/sketchybar/plugins/wifi.sh', 30)
    :set({
      click_script = "open -b com.apple.SystemPreferences /System/Library/PreferencePanes/Network.prefPane"
    })

  local wifi_container = Bracket:new('wifi', { 'wifi' })
  wifi_container:move_to('right')

  return {
    wifi_widget,
    wifi_container
  }
end

return wifi
