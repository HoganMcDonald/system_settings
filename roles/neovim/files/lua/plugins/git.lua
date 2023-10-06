return {
  {
    'tpope/vim-fugitive',
    keys = {
      { '<leader>gb', ':Git blame<cr>', desc = 'Blame' },
      { '<leader>ga', ':Git add -p<cr>', desc = 'Add' },
      { '<leader>gc', ':Git commit<cr>', desc = 'Commit' },
    },
  },

  -- diffview
  {
    'sindrets/diffview.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    keys = {
      { '<leader>dv', ':DiffviewOpen<cr>', desc = 'Open diff view' },
      { '<leader>dc', ':DiffviewClose<cr>', desc = 'Close diff view' },
      { '<leader>gh', ':DiffviewFileHistory<cr>', desc = 'History - diffview' },
    },
    opts = function()
      local cb = require('diffview.config').diffview_callback
      return {
        diff_binaries = false, -- Show diffs for binaries
        enhanced_diff_hl = false, -- See ':h diffview-config-enhanced_diff_hl'
        use_icons = true, -- Requires nvim-web-devicons
        icons = { -- Only applies when use_icons is true.
          folder_closed = '',
          folder_open = '',
        },
        signs = {
          fold_closed = '',
          fold_open = '',
        },
        file_panel = {
          -- position = "left",                  -- One of 'left', 'right', 'top', 'bottom'
          -- width = 35,                         -- Only applies when position is 'left' or 'right'
          -- height = 10,                        -- Only applies when position is 'top' or 'bottom'
          listing_style = 'tree', -- One of 'list' or 'tree'
          tree_options = { -- Only applies when listing_style is 'tree'
            flatten_dirs = true, -- Flatten dirs that only contain one single dir
            folder_statuses = 'only_folded', -- One of 'never', 'only_folded' or 'always'.
          },
        },
        file_history_panel = {
          -- position = "bottom",
          -- width = 35,
          -- height = 16,
          --[[ log_options = {
      max_count = 256,      -- Limit the number of commits
      follow = false,       -- Follow renames (only for single file)
      all = false,          -- Include all refs under 'refs/' including HEAD
      merges = false,       -- List only merge commits
      no_merges = false,    -- List no merge commits
      reverse = false,      -- List commits in reverse order
    }, ]]
        },
        default_args = { -- Default args prepended to the arg-list for the listed commands
          DiffviewOpen = {},
          DiffviewFileHistory = {},
        },
        hooks = {}, -- See ':h diffview-config-hooks'
        key_bindings = {
          disable_defaults = false, -- Disable the default key bindings
          -- The `view` bindings are active in the diff buffers, only when the current
          -- tabpage is a Diffview.
          view = {
            ['<tab>'] = cb('select_next_entry'), -- Open the diff for the next file
            ['<s-tab>'] = cb('select_prev_entry'), -- Open the diff for the previous file
            ['gf'] = cb('goto_file'), -- Open the file in a new split in previous tabpage
            ['<C-w><C-f>'] = cb('goto_file_split'), -- Open the file in a new split
            ['<C-w>gf'] = cb('goto_file_tab'), -- Open the file in a new tabpage
            ['<leader>e'] = cb('focus_files'), -- Bring focus to the files panel
            ['<leader>b'] = cb('toggle_files'), -- Toggle the files panel.
          },
          file_panel = {
            ['j'] = cb('next_entry'), -- Bring the cursor to the next file entry
            ['<down>'] = cb('next_entry'),
            ['k'] = cb('prev_entry'), -- Bring the cursor to the previous file entry.
            ['<up>'] = cb('prev_entry'),
            ['l'] = cb('select_entry'), -- Open the diff for the selected entry.
            ['<left>'] = cb('select_entry'),
            ['o'] = cb('select_entry'),
            ['<2-LeftMouse>'] = cb('select_entry'),
            ['<cr>'] = cb('toggle_stage_entry'), -- Stage / unstage the selected entry.
            ['S'] = cb('stage_all'), -- Stage all entries.
            ['U'] = cb('unstage_all'), -- Unstage all entries.
            ['X'] = cb('restore_entry'), -- Restore entry to the state on the left side.
            ['R'] = cb('refresh_files'), -- Update stats and entries in the file list.
            ['<tab>'] = cb('select_next_entry'),
            ['<s-tab>'] = cb('select_prev_entry'),
            ['gf'] = cb('goto_file'),
            ['<C-w><C-f>'] = cb('goto_file_split'),
            ['<C-w>gf'] = cb('goto_file_tab'),
            ['i'] = cb('listing_style'), -- Toggle between 'list' and 'tree' views
            ['f'] = cb('toggle_flatten_dirs'), -- Flatten empty subdirectories in tree listing style.
            ['<leader>e'] = cb('focus_files'),
            ['<leader>b'] = cb('toggle_files'),
          },
          file_history_panel = {
            ['g!'] = cb('options'), -- Open the option panel
            ['<C-A-d>'] = cb('open_in_diffview'), -- Open the entry under the cursor in a diffview
            ['y'] = cb('copy_hash'), -- Copy the commit hash of the entry under the cursor
            ['zR'] = cb('open_all_folds'),
            ['zM'] = cb('close_all_folds'),
            ['j'] = cb('next_entry'),
            ['<down>'] = cb('next_entry'),
            ['k'] = cb('prev_entry'),
            ['<up>'] = cb('prev_entry'),
            ['l'] = cb('select_entry'),
            ['o'] = cb('select_entry'),
            ['<2-LeftMouse>'] = cb('select_entry'),
            ['<tab>'] = cb('select_next_entry'),
            ['<s-tab>'] = cb('select_prev_entry'),
            ['gf'] = cb('goto_file'),
            ['<C-w><C-f>'] = cb('goto_file_split'),
            ['<C-w>gf'] = cb('goto_file_tab'),
            ['<leader>e'] = cb('focus_files'),
            ['<leader>b'] = cb('toggle_files'),
          },
          option_panel = {
            ['<tab>'] = cb('select'),
            ['q'] = cb('close'),
          },
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
      { '<leader>gl', ':Gitsigns blame_line<cr>', desc = 'Blame Line' },
    },
    opts = {
      signs = {
        add = { hl = 'GitSignsAdd', text = '▎', numhl = 'GitSignsAddNr', linehl = 'GitSignsAddLn' },
        change = { hl = 'GitSignsChange', text = '▎', numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn' },
        delete = { hl = 'GitSignsDelete', text = '▎', numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn' },
        topdelete = {
          hl = 'GitSignsDelete',
          text = '契',
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
