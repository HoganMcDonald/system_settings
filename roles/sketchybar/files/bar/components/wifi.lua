local colors = require('colors')

---@type ComponentSpec
return {
  name = 'wifi',
  script = { path = 'wifi.sh', every = 30 },
  on_click = 'open -b com.apple.SystemPreferences /System/Library/PreferencePanes/Network.prefPane',
  props = {
    label = { color = colors.text },
    icon = { color = colors.cyan, padding_left = 9, padding_right = 9 },
    background = {
      color = colors.with_alpha(colors.cyan, 0x24),
      border_color = colors.with_alpha(colors.cyan, 0x99),
      height = 28,
    },
    padding_left = 4,
    padding_right = 4,
  },
}
