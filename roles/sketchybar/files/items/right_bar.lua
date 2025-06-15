-- Brackets
local systray = require('items.brackets.systray')
local clock = require('items.brackets.clock')
local volume_bracket = require('items.brackets.volume')
local right_bar = require('items.brackets.right_bar')

-- Widgets
local search   = require("items.widgets.search")
local cal      = require("items.widgets.cal")
local volume   = require("items.widgets.volume")
local wifi     = require("items.widgets.wifi")
local media    = require("items.widgets.media")
local weather  = require("items.widgets.weather")

local M = {}

M.setup = function(sbar)
  -- Setup widgets first
  search(sbar)
  cal(sbar)
  volume(sbar)
  wifi(sbar)
  media(sbar)
  weather(sbar)

  -- Setup brackets
  systray.setup(sbar)
  clock.setup(sbar)
  volume_bracket.setup(sbar)
  right_bar.setup(sbar)
end

return M
