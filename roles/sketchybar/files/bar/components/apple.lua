local Bracket = require('lib').Bracket
local Item = require('lib').Item
--  󰱯    

local function apple()
  -- Create the main apple item
  local apple_widget = Item:new('item', 'apple', 'left')
  apple_widget
    :icon_string("")
    :icon_color(0xffa6e3a1)
    :icon_font('Hack Nerd Font', 16)
    :padding(0, 5)
    :set({
      label = { drawing = false },
      popup = {
        drawing = false,
        background = {
          color = 0xff1e1e2e,
          corner_radius = 8,
          border_width = 1,
          border_color = 0xffffffff
        }
      },
      click_script = "~/.config/sketchybar/plugins/apple_click.sh",
    })

  -- Create popup items directly in Lua
  local apple_prefs = Item:new('item', 'apple.prefs', 'popup.apple')
  apple_prefs
    :icon_string("󰍉")
    :label_string(" Preferences")
    :set({
      click_script = "open -a 'System Preferences'; sketchybar --set apple popup.drawing=off"
    })

  local apple_activity = Item:new('item', 'apple.activity', 'popup.apple')
  apple_activity
    :icon_string("󰻀")
    :label_string(" Activity")
    :set({
      click_script = "open -a 'Activity Monitor'; sketchybar --set apple popup.drawing=off"
    })

  local apple_lock = Item:new('item', 'apple.lock', 'popup.apple')
  apple_lock
    :icon_string("󰌾")
    :label_string(" Lock Screen")
    :set({
      click_script = "pmset displaysleepnow; sketchybar --set apple popup.drawing=off"
    })

  local apple_container = Bracket:new('apple', { 'apple' })
  apple_container:move_to('left')

  return {
    apple_widget,
    apple_prefs,
    apple_activity,
    apple_lock,
    apple_container
  }
end

return apple
