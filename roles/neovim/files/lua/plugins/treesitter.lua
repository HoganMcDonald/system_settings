local load_textobjects = false

return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'RRethy/nvim-treesitter-endwise',
      'nvim-treesitter/nvim-treesitter-textobjects',
      'windwp/nvim-ts-autotag',
    },
    cmd = { 'TSUpdateSync' },
    keys = {
      { '<c-space>', desc = 'Increment selection' },
    },
    opts = {
      auto_install = true,
      ensure_installed = {
        'javascript',
        'typescript',
        'tsx',

        'html',
        'json',
        'lua',
        'luadoc',
        'luap',
        'markdown',
        'markdown_inline',
        'query',
        'regex',
        'yaml',
      },
      highlight = { enable = true },
      indent = { enable = true },
      endwise = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<C-space>',
          node_incremental = '<C-space>',
          scope_incremental = false,
          node_decremental = '<bs>',
        },
      },
      textobjects = {
        select = {
          enable = true,

          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,

          keymaps = {
            -- methods
            ['m'] = '@function.outer',
            ['mi'] = '@function.inner',

            -- assignments
            ['v'] = '@assignment.outer',
            ['vi'] = '@assignment.inner',
            ['vl'] = '@assignment.lhs',
            ['vr'] = '@assignment.rhs',
          },
          selection_modes = {
            ['@parameter.outer'] = 'v',
            ['@function.outer'] = 'V',
            ['@class.outer'] = '<c-v>',
          },
          include_surrounding_whitespace = true,
        },
        swap = {
          enable = true,
          swap_next = {
            ['<leader>sp'] = '@parameter.inner',
            ['<leader>sm'] = '@function.outer',
            ['<leader>sv'] = '@assignment.outer',
          },
          swap_previous = {
            ['<leader>SP'] = '@parameter.inner',
            ['<leader>SM'] = '@function.outer',
            ['<leader>SV'] = '@assignment.outer',
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            [']m'] = '@function.outer',
            [']v'] = '@assignment.outer',
            [']c'] = '@class.outer',
            [']z'] = '@fold',
          },
          goto_next_end = {
            [']M'] = '@function.outer',
            [']V'] = '@assignment.outer',
            [']C'] = '@class.outer',
            [']Z'] = '@fold',
          },
          goto_previous_start = {
            ['[m'] = '@function.outer',
            ['[v'] = '@assignment.outer',
            ['[c'] = '@class.outer',
            ['[z'] = '@fold',
          },
          goto_previous_end = {
            ['[M'] = '@function.outer',
            ['[V'] = '@assignment.outer',
            ['[C'] = '@class.outer',
            ['[Z'] = '@fold',
          },
        },
        lsp_interop = {
          enable = true,
          border = 'none',
          floating_preview_opts = {},
          peek_definition_code = {
            ['<leader>pm'] = '@function.outer',
            ['<leader>pc'] = '@class.outer',
          },
        },
      },
    },
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)
      require('nvim-ts-autotag').setup()
    end,
  },

  {
    'sustech-data/wildfire.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('wildfire').setup()
    end,
  },

  -- markdown
  {
    'MeanderingProgrammer/markdown.nvim',
    name = 'render-markdown', -- Only needed if you have another plugin named markdown.nvim
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    config = function()
      require('render-markdown').setup {}
    end,
  },
}
