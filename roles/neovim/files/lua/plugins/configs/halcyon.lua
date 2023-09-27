-----------------------------------------------------------
-- Halcyon colorscheme configuration file
-----------------------------------------------------------

-- Plugin: halcyon
-- https://github.com/kwsp/halcyon-neovim

local cmd = vim.cmd
local bg = require('core.utils').bg
local fg = require('core.utils').fg
local colors = require('core.colors').get()

cmd([[colorscheme halcyon]])

-----------------------------------------------------------
-- Highlights
-----------------------------------------------------------
bg('VertSplit', colors.bg)
fg('VertSplit', colors.highlight)
