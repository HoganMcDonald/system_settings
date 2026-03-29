-- GitHub Dark Color Palette
-- https://github.com/primer/primitives

local M = {}

-- Accent colors
M.blue      = 0xff58a6ff
M.green     = 0xff3fb950
M.red       = 0xfff85149
M.yellow    = 0xffe3b341
M.purple    = 0xffbc8cff
M.pink      = 0xffdb61a2
M.teal      = 0xff39c5cf
M.orange    = 0xfff0883e

-- Surface colors
M.text      = 0xffe6edf3
M.subtext1  = 0xffb1bac4
M.subtext0  = 0xff8b949e
M.overlay2  = 0xff6e7681
M.overlay1  = 0xff484f58
M.overlay0  = 0xff30363d
M.surface2  = 0xff30363d
M.surface1  = 0xff21262d
M.surface0  = 0xff161b22

-- Background colors
M.base      = 0xff0d1117
M.mantle    = 0xff010409
M.crust     = 0xff000000

-- Transparent variants (for use with transparency)
M.transparent = 0x00000000
M.bar_bg = 0xcc0d1117  -- Semi-transparent base

-- Utility function to create color with custom alpha
function M.with_alpha(color, alpha)
  local rgb = color & 0xffffff
  return (alpha << 24) | rgb
end

return M
