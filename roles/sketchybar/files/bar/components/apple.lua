local colors = require('colors')

---@type ComponentSpec
return {
  name = 'apple',
  props = {
    icon = {
      string = '\u{F8FF}',
      color = colors.green,
      font = { family = 'Hack Nerd Font', size = 16 },
    },
    label = { drawing = false },
    padding_left = 0,
    padding_right = 5,
  },
  popup = {
    background = {
      color = colors.base,
      corner_radius = 8,
      border_width = 1,
      border_color = colors.lavender,
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
        },
        on_click = 'open -a "System Preferences"; sketchybar --set apple popup.drawing=off',
      },
    },
  },
}
