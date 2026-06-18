local colors = require 'colors'

---@type GroupSpec
return {
  group = {
    name = 'mode',
    props = {
      background = {
        drawing = true,
        color = colors.with_alpha(colors.cyan, 0x1f),
        border_color = colors.cyan,
        border_width = 1,
        corner_radius = 3,
        height = 28,
        padding_left = 12,
        padding_right = 12,
      },
    },
  },
  items = {
    {
      name = 'mode_indicator',
      script = 'aerospace_mode.sh',
      subscribe = { 'aerospace_mode_change' },
      props = {
        label = { string = '[ MAIN ]', color = colors.cyan },
        padding_left = 4,
        padding_right = 4,
        background = {
          drawing = false,
          color = colors.transparent,
          border_width = 0,
        },
      },
    },
  },
}
