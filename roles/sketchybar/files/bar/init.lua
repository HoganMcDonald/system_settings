local lib = require('lib')

local apple = require('bar.components.apple')
local mode_indicator = require('bar.components.mode_indicator')
local workspace_indicator = require('bar.components.workspace_indicator')
local clock = require('bar.components.clock')
local wifi = require('bar.components.wifi')
local battery = require('bar.components.battery')

local M = {}

function M.setup()
  lib.render.render({
    bar = {
      height = 32,
      blur_radius = 30,
      margin = 20,
      y_offset = 15,
      corner_radius = 10,
      position = 'top',
      sticky = true,
      padding_left = 10,
      padding_right = 10,
    },

    events = {
      'aerospace_mode_change',
      'aerospace_workspace_change',
    },

    defaults = {
      label = { font = { family = 'SF Pro Display', size = 14 } },
    },

    left = { apple, mode_indicator },
    center = { workspace_indicator },
    right = { clock, wifi, battery },
  })
end

return M
