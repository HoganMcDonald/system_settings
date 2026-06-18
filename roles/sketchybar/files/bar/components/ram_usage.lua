local colors = require 'colors'

---@type ComponentSpec
return {
  name = 'ram_usage',
  script = { path = 'ram_usage.sh', every = 10 },
  on_click = 'open -a "Activity Monitor"',
  props = {
    icon = { string = 'RAM', color = colors.purple, padding_left = 8, padding_right = 6 },
    label = { string = '--%', color = colors.text, padding_right = 9 },
    background = {
      color = colors.with_alpha(colors.purple, 0x60),
      border_color = colors.with_alpha(colors.purple, 0x99),
      height = 28,
    },
    padding_left = 4,
    padding_right = 4,
  },
}
