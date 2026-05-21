local colors = require('colors')

---@type GroupSpec
return {
  group = {
    name = 'mode',
    props = {
      background = {
        drawing = true,
        color = colors.surface0,
        corner_radius = 16,
        height = 24,
        padding_left = 8,
        padding_right = 8,
      },
    },
  },
  items = {
    {
      name = 'mode_indicator',
      script = 'aerospace_mode.sh',
      subscribe = { 'aerospace_mode_change' },
      props = {
        label = { string = 'Main', color = colors.text },
        padding_left = 5,
        padding_right = 5,
      },
    },
  },
}
