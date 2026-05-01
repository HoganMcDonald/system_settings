local Bracket = require('lib').Bracket
local Item = require('lib').Item
local colors = require('colors')

local function pet()
  local pet_widget = Item:new('item', 'pet', 'right')
  pet_widget
    :icon_string('🥚')
    :icon_color(colors.text)
    :icon_font('SF Pro Display', 16)
    :label_color(colors.text)
    :label_font('SF Pro Display', 12)
    :padding(5, 5)
    :script('~/.config/sketchybar/plugins/pet_tick.sh', 60)
    :subscribe('pet_action', 'system_woke')
    :set({
      click_script = '~/.config/sketchybar/plugins/pet_click.sh',
      popup = {
        drawing = false,
        background = {
          color = colors.base,
          corner_radius = 8,
          border_width = 1,
          border_color = colors.purple,
        },
      },
    })

  local pet_container = Bracket:new('pet', { 'pet' })
  pet_container:move_to('right')

  return {
    pet_widget,
    pet_container,
  }
end

return pet
