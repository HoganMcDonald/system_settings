local colors = require 'colors'

---@type ComponentSpec
return {
  name = 'cpu_temp',
  script = { path = 'cpu_temp.sh', every = 5 },
  on_click = 'open -a "Activity Monitor"',
  props = {
    icon = { string = 'TEMP', color = colors.blue, padding_left = 8, padding_right = 6 },
    label = { string = '--C', color = colors.text, padding_right = 9 },
    background = {
      color = colors.with_alpha(colors.blue, 0x50),
      border_color = colors.with_alpha(colors.blue, 0x99),
      height = 28,
    },
    padding_left = 4,
    padding_right = 4,
  },
}
