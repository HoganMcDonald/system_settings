local colors = require 'colors'

local alert_bg = colors.with_alpha(colors.critical, 0x38)
local alert_bg_hot = colors.with_alpha(colors.critical, 0x48)

---@type GroupSpec
return {
  group = {
    name = 'swap_warning',
    props = { background = { drawing = false } },
  },
  items = {
    {
      name = 'swap_alert',
      script = { path = 'swap_warning.sh', every = 10 },
      on_click = 'open -a "Activity Monitor"',
      props = {
        drawing = false,
        icon = { string = '!!', color = colors.critical, padding_left = 9, padding_right = 5 },
        label = { string = 'SWAP', color = colors.critical, padding_right = 9 },
        background = {
          color = alert_bg_hot,
          border_color = colors.critical,
          border_width = 1,
          height = 28,
          corner_radius = 3,
        },
        padding_left = 4,
        padding_right = 4,
      },
    },
    {
      name = 'swap_detail',
      on_click = 'open -a "Activity Monitor"',
      props = {
        drawing = false,
        icon = { string = 'MEM', color = colors.critical, padding_left = 9, padding_right = 6 },
        label = { string = 'FAULT 0M', color = colors.text, padding_right = 10 },
        background = {
          color = alert_bg,
          border_color = colors.critical,
          border_width = 1,
          height = 28,
          corner_radius = 3,
        },
        padding_left = 4,
        padding_right = 4,
      },
    },
  },
}
