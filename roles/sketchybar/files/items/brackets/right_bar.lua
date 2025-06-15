local Bracket = require("items.bracket")
local settings = require("settings")
local colors = require("colors")

local M = {}

---@param sbar SketchyBar
M.setup = function(sbar)
  -- Check if we're using bar-full.lua
  local is_bar_full = os.getenv("BAR_CONFIG") == "bar-full"
  
  Bracket:new(
    sbar,
    "right_bar.bracket",
    { "clock.bracket", "volume.bracket", "systray.bracket" },
    {
      shadow = not is_bar_full,
      width = "dynamic",
      padding_left = 10,
      padding_right = 10,
      background = {
        padding_left = settings.group_paddings,
        padding_right = settings.group_paddings,
        color = colors.bar.bg2,
      },
    }
  ):render()
end

return M