local Colors = require('util.colors')
local bg = require('util.highlight').bg
local fg = require('util.highlight').fg

return {
  -- halcyon
  {
    'kwsp/halcyon-neovim',
    lazy = false,
    config = function(_, opts)
      vim.cmd.colorscheme('halcyon')

      -- fixes issue where highlights for vertsplit seem backwards
      bg('VertSplit', Colors.BACKGROUND)
      fg('VertSplit', Colors.GREY)
    end,
  },
  --
  -- -- halcyon base16 custom
  -- {
  --   'RRethy/base16-nvim',
  --   lazy = false,
  --   config = function()
  --     require('base16-colorscheme').setup({
  --       base00 = Colors.BACKGROUND, -- background
  --       base01 = Colors.WORKBENCH,
  --       base02 = Colors.GREY,
  --       base03 = Colors.UI_GREY,
  --       base04 = '#565c84',
  --       base05 = '#abb2bf',
  --       base06 = Colors.LIGHT_GREY,
  --       base07 = Colors.WHITE,
  --       base08 = Colors.ACCENT,
  --       base09 = Colors.ORANGE,
  --       base0A = Colors.YELLOW,
  --       base0B = Colors.GREEN,
  --       base0C = Colors.PURPLE,
  --       base0D = Colors.RED,
  --       base0E = Colors.BLUE,
  --       base0F = '#bada55',
  --     })
  --
  --     bg('VertSplit', Colors.BACKGROUND)
  --     fg('VertSplit', Colors.GREY)
  --   end,
  -- },
}
