local colors = require("colors")

---@class Bar
---@field start_pos integer
---@field overshoot integer
---@field final_pos integer
---@field height integer
local M = {}

---@param sbar SketchyBar
---@param opts any
---@return Bar
function M:new(sbar, opts)
  opts = opts or {}

  local obj = {
    start_pos = opts.start_pos or -50,
    overshoot = opts.overshoot or 15,
    final_pos = opts.final_pos or 5,
    height = opts.height or 35,
  }
  setmetatable(obj, {__index = self})

  obj:_init(sbar)
  return obj
end

---@param sbar SketchyBar
function M:_init(sbar)
  sbar.bar({
    alpha = 0,
    y_offset = -50, -- Start off-screen
    position = "top",
    height = 35,
    color = colors.transparent,
    margin = 0,
    corner_radius = 8,
    shadow = true,
    blur_radius = 30,
  })

  sbar.animate("sin", 15, function()
    local overshoot = 15 -- Drop below before bouncing up
    local final_pos = 5

    -- Move from start -> overshoot -> final position
    sbar.bar({ y_offset = final_pos + overshoot })

    -- Bounce back up to final position
    sbar.animate("sin", 15, function()
      sbar.bar({ y_offset = final_pos, alpha = 1 })
    end)
  end)
end

return M
