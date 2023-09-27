local M = {}

local colors = {}

colors.black = '#171C28'
colors.bg = '#1D2433'
colors.highlight = '#2F3B54'
colors.grey = '#6679A4'
colors.light_grey = '#8695B7'
colors.off_white = '#A2AABC'
colors.white = '#D7DCE2'
colors.gold = '#FFCC66'
colors.blue = '#5CCFE6'
colors.green = '#BAE67E'
colors.orange = '#FFAE57'
colors.yellow = '#FFD580'
colors.lavender = '#C3A6FF'
colors.red = '#EF6B73'
colors.none = 'NONE'

M.get = function()
  return colors
end

return M
