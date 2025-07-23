local Bracket = require('lib').Bracket
local Item = require('lib').Item

local function mode_indicator()
  local mode_indicator_widget = Item:new('item', 'mode_indicator', 'left')
  mode_indicator_widget
    :label_string("Main")
    :label_color(0xffffffff)
    :label_font('SF Pro Display', 14)
    :padding(5, 5)
    :script('~/.config/sketchybar/plugins/aerospace_mode.sh', 0)
    :subscribe('aerospace_mode_change')

  local mode_indicator_container = Bracket:new('mode', { 'mode_indicator' })
  mode_indicator_container
    :move_to('left')
    :set({
      background = {
        drawing = true,
        color = 0xff2a2a3a,
        corner_radius = 16,
        height = 24,
        padding_left = 8,
        padding_right = 8
      }
    })

  return {
    mode_indicator_widget,
    mode_indicator_container
  }
end

return mode_indicator
