return {
  -- tokyonight
  -- {
  --   "folke/tokyonight.nvim",
  --   lazy = true,
  --   opts = { style = "moon" },
  -- },

  -- halcyon
  {
    'kwsp/halcyon-neovim',
    lazy = false,
    config = function(_, opts)
      local Colors = require('util.colors')
      local bg = require('util.highlight').bg
      local fg = require('util.highlight').fg
      vim.cmd.colorscheme('halcyon')

      -- fixes issue where highlights for vertsplit seem backwards
      bg('VertSplit', Colors.BACKGROUND)
      fg('VertSplit', Colors.GREY)
    end,
  },
}
