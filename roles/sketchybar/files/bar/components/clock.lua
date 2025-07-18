local Bracket = require('lib').Bracket
local Item = require('lib').Item

local function clock()
  local clock_widget = Item:new('item', 'clock', 'right')
  clock_widget
    :label_color(0xffffffff)
    :label_font('SF Pro Display', 14)
    :script('~/.config/sketchybar/plugins/clock.sh', 30)

  local clock_container = Bracket:new('clock', { 'clock' })
  clock_container:move_to('right')

  return {
    clock_widget,
    clock_container
  }
end

return clock
