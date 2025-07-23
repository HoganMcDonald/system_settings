local Bracket = require('lib').Bracket
local Item = require('lib').Item

local function battery()
  local battery_widget = Item:new('item', 'battery', 'right')
  battery_widget
    :label_color(0xffffffff)
    :label_font('SF Pro Display', 14)
    :icon_color(0xffa6e3a1)
    :icon_font('SF Pro Display', 16)
    :padding(5, 5)
    :script('~/.config/sketchybar/plugins/battery.sh', 120)
    :subscribe('power_source_change', 'system_woke')
    :set({
      click_script = "~/.config/sketchybar/plugins/battery_click.sh"
    })

  local battery_container = Bracket:new('battery', { 'battery' })
  battery_container:move_to('right')

  return {
    battery_widget,
    battery_container
  }
end

return battery
