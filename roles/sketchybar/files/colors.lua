-- Cyberdream Color Palette
-- https://github.com/scottmckendry/cyberdream.nvim

local M = {}

-- Accent colors
M.blue      = 0xff5ea1ff
M.green     = 0xff5eff6b
M.red       = 0xffff6e5e
M.yellow    = 0xfff1ff5e
M.purple    = 0xffbd5eff
M.pink      = 0xffff5ea0
M.teal      = 0xff5ef1ff
M.orange    = 0xffffbd5e

-- Surface colors
M.text      = 0xffffffff
M.subtext1  = 0xffb8c0cc
M.subtext0  = 0xff7b8496
M.overlay2  = 0xff5a6272
M.overlay1  = 0xff4a505c
M.overlay0  = 0xff3c4048
M.surface2  = 0xff3c4048
M.surface1  = 0xff26282c
M.surface0  = 0xff1a1c1e

-- Background colors
M.base      = 0xff000000
M.mantle    = 0xff0a0b0d
M.crust     = 0xff000000

-- Transparent variants (for use with transparency)
M.transparent = 0x00000000
M.bar_bg = 0xcc000000  -- Semi-transparent base

-- Utility function to create color with custom alpha
function M.with_alpha(color, alpha)
  local rgb = color & 0xffffff
  return (alpha << 24) | rgb
end

return M
