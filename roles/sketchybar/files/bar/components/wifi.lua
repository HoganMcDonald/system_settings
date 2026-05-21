local colors = require('colors')

---@type ComponentSpec
return {
  name = 'wifi',
  script = { path = 'wifi.sh', every = 30 },
  on_click = 'open -b com.apple.SystemPreferences /System/Library/PreferencePanes/Network.prefPane',
  props = {
    label = { color = colors.text },
    icon = { color = colors.sky },
    padding_left = 5,
    padding_right = 10,
  },
}
