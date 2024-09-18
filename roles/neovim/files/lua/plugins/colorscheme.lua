local Colors = require 'util.colors'
local bg = require('util.highlight').bg
local fg = require('util.highlight').fg

return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "catppuccin-mocha" -- catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
    end
  },

  -- -- halcyon
  -- {
  --   'kwsp/halcyon-neovim',
  --   lazy = false,
  --   config = function()
  --     vim.cmd.colorscheme 'halcyon'
  --
  --     -- fixes issue where highlights for vertsplit seem backwards
  --     bg('VertSplit', Colors.BACKGROUND)
  --     fg('VertSplit', Colors.GREY)
  --   end,
  -- },
}
