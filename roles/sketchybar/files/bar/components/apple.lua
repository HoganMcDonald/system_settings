local colors = require 'colors'

---@type ComponentSpec
return {
  name = 'apple',
  props = {
    icon = {
      string = '\u{F8FF}',
      color = colors.magenta,
      font = { family = 'SF Pro Display:Bold', size = 17 },
      width = 28,
      padding_left = 8,
    },
    label = { drawing = false },
    padding_left = 4,
    padding_right = 4,
    background = {
      color = colors.with_alpha(colors.magenta, 0x30),
      border_color = colors.magenta,
      height = 28,
    },
  },
  popup = {
    background = {
      color = colors.panel_bg,
      corner_radius = 4,
      border_width = 1,
      border_color = colors.magenta,
    },
    items = {
      {
        name = 'about',
        props = {
          icon = { string = '\u{F01C4}', font = { family = 'Hack Nerd Font:Bold', size = 12 } },
          label = { string = ' About This Mac', font = { family = 'Hack Nerd Font:Bold', size = 12 } },
          padding_left = 12,
          padding_right = 12,
          width = 150,
          background = { drawing = false },
        },
        on_click = 'open -a "System Information"; sketchybar --set apple popup.drawing=off',
      },
      {
        name = 'prefs',
        props = {
          icon = { string = '', font = { family = 'Hack Nerd Font:Bold', size = 12 } },
          label = { string = ' System Preferences', font = { family = 'Hack Nerd Font:Bold', size = 12 } },
          padding_left = 12,
          padding_right = 12,
          width = 150,
          background = { drawing = false },
        },
        on_click = 'open -a "System Preferences"; sketchybar --set apple popup.drawing=off',
      },
    },
  },
}
