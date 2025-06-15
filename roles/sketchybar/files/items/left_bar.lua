local colors = require("colors")

-- Brackets
local left_bar = require('items.brackets.left_bar')

-- Widgets
local smenu = require("items.widgets.smenu")
local menu_watcher = require("items.widgets.menus")
local front_app = require("items.widgets.front_app")

local M = {}

M.setup = function(sbar)
  -- Setup widgets first
  smenu(sbar)
  menu_watcher(sbar)
  front_app(sbar)
  
  -- Setup brackets
  left_bar.setup(sbar)
end

return M
