local Colors = require 'util.colors'

return {
  -- lsp installer
  {
    'williamboman/mason.nvim',
    dependencies = {
      'williamboman/mason-lspconfig.nvim',
      'neovim/nvim-lspconfig',
    },
  },

  -- ---------------------
  -- lsp utilities
  -- ---------------------
  -- free up ram by stopping lsps
  {
    'zeioth/garbage-day.nvim',
    dependencies = 'neovim/nvim-lspconfig',
    event = 'VeryLazy',
    opts = {
      -- your options here
    },
  },

  -- ---------------------
  -- lsp ui elements
  -- ---------------------
  -- lsp progress
  {
    'j-hui/fidget.nvim',
  },

  -- virtual text lines
  {
    'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
    config = function()
      require('lsp_lines').setup()
    end,
  },

  -- lsp hover
  {
    'lewis6991/hover.nvim',
    keys = {
      {
        'K',
        function()
          require('hover').hover()
        end,
        desc = '[hover.nvim] LSP Hover',
      },
      {
        'gK',
        function()
          require('hover').hover_select()
        end,
        desc = '[hover.nvim] LSP Hover (select)',
      },
      {
        '<C-p>',
        function()
          require('hover').hover_switch 'previous'
        end,
        desc = '[hover.nvim] Previous Source',
      },
      {
        '<C-n>',
        function()
          require('hover').hover_switch 'next'
        end,
        desc = '[hover.nvim] Next Source',
      },
    },
    opts = {
      init = function()
        require 'hover.providers.lsp'
        -- require('hover.providers.gh')
        -- require('hover.providers.gh_user')
        -- require('hover.providers.jira')
        require 'hover.providers.man'
        require 'hover.providers.dictionary'
      end,
    },
  },

  -- code actions previews
  {
    'aznhe21/actions-preview.nvim',
    keys = {
      {
        '<leader>ca',
        function()
          require('actions-preview').code_actions()
        end,
        desc = 'Code Action',
        mode = { 'n', 'v' },
      },
    },
  },

  -- winbar
  {
    'SmiteshP/nvim-navic', -- statusline/winbar component using lsp
    dependencies = 'neovim/nvim-lspconfig',
    opts = {
      highlight = true,
      separator = ' 〉',
      -- VScode-like icons
      icons = {
        File = ' ',
        Module = ' ',
        Namespace = ' ',
        Package = ' ',
        Class = ' ',
        Method = ' ',
        Property = ' ',
        Field = ' ',
        Constructor = ' ',
        Enum = ' ',
        Interface = ' ',
        Function = ' ',
        Variable = ' ',
        Constant = ' ',
        String = ' ',
        Number = ' ',
        Boolean = ' ',
        Array = ' ',
        Object = ' ',
        Key = ' ',
        Null = ' ',
        EnumMember = ' ',
        Struct = ' ',
        Event = ' ',
        Operator = ' ',
        TypeParameter = ' ',
      },
    },
  },

  {
    'utilyre/barbecue.nvim',
    name = 'barbecue',
    version = '*',
    dependencies = {
      'SmiteshP/nvim-navic',
      'nvim-tree/nvim-web-devicons', -- optional dependency
    },
    opts = {
      theme = {
        normal = { bg = Colors.BLACK },
      },
    },
  },
}
