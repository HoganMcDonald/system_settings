local M = {}

---Initializes the sketchybar items
---@param sbar SketchyBar
M.setup = function(sbar)
  require("items.left_bar").setup(sbar)
  require("items.center_bar").setup(sbar)
  require("items.right_bar").setup(sbar)
end

return M
