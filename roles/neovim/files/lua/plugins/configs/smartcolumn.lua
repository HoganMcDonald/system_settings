-----------------------------------------------------------
-- Smart Column highlight configuration file
-----------------------------------------------------------

-- Plugin: smartcolumn.nvim
-- https://github.com/m4xshen/smartcolumn.nvim

local bg = require('core.utils').bg
local colors = require('core.colors').get()

local present, smartcolumn = pcall(require, 'smartcolumn')

if not present then
  return
end

smartcolumn.setup {
  colorcolumn = "80",
  disabled_filetypes = {
    "help",
    "text",
    "markdown",
    "dashboard",
    "NvimTree",
    "Lazy",
    "mason",
    "help",
    "eruby"
  },
  custom_colorcolumn = {},
  scope = "window",
}

bg('ColorColumn', colors.highlight)
