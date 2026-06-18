local colors = require 'colors'

---@type ComponentSpec
return {
  name = 'degraded_warning',
  props = {
    drawing = false,
    icon = { string = '!!', color = colors.critical, padding_left = 9, padding_right = 6 },
    label = { string = 'DEGRADED - RESTART SYSTEM NOW', color = colors.text, padding_right = 10 },
    background = {
      color = colors.with_alpha(colors.critical, 0x48),
      border_color = colors.critical,
      border_width = 1,
      height = 28,
      corner_radius = 3,
    },
    padding_left = 4,
    padding_right = 4,
  },
}
