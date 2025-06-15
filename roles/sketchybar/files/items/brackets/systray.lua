local Bracket = require("items.bracket")
local settings = require("settings")
local colors = require("colors")

local M = {}

---@param sbar SketchyBar
M.setup = function(sbar)
  Bracket:new(
    sbar,
    "systray.bracket",
    { "search", "widgets.wifi.bracket", "media_icon", "widgets.weather" },
    {
      display = 1,
      width = "dynamic",
      icon = {
        padding_left = 10,
        padding_right = 10,
      },
      background = {
        padding_left = settings.group_paddings,
        padding_right = settings.group_paddings,
        color = colors.transparent,
      },
    }
  ):render()
end

return M
