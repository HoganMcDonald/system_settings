local colors = require 'colors'

local function timer_option(name, icon, label, minutes)
  return {
    name = name,
    props = {
      icon = { string = icon, color = colors.magenta, font = { family = 'Hack Nerd Font:Bold', size = 12 } },
      label = { string = ' ' .. label, font = { family = 'Hack Nerd Font:Bold', size = 12 } },
      padding_left = 12,
      padding_right = 12,
      width = 145,
      background = { drawing = false, border_width = 0 },
    },
    on_click = 'bash ~/.config/sketchybar/plugins/pomodoro_action.sh ' .. minutes,
  }
end

---@type ComponentSpec
return {
  name = 'pomodoro',
  script = { path = 'pomodoro.sh', every = 1 },
  props = {
    icon = { string = '󰔛', color = colors.purple, padding_left = 8, padding_right = 7 },
    label = { string = 'Ready', color = colors.text, padding_right = 10 },
    background = {
      color = colors.with_alpha(colors.purple, 0x24),
      border_color = colors.with_alpha(colors.purple, 0xaa),
      height = 28,
    },
    padding_left = 4,
    padding_right = 4,
  },
  popup = {
    background = {
      color = colors.panel_bg,
      corner_radius = 4,
      border_width = 1,
      border_color = colors.magenta,
    },
    items = {
      timer_option('focus', '󱎫', 'Focus 25m', 25),
      timer_option('short_break', '󰒲', 'Break 5m', 5),
      timer_option('long_break', '󰤄', 'Long Break 15m', 15),
      {
        name = 'stop',
        props = {
          icon = { string = '󰓛', color = colors.red, font = { family = 'Hack Nerd Font:Bold', size = 12 } },
          label = { string = ' Stop Timer', font = { family = 'Hack Nerd Font:Bold', size = 12 } },
          padding_left = 12,
          padding_right = 12,
          width = 145,
          background = { drawing = false, border_width = 0 },
        },
        on_click = 'bash ~/.config/sketchybar/plugins/pomodoro_action.sh stop',
      },
    },
  },
}
