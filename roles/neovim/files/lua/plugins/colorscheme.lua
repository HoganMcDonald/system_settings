local Colors = require 'util.colors'
local bg = require('util.highlight').bg
local fg = require('util.highlight').fg

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function(_, opts)
      vim.cmd.colorscheme 'tokyonight'
    end
  }

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
