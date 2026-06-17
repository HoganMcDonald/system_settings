local colors = require('colors')

---@type ComponentSpec
return {
  name = 'pet',
  script = { path = 'pet_tick.sh', every = 60 },
  on_click = 'pet_click.sh',
  subscribe = { 'system_woke' },
  animate = {
    flash = {
      duration = 0.25,
      curve = 'ease_out',
      to = { icon = { color = colors.yellow } },
    },
    settle = {
      duration = 0.6,
      curve = 'ease_in_out',
      to = { icon = { color = colors.text } },
    },
  },
  on = {
    pet_action = function(_, _, anim)
      anim('flash')
      anim('settle')
    end,
  },
  props = {
    icon = {
      string = '🥚',
      color = colors.text,
      font = { family = 'Apple Color Emoji', size = 16 },
    },
    label = {
      color = colors.text,
      font = { family = 'Apple Color Emoji', size = 12 },
    },
    padding_left = 5,
    padding_right = 5,
    popup = {
      drawing = false,
      background = {
        color = colors.panel_bg,
        corner_radius = 4,
        border_width = 1,
        border_color = colors.purple,
      },
    },
  },
}
