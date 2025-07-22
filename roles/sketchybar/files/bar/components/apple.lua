local Bracket = require('lib').Bracket
local Item = require('lib').Item
--  󰱯    

local function apple()
  -- Create the main apple item
  local apple_widget = Item:new('item', 'apple', 'left')
  apple_widget
    :icon_string("")
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

  -- Create popup items using helper script
  os.execute("~/.config/sketchybar/plugins/apple_popup.sh")

  local apple_container = Bracket:new('apple', { 'apple' })
  apple_container:move_to('left')

  return {
    apple_widget,
    apple_container
  }
end

return apple
