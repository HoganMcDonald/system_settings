local Bracket = require('lib').Bracket
local Item = require('lib').Item
local colors = require('colors')
--  󰱯    

local function apple()
  -- Create the main apple item
  local apple_widget = Item:new('item', 'apple', 'left')
  apple_widget
    :icon_string("")
    :icon_color(colors.green)
    :icon_font('Hack Nerd Font', 16)
    :padding(0, 5)
    :set({
      label = { drawing = false },
      popup = {
        drawing = false,
        background = {
          color = colors.base,
          corner_radius = 8,
          border_width = 1,
          border_color = colors.lavender
        }
      },
      click_script = "~/.config/sketchybar/plugins/apple_click.sh",
    })

  -- Popup items are created on-demand by apple_click.sh

  local apple_container = Bracket:new('apple', { 'apple' })
  apple_container:move_to('left')

  return {
    apple_widget,
    apple_container
  }
end

return apple
