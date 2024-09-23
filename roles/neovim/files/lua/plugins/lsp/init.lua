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

  {
    'smjonas/inc-rename.nvim',
    keys = {
      {
        '<leader>lr',
        function()
          return ':IncRename ' .. vim.fn.expand '<cword>'
        end,
        expr = true,
        desc = 'Incremental Rename',
      },
    },
    config = function()
      require('inc_rename').setup()
    end,
  },

  -- ---------------------
  -- lsp ui elements
  -- ---------------------
  -- lsp progress
  {
    'j-hui/fidget.nvim',
    opts = {},
  },

  -- virtual text lines
  {
    'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
    keys = {
      {
        '<leader>ll',
        function()
          require('lsp_lines').toggle()
        end,
        desc = '[lsp_lines] Toggle lsp_lines',
      },
    },
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
    'luckasRanarison/clear-action.nvim',
    event = 'LspAttach',
    opts = function()
      local fmt = require('util.icons').fmt

      return {
        silent = true, -- dismiss code action requests errors
        signs = {
          enable = false,
          combine = true, -- combines all action kinds into a single sign
          priority = 200, -- extmark priority
          position = 'eol', -- "right_align" | "overlay" | "eol"
          separator = ' ', -- signs separator
          show_count = false, -- show the number of each action kind
          show_label = true, -- show the string returned by `label_fmt`
          label_fmt = function(actions)
            return actions[1].title
          end, -- actions is an array of `CodeAction`
          update_on_insert = false, -- show and update signs in insert mode
          icons = {
            quickfix = '🔧',
            refactor = '💡',
            source = '🔗',
            combined = '💡', -- used when combine is set to true or as a fallback when there is no action kind
          },
          highlights = { -- highlight groups
            quickfix = 'NonText',
            refactor = 'NonText',
            source = 'NonText',
            combined = 'NonText',
            label = 'NonText',
          },
        },
        popup = { -- replaces the default prompt when selecting code actions
          enable = true,
          center = false,
          border = 'rounded',
          hide_cursor = true,
          hide_client = false, -- hide displaying name of LSP client
          highlights = {
            header = 'CodeActionHeader',
            label = 'CodeActionLabel',
            title = 'CodeActionTitle',
          },
        },
        mappings = {
          code_action = { '<leader>ca', fmt('Fix', 'Code action') },
          apply_first = { '<leader>cc', fmt('Fix', 'Apply') },
          quickfix = { '<leader>cq', fmt('Fix', 'Quickfix') },
          quickfix_next = { '<leader>cn', fmt('Fix', 'Quickfix next') },
          quickfix_prev = { '<leader>cp', fmt('Fix', 'Quickfix prev') },
          refactor = { '<leader>cr', fmt('Fix', 'Refactor') },
          refactor_inline = { '<leader>cR', fmt('Fix', 'Refactor inline') },
          actions = {
            ['rust_analyzer'] = {
              ['Import'] = { '<leader>ai', fmt('Fix', 'Import') },
              ['Replace if'] = { '<leader>am', fmt('Fix', 'Replace if with match') },
              ['Fill match'] = { '<leader>af', fmt('Fix', 'Fill match arms') },
              ['Wrap'] = { '<leader>aw', fmt('Fix', 'Wrap') },
              ['Insert `mod'] = { '<leader>aM', fmt('Fix', 'Insert mod') },
              ['Insert `pub'] = { '<leader>aP', fmt('Fix', 'Insert pub mod') },
              ['Add braces'] = { '<leader>ab', fmt('Fix', 'Add braces') },
            },
          },
        },
      }
    end,
  },

  -- winbar
  {
    'Bekaboo/dropbar.nvim',
    -- optional, but required for fuzzy finder support
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim',
    },
  },
}
