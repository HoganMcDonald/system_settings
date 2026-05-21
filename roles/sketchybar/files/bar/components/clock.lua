local colors = require('colors')

---@type ComponentSpec
return {
  name = 'clock',
  script = { path = 'clock.sh', every = 30 },
  on_click = 'clock_click.sh',
  props = {
    label = { color = colors.text },
  },
}
