local hi_link = require('util.highlight').hi_link

return {
  {
    'tpope/vim-fugitive',
    keys = {
      { '<leader>gc', ':Git commit<cr>', desc = 'Commit' },
    },
    cmd = 'Git',
  },

  -- diffview
  {
    'sindrets/diffview.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    keys = {
      {
        '<leader>gg',
        function()
          local lib = require 'diffview.lib'
          local view = lib.get_current_view()
          if view then
            -- Current tabpage is a Diffview; close it
            vim.cmd ':DiffviewClose'
          else
            -- No open Diffview exists: open a new one
            vim.cmd ':DiffviewOpen'
          end
        end,
        desc = '[diffview] Toggle Diffview',
      },
      {
        '<leader>gh',
        '<cmd>DiffviewFileHistory<cr>',
        mode = { 'n' },
        desc = '[diffview] Repo history',
      },
      {
        '<leader>gf',
        '<cmd>DiffviewFileHistory --follow %<cr>',
        mode = { 'n' },
        desc = '[diffview] File history',
      },
      {
        '<leader>gm',
        '<cmd>DiffviewOpen main<cr>',
        mode = { 'n' },
        desc = '[diffview] Diff with main',
      },
      {
        '<leader>gl',
        '<cmd>.DiffviewFileHistory --follow<CR>',
        mode = { 'n' },
        desc = '[diffview] Line history',
      },
      {
        '<leader>gg',
        '<esc><cmd>\'<,\'>DiffviewFileHistory --follow<CR>',
        mode = { 'v' },
        desc = '[diffview] Range history',
      },
    },
    config = function()
      -- set fillchars in vim
      vim.opt.fillchars:append { diff = '╱' }

      require('diffview').setup {
        diff_binaries = false,
        enhanced_diff_hl = true,
        git_cmd = { 'git' },
        hg_cmd = { 'chg' },
        use_icons = true,
        show_help_hints = false,
        view = {
          default = {
            -- layout = "diff1_inline",
            winbar_info = false,
          },
          merge_tool = {
            layout = 'diff3_mixed',
            disable_diagnostics = true,
            winbar_info = true,
          },
          file_history = {
            -- layout = "diff1_inline",
            winbar_info = false,
          },
        },
        file_panel = {
          listing_style = 'tree',
          tree_options = {
            flatten_dirs = true,
            folder_statuses = 'only_folded',
          },
          win_config = function()
            local editor_width = vim.o.columns
            return {
              position = 'left',
              width = editor_width >= 247 and 45 or 35,
            }
          end,
        },
        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                diff_merges = 'first-parent',
                follow = true,
              },
              multi_file = {
                diff_merges = 'first-parent',
              },
            },
          },
          win_config = {
            position = 'bottom',
            height = 16,
          },
        },
        default_args = {
          DiffviewOpen = {},
          DiffviewFileHistory = {},
        },
      }
    end,
  },

  -- gitsigns
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufRead',
    keys = {
      { '<leader>hn', ':Gitsigns next_hunk<cr>', desc = 'Next' },
      { '<leader>hp', ':Gitsigns prev_hunk<cr>', desc = 'Previous' },
      { '<leader>hs', ':Gitsigns stage_hunk<cr>', desc = 'Stage' },
      { '<leader>hr', ':Gitsigns reset_hunk<cr>', desc = 'Reset' },
      { '<leader>br', ':Gitsigns reset_buffer<cr>', desc = 'Git reset' },
      { '<leader>gb', ':Gitsigns blame_line<cr>', desc = 'Blame Line' },
    },
    opts = {
      signs = {
        add = { hl = 'GitSignsAdd', text = '▎', numhl = 'GitSignsAddNr', linehl = 'GitSignsAddLn' },
        change = { hl = 'GitSignsChange', text = '▎', numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn' },
        delete = { hl = 'GitSignsDelete', text = '▎', numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn' },
        topdelete = {
          hl = 'GitSignsDelete',
          text = '▎',
          numhl = 'GitSignsDeleteNr',
          linehl = 'GitSignsDeleteLn',
        },
        changedelete = {
          hl = 'GitSignsChange',
          text = '▎',
          numhl = 'GitSignsChangeNr',
          linehl = 'GitSignsChangeLn',
        },
      },
      signcolumn = true,
      numhl = false,
      linehl = false,
      word_diff = false,
      watch_gitdir = {
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true,
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        delay = 1000,
        ignore_whitespace = false,
      },
      current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
      current_line_blame_formatter_opts = {
        relative_time = false,
      },
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil,
      max_file_length = 40000,
      preview_config = {
        border = 'single',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1,
      },
      yadm = {
        enable = false,
      },
    },
  },
}
