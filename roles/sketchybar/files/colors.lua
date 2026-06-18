-- Marathon / cyberpunk HUD palette

local M = {}

-- Accent colors
M.blue      = 0xff47a7ff
M.green     = 0xff35ff8a
M.red       = 0xffff3f66
M.yellow    = 0xffffd15c
M.purple    = 0xff9b5cff
M.pink      = 0xffff2bd6
M.teal      = 0xff00f5ff
M.orange    = 0xffff8a3d

-- Semantic HUD accents
M.cyan      = M.teal
M.magenta   = M.pink
M.amber     = M.yellow
M.warning   = M.orange
M.critical  = M.red

-- Surface colors
M.text      = 0xffe8fbff
M.subtext1  = 0xff9bb6c5
M.subtext0  = 0xff667884
M.overlay2  = 0xff35505d
M.overlay1  = 0xff233743
M.overlay0  = 0xff172832
M.surface2  = 0xff183544
M.surface1  = 0xff0f242f
M.surface0  = 0xff071820

-- Background colors
M.base      = 0xff02070c
M.mantle    = 0xff050d14
M.crust     = 0xff010306

-- Transparent variants (for use with transparency)
M.transparent = 0x00000000
M.bar_bg = M.transparent
M.panel_bg = 0xe6071820
M.panel_bg_dim = 0xd4111f2a
M.glow_cyan = 0x6600f5ff
M.glow_magenta = 0x66ff2bd6

-- Compatibility aliases used by older components.
M.lavender = M.purple
M.sky = M.cyan

-- Utility function to create color with custom alpha
function M.with_alpha(color, alpha)
  local rgb = color & 0xffffff
  return (alpha << 24) | rgb
end

return M
