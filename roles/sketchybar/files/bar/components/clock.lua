local colors = require('colors')

---@type ComponentSpec
return {
  name = 'clock',
  script = { path = 'clock.sh', every = 30 },
  on_click = 'clock_click.sh',
  props = {
    label = { color = colors.amber, padding_right = 10 },
    icon = { string = '󰥔', color = colors.amber, padding_left = 8, padding_right = 7 },
    background = {
      color = colors.with_alpha(colors.amber, 0x26),
      border_color = colors.with_alpha(colors.amber, 0xaa),
      height = 28,
    },
    padding_left = 4,
    padding_right = 4,
  },
}
