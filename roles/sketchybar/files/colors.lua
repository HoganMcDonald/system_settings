-- Catppuccin Mocha Color Palette
-- https://github.com/catppuccin/catppuccin

local M = {}

-- Base colors
M.rosewater = 0xfff5e0dc
M.flamingo  = 0xfff2cdcd
M.pink      = 0xfff5c2e7
M.mauve     = 0xffcba6f7
M.red       = 0xfff38ba8
M.maroon    = 0xffeba0ac
M.peach     = 0xfffab387
M.yellow    = 0xfff9e2af
M.green     = 0xffa6e3a1
M.teal      = 0xff94e2d5
M.sky       = 0xff89dceb
M.sapphire  = 0xff74c7ec
M.blue      = 0xff89b4fa
M.lavender  = 0xffb4befe

-- Surface colors
M.text      = 0xffcdd6f4
M.subtext1  = 0xffbac2de
M.subtext0  = 0xffa6adc8
M.overlay2  = 0xff9399b2
M.overlay1  = 0xff7f849c
M.overlay0  = 0xff6c7086
M.surface2  = 0xff585b70
M.surface1  = 0xff45475a
M.surface0  = 0xff313244

-- Background colors
M.base      = 0xff1e1e2e
M.mantle    = 0xff181825
M.crust     = 0xff11111b

-- Transparent variants (for use with transparency)
M.transparent = 0x00000000
M.bar_bg = 0xcc1e1e2e  -- Semi-transparent base

-- Utility function to create color with custom alpha
function M.with_alpha(color, alpha)
  local rgb = color & 0xffffff
  return (alpha << 24) | rgb
end

return M
