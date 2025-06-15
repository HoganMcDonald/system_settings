local colors = require("colors")
local settings = require("settings")

-- Brackets
local center_bar = require('items.brackets.center_bar')

-- Widgets
local spaces = require("items.widgets.spaces")
local add_space = require("items.widgets.add_space")
local mission = require("items.widgets.mission_control")

local M = {}

M.setup = function(sbar)
  -- Setup widgets first (spaces creates its own bracket)
  spaces(sbar)
  add_space(sbar)
  mission(sbar)
  
  -- Setup main center bar bracket
  center_bar.setup(sbar)
end

return M
