local colors = require 'colors'

---@type ComponentSpec
return {
  name = 'weather',
  script = { path = 'weather.sh', every = 600 },
  on_click = 'open "https://wttr.in/${WEATHER_LOCATION:-}"',
  props = {
    icon = { string = '󰖕', color = colors.yellow, padding_left = 8, padding_right = 7 },
    label = { string = '--', color = colors.text, padding_right = 10 },
    background = {
      color = colors.with_alpha(colors.yellow, 0x36),
      border_color = colors.with_alpha(colors.yellow, 0x99),
      height = 28,
    },
    padding_left = 4,
    padding_right = 4,
  },
}
