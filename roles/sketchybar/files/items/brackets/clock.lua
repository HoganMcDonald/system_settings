local Bracket = require("items.bracket")
local settings = require("settings")
local colors = require("colors")

local M = {}

---@param sbar SketchyBar
M.setup = function(sbar)
  Bracket:new(
    sbar,
    "clock.bracket",
    { "cal" },
    {
      width = "dynamic",
      background = {
        padding_left = settings.group_paddings,
        padding_right = settings.group_paddings,
        color = colors.transparent,
      },
    }
  ):render()
end

return M