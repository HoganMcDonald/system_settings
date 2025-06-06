---@alias IconFont "sf-symbols" | "nerdfont"

---@class Settings.font
---@field text string
---@field numbers string
---@field icons IconFont
---@field style_map table<string, string>

---@class Settings
---@field paddings number
---@field group_paddings number
---@field icons IconFont
---@field animated_icons boolean
---@field font Settings.font
local M = {}

local settings = {
  paddings = 3,
  group_paddings = 10,

  icons = 'sf-symbols', -- Options: "sf-symbols", "nerdfont"
  animated_icons = false, -- Set to true if you want to use animated icons

  font = {
    text = 'Operator Mono Nerd Font', -- Used for text
    numbers = 'Operator Mono Nerd Font', -- Used for numbers
    icons = 'sf-symbols', -- Used for icons (or NerdFont)
    style_map = {
      ['Regular'] = 'Regular',
      ['Semibold'] = 'Medium',
      ['Bold'] = 'semiBold',
      ['Heavy'] = 'Bold',
      ['Black'] = 'ExtraBold',
    },
  },
}

setmetatable(M, {
  __index = function(_, key)
    return settings[key]
  end,
})

return M
