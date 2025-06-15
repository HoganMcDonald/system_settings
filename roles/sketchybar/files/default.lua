local settings = require("settings")
local colors = require("colors")

local M = {}

---loads the default configuration for sketchybar
---@param sbar SketchyBar
M.load = function(sbar)
  sbar.default({
    updates       = "when_shown",
    icon          = {
      padding_right = settings.paddings,
      padding_left  = settings.paddings,
      color         = colors.icon.primary,
      font          = {
        family = settings.font.icons,
        style = settings.font.style_map.Bold,
        size = 14
      },
    },
    label         = {
      padding_right = settings.paddings,
      padding_left  = settings.paddings,
      color         = colors.primary,
      font          = {
        family = "fonarto",
        style  = settings.font.style_map.Bold,
        size   = 14.0
      },
    },
    background    = {
      padding_right = settings.paddings,
      padding_left  = settings.paddings,
      height        = 35,
      image         = {
        corner_radius = 8
      },
    },
    padding_left  = settings.paddings,
    padding_right = settings.paddings,
    blur_radius   = 60,
  })
end


return M
