local Colors = require 'util.colors'

return {
  -- icons
  {
    'nvim-tree/nvim-web-devicons',
    lazy = true,
  },

  -- colorizer
  {
    'norcalli/nvim-colorizer.lua',
    event = 'BufRead',
    opts = {
      RGB = true, -- #RGB hex codes
      RRGGBB = true, -- #RRGGBB hex codes
      names = false, -- "Name" codes like Blue
      RRGGBBAA = false, -- #RRGGBBAA hex codes
      rgb_fn = false, -- CSS rgb() and rgba() functions
      hsl_fn = false, -- CSS hsl() and hsla() functions
      css = false, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
      css_fn = false, -- Enable all CSS *functions*: rgb_fn, hsl_fn

      -- Available modes: foreground, background
      mode = 'background', -- Set the display mode.
    },
    config = function(_, opts)
      require('colorizer').setup({ '*' }, opts)
      vim.cmd 'ColorizerReloadAllBuffers'
    end,
  },

  {
    'kevinhwang91/nvim-hlslens',
    keys = {
      {
        'n',
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
      },
      {
        'N',
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
      },
      { '*', [[*<Cmd>lua require('hlslens').start()<CR>]] },
      { '#', [[#<Cmd>lua require('hlslens').start()<CR>]] },
      { 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]] },
      { 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]] },
    },
    config = function(_, opts)
      require('hlslens').setup(opts)
    end,
  },
}
