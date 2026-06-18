local lib = require('lib')
local colors = require('colors')

local apple = require('bar.components.apple')
local degraded_warning = require('bar.components.degraded_warning')
local mode_indicator = require('bar.components.mode_indicator')
local workspace_indicator = require('bar.components.workspace_indicator')
local clock = require('bar.components.clock')
local wifi = require('bar.components.wifi')
local battery = require('bar.components.battery')
local swap_warning = require('bar.components.swap_warning')

local M = {}

function M.setup()
  lib.render.render({
    bar = {
      color = colors.bar_bg,
      height = 40,
      blur_radius = 0,
      margin = 18,
      y_offset = 10,
      corner_radius = 4,
      position = 'top',
      sticky = true,
      padding_left = 14,
      padding_right = 14,
    },

    events = {
      'aerospace_mode_change',
      'aerospace_workspace_change',
    },

    defaults = {
      icon = { font = { family = 'Hack Nerd Font:Bold', size = 15 }, color = colors.cyan },
      label = { font = { family = 'Hack Nerd Font:Bold', size = 13 }, color = colors.text },
      background = {
        drawing = true,
        color = colors.panel_bg_dim,
        border_color = colors.overlay2,
        border_width = 1,
        corner_radius = 3,
        height = 28,
      },
      padding_left = 4,
      padding_right = 4,
    },

    left = { apple, degraded_warning, mode_indicator },
    center = { workspace_indicator },
    right = { clock, wifi, battery, swap_warning },
  })
end

return M
