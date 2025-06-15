local Bracket = require("items.bracket")
local settings = require("settings")
local colors = require("colors")

local M = {}

---@param sbar SketchyBar
M.setup = function(sbar)
  -- Volume widget already creates its own bracket, so this is a no-op
  -- The volume.bracket is created directly in the volume widget
end

return M