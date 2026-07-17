local colors = require 'colors'

---@type ComponentSpec
return {
  name = 'dancing_robot',
  script = { path = 'dancing_robot.sh', every = 1 },
  props = {
    icon = {
      string = '🤖',
      font = { family = 'Apple Color Emoji', size = 15 },
      padding_left = 8,
      padding_right = 8,
    },
    label = {
      drawing = false,
    },
    background = {
      color = colors.with_alpha(colors.teal, 0x20),
      border_color = colors.with_alpha(colors.teal, 0x99),
      height = 28,
    },
    padding_left = 2,
    padding_right = 4,
  },
}
