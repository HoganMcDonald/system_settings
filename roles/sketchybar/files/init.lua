local M = {}

---@class SketchyBar
---@field begin_config fun()
---@field end_config fun()
---@field animate fun(animation: string, duration: number, callback: fun())
---@field event_loop fun()
---@field default fun(config: table)
---@field bar fun(config: table)
---@field add fun(type: string, name?: string, ...): any
---@field exec fun(command: string, ...): any

local logger = require("helpers.logger")
logger.set_level(logger.LEVELS.DEBUG)

---@type SketchyBar
M.sbar = require("sketchybar")

M.setup = function()
  M.sbar.begin_config()

  require("default").load(M.sbar)
  M.sbar.animate("tanh", 25, function()
    require("items").setup(M.sbar)

    require("bar"):new(
      M.sbar,
      {
        start_pos = -50,
        overshoot = 15,
        final_pos = 5,
        height = 35,
      }
    )
  end)
  M.sbar.end_config()

  M.sbar.event_loop()
end

M.setup()

return M
