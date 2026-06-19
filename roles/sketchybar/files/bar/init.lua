print("[bar/init.lua] loading...")
local lib = require('lib')
print("[bar/init.lua] lib loaded")
local colors = require('colors')
print("[bar/init.lua] colors loaded")

print("[bar/init.lua] loading components...")
local apple = require('bar.components.apple')
print("[bar/init.lua] apple loaded")
local degraded_warning = require('bar.components.degraded_warning')
print("[bar/init.lua] degraded_warning loaded")
local mode_indicator = require('bar.components.mode_indicator')
print("[bar/init.lua] mode_indicator loaded")
local workspace_indicator = require('bar.components.workspace_indicator')
print("[bar/init.lua] workspace_indicator loaded")
local clock = require('bar.components.clock')
print("[bar/init.lua] clock loaded")
local wifi = require('bar.components.wifi')
print("[bar/init.lua] wifi loaded")
local cpu_temp = require('bar.components.cpu_temp')
print("[bar/init.lua] cpu_temp loaded")
local ram_usage = require('bar.components.ram_usage')
print("[bar/init.lua] ram_usage loaded")
local battery = require('bar.components.battery')
print("[bar/init.lua] battery loaded")
local swap_warning = require('bar.components.swap_warning')
print("[bar/init.lua] swap_warning loaded")

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
    right = { clock, wifi, cpu_temp, ram_usage, battery, swap_warning },
  })
end

return M
