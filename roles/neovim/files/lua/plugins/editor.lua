local Colors = require 'util.colors'
local bg = require('util.highlight').bg
local fg = require('util.highlight').fg

return {
  -- fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'folke/trouble.nvim' },
    cmd = 'Telescope',
    keys = {
      { '<leader>pf', ':Telescope find_files<cr>', desc = '[Telescope] Find files' },
      { '<leader>po', ':Telescope oldfiles<cr>', desc = '[Telescope] Old files' },
      { '<leader>fa', ':Telescope live_grep<cr>', desc = '[Telescope] All files' },
      { '<leader>bb', ':Telescope buffers<cr>', desc = '[Telescope] buffers' },
      { 'gr', ':Telescope lsp_references<CR>', desc = '[Telescope] Go to references' },
    },
    config = function()
      local open_with_trouble = require('trouble.sources.telescope').open

      -- Use this to add more results without clearing the trouble list
      local add_to_trouble = require('trouble.sources.telescope').add

      local opts = {
        defaults = {
          mappings = {
            i = {
              ['<c-q>'] = open_with_trouble,
              ['<c-a>'] = add_to_trouble,
              ['<c-d>'] = require('telescope.actions').delete_buffer,
            },
            n = {
              ['<c-q>'] = open_with_trouble,
              ['<c-a>'] = add_to_trouble,
              ['<c-d>'] = require('telescope.actions').delete_buffer,
            },
          },
          prompt_prefix = '   ',
          selection_caret = '  ',

          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
          },
          entry_prefix = '  ',
          initial_mode = 'insert',
          selection_strategy = 'reset',
          sorting_strategy = 'ascending',
          layout_strategy = 'horizontal',
          layout_config = {
            horizontal = {
              prompt_position = 'top',
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          file_ignore_patterns = { 'node_modules' },
          path_display = { 'truncate' },
          winblend = 0,
          border = {},
          borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
          color_devicons = true,
        },
      }
      require('telescope').setup(opts)
    end,
  },

  -- buffer management
  {
    'theprimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    event = 'BufEnter',
    config = function()
      require('harpoon'):setup()
    end,
    keys = {
      {
        '<leader>bp',
        function()
          require('harpoon'):list():add()
        end,
        desc = '[harpoon] pin buffer',
      },
      {
        '<S-TAB>',
        function()
          require('harpoon'):list():prev()
        end,
        desc = '[harpoon] Previous buffer',
      },
      {
        '<TAB>',
        function()
          require('harpoon'):list():next()
        end,
        desc = '[harpoon] Next buffer',
      },
      {
        '<leader>bd',
        function()
          require('harpoon'):list():clear()
        end,
        desc = '[harpoon] file',
      },
      {
        '<leader>mm',
        function()
          local harpoon = require 'harpoon'
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = '[harpoon] quick menu',
      },
    },
  },

  {
    'akinsho/bufferline.nvim',
    event = 'BufEnter',
    keys = {
      { '<leader>bp', '<Cmd>BufferLineTogglePin<CR>', desc = 'Toggle buffer pin' },
      { '<leader>bd', '<Cmd>BufferLineGroupClose ungrouped<CR>', desc = 'Delete non-pinned buffers' },
      { '<S-TAB>', ':BufferLineCyclePrev<cr>', desc = 'Previous buffer' },
      { '<TAB>', ':BufferLineCycleNext<cr>', desc = 'Next buffer' },
    },
    config = function()
      local opts = {
        options = {
          offsets = { { filetype = 'NvimTree', text = '', padding = 1 } },
          groups = {
            items = {
              require('bufferline.groups').builtin.pinned:with { icon = '' },
            },
          },
          diagnostics = 'nvim_lsp',
          always_show_bufferline = true,
          modified_icon = '',
          numbers = 'none',
          show_close_icon = false,
          left_trunc_marker = '',
          right_trunc_marker = '',
          max_name_length = 16,
          max_prefix_length = 13,
          tab_size = 20,
          show_tab_indicators = true,
          enforce_regular_tabs = false,
          view = 'multiwindow',
          show_buffer_close_icons = true,
          -- separator_style = { "", "" },
          separator_style = 'slant',
          indicator = {
            icon = ' ',
            style = 'icon',
          },
          pinned_icon = '',
          custom_filter = function(buf_number)
            -- Func to filter out our managed/persistent split terms
            local present_type, type = pcall(function()
              return vim.api.nvim_buf_get_var(buf_number, 'term_type')
            end)

            if present_type then
              if type == 'vert' then
                return false
              elseif type == 'hori' then
                return false
              end
              return true
            end

            return true
          end,
        },
      }
      require('bufferline').setup(opts)
    end,
  },

  -- file explorer
  {
    'kyazdani42/nvim-tree.lua',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '<leader>ft', ':NvimTreeToggle<cr>', desc = 'File tree' },
    },
    opts = {
      on_attach = function(bufnr)
        local api = require 'nvim-tree.api'

        local function opts(desc)
          return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        -- Default mappings. Feel free to modify or remove as you wish.
        --
        -- BEGIN_DEFAULT_ON_ATTACH
        vim.keymap.set('n', '<C-]>', api.tree.change_root_to_node, opts 'CD')
        vim.keymap.set('n', '<C-e>', api.node.open.replace_tree_buffer, opts 'Open: In Place')
        vim.keymap.set('n', '<C-k>', api.node.show_info_popup, opts 'Info')
        vim.keymap.set('n', '<C-r>', api.fs.rename_sub, opts 'Rename: Omit Filename')
        vim.keymap.set('n', '<C-t>', api.node.open.tab, opts 'Open: New Tab')
        vim.keymap.set('n', '<C-v>', api.node.open.vertical, opts 'Open: Vertical Split')
        vim.keymap.set('n', '<C-x>', api.node.open.horizontal, opts 'Open: Horizontal Split')
        vim.keymap.set('n', '<BS>', api.node.navigate.parent_close, opts 'Close Directory')
        vim.keymap.set('n', '<CR>', api.node.open.edit, opts 'Open')
        vim.keymap.set('n', '<Tab>', api.node.open.preview, opts 'Open Preview')
        vim.keymap.set('n', '>', api.node.navigate.sibling.next, opts 'Next Sibling')
        vim.keymap.set('n', '<', api.node.navigate.sibling.prev, opts 'Previous Sibling')
        vim.keymap.set('n', '.', api.node.run.cmd, opts 'Run Command')
        vim.keymap.set('n', '-', api.tree.change_root_to_parent, opts 'Up')
        vim.keymap.set('n', 'a', api.fs.create, opts 'Create')
        vim.keymap.set('n', 'bmv', api.marks.bulk.move, opts 'Move Bookmarked')
        vim.keymap.set('n', 'B', api.tree.toggle_no_buffer_filter, opts 'Toggle No Buffer')
        vim.keymap.set('n', 'c', api.fs.copy.node, opts 'Copy')
        vim.keymap.set('n', 'C', api.tree.toggle_git_clean_filter, opts 'Toggle Git Clean')
        vim.keymap.set('n', '[c', api.node.navigate.git.prev, opts 'Prev Git')
        vim.keymap.set('n', ']c', api.node.navigate.git.next, opts 'Next Git')
        vim.keymap.set('n', 'd', api.fs.remove, opts 'Delete')
        vim.keymap.set('n', 'D', api.fs.trash, opts 'Trash')
        vim.keymap.set('n', 'E', api.tree.expand_all, opts 'Expand All')
        vim.keymap.set('n', 'e', api.fs.rename_basename, opts 'Rename: Basename')
        vim.keymap.set('n', ']e', api.node.navigate.diagnostics.next, opts 'Next Diagnostic')
        vim.keymap.set('n', '[e', api.node.navigate.diagnostics.prev, opts 'Prev Diagnostic')
        vim.keymap.set('n', 'F', api.live_filter.clear, opts 'Clean Filter')
        vim.keymap.set('n', 'f', api.live_filter.start, opts 'Filter')
        vim.keymap.set('n', 'g?', api.tree.toggle_help, opts 'Help')
        vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, opts 'Copy Absolute Path')
        vim.keymap.set('n', 'H', api.tree.toggle_hidden_filter, opts 'Toggle Dotfiles')
        vim.keymap.set('n', 'I', api.tree.toggle_gitignore_filter, opts 'Toggle Git Ignore')
        vim.keymap.set('n', 'J', api.node.navigate.sibling.last, opts 'Last Sibling')
        vim.keymap.set('n', 'K', api.node.navigate.sibling.first, opts 'First Sibling')
        vim.keymap.set('n', 'm', api.marks.toggle, opts 'Toggle Bookmark')
        vim.keymap.set('n', 'o', api.node.open.edit, opts 'Open')
        vim.keymap.set('n', 'O', api.node.open.no_window_picker, opts 'Open: No Window Picker')
        vim.keymap.set('n', 'p', api.fs.paste, opts 'Paste')
        vim.keymap.set('n', 'P', api.node.navigate.parent, opts 'Parent Directory')
        vim.keymap.set('n', 'q', api.tree.close, opts 'Close')
        vim.keymap.set('n', 'r', api.fs.rename, opts 'Rename')
        vim.keymap.set('n', 'R', api.tree.reload, opts 'Refresh')
        vim.keymap.set('n', 's', api.node.run.system, opts 'Run System')
        vim.keymap.set('n', 'S', api.tree.search_node, opts 'Search')
        vim.keymap.set('n', 'U', api.tree.toggle_custom_filter, opts 'Toggle Hidden')
        vim.keymap.set('n', 'W', api.tree.collapse_all, opts 'Collapse')
        vim.keymap.set('n', 'x', api.fs.cut, opts 'Cut')
        vim.keymap.set('n', 'y', api.fs.copy.filename, opts 'Copy Name')
        vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts 'Copy Relative Path')
        vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit, opts 'Open')
        vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, opts 'CD')
        -- END_DEFAULT_ON_ATTACH

        -- Mappings migrated from view.mappings.list
        --
        -- You will need to insert "your code goes here" for any mappings with a custom action_cb
        vim.keymap.set('n', '<CR>', api.node.open.edit, opts 'Open')
        vim.keymap.set('n', 'o', api.node.open.edit, opts 'Open')
        vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit, opts 'Open')
        vim.keymap.set('n', 'l', api.node.open.edit, opts 'Open')
        vim.keymap.set('n', '<BS>', api.node.navigate.parent_close, opts 'Close Directory')
        vim.keymap.set('n', 'h', api.node.navigate.parent_close, opts 'Close Directory')
      end,
      filesystem_watchers = {
        ignore_dirs = {
          'node_modules',
        },
      },
      auto_reload_on_write = true,
      disable_netrw = true,
      hijack_cursor = true,
      hijack_netrw = true,
      hijack_unnamed_buffer_when_opening = false,
      sort_by = 'name',
      update_cwd = true,
      view = {
        width = 40,
        side = 'left',
        preserve_window_proportions = false,
        number = false,
        relativenumber = false,
        signcolumn = 'yes',
      },
      renderer = {
        highlight_git = true,
        add_trailing = false, -- append a trailing slash to folder names
        highlight_opened_files = 'icon',
        indent_markers = {
          enable = true,
          icons = {
            corner = '└',
            edge = '│',
            none = ' ',
          },
        },
        icons = {
          webdev_colors = true,
          git_placement = 'signcolumn',
          show = {
            folder = true,
            file = true,
            git = true,
            folder_arrow = false,
          },
          glyphs = {
            default = '',
            symlink = '',
            git = {
              deleted = 'D',
              ignored = '◌',
              renamed = 'R',
              staged = 'M',
              unmerged = '',
              unstaged = 'M',
              untracked = 'U',
            },
            folder = {
              default = '',
              empty = '',
              empty_open = '',
              open = '',
              symlink = '',
              symlink_open = '',
            },
          },
        },
      },
      hijack_directories = {
        enable = true,
        auto_open = true,
      },
      update_focused_file = {
        enable = true,
        update_cwd = false,
        ignore_list = {},
      },
      system_open = {
        cmd = '',
        args = {},
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
        icons = {
          hint = '',
          info = '',
          warning = '',
          error = '',
        },
      },
      filters = {
        dotfiles = true,
        custom = {},
        exclude = {},
      },
      git = {
        enable = true,
        ignore = false,
        timeout = 400,
      },
      actions = {
        use_system_clipboard = true,
        change_dir = {
          enable = true,
          global = false,
          restrict_above_cwd = false,
        },
        open_file = {
          quit_on_open = true,
          resize_window = false,
          window_picker = {
            enable = true,
            chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
            exclude = {
              filetype = { 'notify', 'packer', 'qf', 'diff', 'fugitive', 'fugitiveblame' },
              buftype = { 'nofile', 'terminal', 'help' },
            },
          },
        },
      },
    },
    config = function(_, opts)
      require('nvim-tree').setup(opts)
      fg('NvimTreeEmptyFolderName', Colors.FOREGROUND)
      fg('NvimTreeEndOfBuffer', Colors.BLACK)
      fg('NvimTreeFolderIcon', Colors.FOREGROUND)
      fg('NvimTreeFolderName', Colors.ACCENT)
      fg('NvimTreeIndentMarker', Colors.GREY)
      bg('NvimTreeNormal', Colors.BLACK)
      bg('NvimTreeNormalNC', Colors.BLACK)
      fg('NvimTreeOpenedFolderName', Colors.WHITE)
      fg('NvimTreeRootFolder', Colors.BLACK)
      fg('NvimTreeStatuslineNc', Colors.BLACK)
      bg('NvimTreeStatuslineNc', Colors.BLACK)
      fg('NvimTreeVertSplit', Colors.BLACK)
      bg('NvimTreeVertSplit', Colors.BLACK)
      bg('NvimTreeWindowPicker', Colors.GREY)
      fg('NvimTreeWindowPicker', Colors.WHITE)
      -- git
      fg('NvimTreeGitIgnored', Colors.GREY)
      fg('NvimTreeGitNew', Colors.GREEN)
      fg('NvimTreeGitRenamed', Colors.PURPLE)
      fg('NvimTreeGitDirty', Colors.BLUE)
    end,
  },

  -- Navigation
  -- Flash enhances the built-in search functionality by showing labels
  -- at the end of each match, letting you quickly jump to a specific
  -- location.
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    keys = {
      {
        'f',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash',
      },
      {
        'F',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
      },
    },
    opts = {
      search = {
        multi_window = true, -- search in multiple windows
      },
      jump = {
        jumplist = true, -- save in jumplist
      },
      modes = {
        char = {
          enabled = false, -- disable all default keymaps
        },
      },
    },
    config = function(_, opts)
      require('flash').setup(opts)
      fg('FlashMatch', Colors.WHITE)
      bg('FlashMatch', Colors.PURPLE)
      fg('FlashLabel', Colors.BLACK)
      bg('FlashLabel', Colors.PURPLE)
    end,
  },

  -- Automatically highlights/underlines other instances of the word under your
  -- cursor. This works with LSP, Treesitter, and regexp matching to find the
  -- other instances.
  {
    'RRethy/vim-illuminate',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      delay = 0,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { 'lsp' },
      },
    },
    config = function(_, opts)
      require('illuminate').configure(opts)

      local function map(key, dir, buffer)
        vim.keymap.set('n', key, function()
          require('illuminate')['goto_' .. dir .. '_reference'](false)
        end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. ' Reference', buffer = buffer })
      end

      map(']]', 'next')
      map('[[', 'prev')

      -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          map(']]', 'next', buffer)
          map('[[', 'prev', buffer)
        end,
      })
    end,
    keys = {
      { ']]', desc = 'Next Reference' },
      { '[[', desc = 'Prev Reference' },
    },
  },

  -- Keymaps
  -- which-key helps you remember key bindings by showing a popup
  -- with the active keybindings of the command you started typing.
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    keys = {
      {
        '<leader>?',
        function()
          require('which-key').show { global = false }
        end,
        desc = 'Buffer Local Keymaps (which-key)',
      },
    },
    opts = {
      plugins = { spelling = true },
    },
    config = function(_, opts)
      local wk = require 'which-key'

      wk.setup(opts)
      wk.add {
        mode = { 'n', 'v' },
        { '<leader>a', group = 'ai assistant' },
        { '<leader>b', group = 'buffer' },
        { '<leader>c', group = 'code actions' },
        { '<leader>d', group = 'debugger' },
        -- { '<leader>e', group = 'xxx' },
        { '<leader>f', group = 'file/find' },
        { '<leader>g', group = 'git' },
        { '<leader>h', group = 'hunks' },
        -- { '<leader>i', group = 'xxx' },
        -- { '<leader>j', group = 'xxx' },
        -- { '<leader>k', group = 'xxx' },
        { '<leader>l', group = 'lsp' },
        { '<leader>m', group = 'marks' },
        { '<leader>n', group = 'notes' },
        -- { '<leader>o', group = 'xxx' },
        { '<leader>p', group = 'project' },
        -- { '<leader>q', group = 'xxx' },
        { '<leader>r', group = 'code runner' },
        -- { '<leader>s', group = 'xxx' },
        { '<leader>t', group = 'tests' },
        { '<leader>tw', group = 'watch' },
        { '<leader>u', group = 'utility' },
        -- { '<leader>v', group = 'xxx' },
        { '<leader>w', group = 'windows' },
        { '<leader>x', group = 'diagnostic' },
        -- { '<leader>y', group = 'xxx' },
        -- { '<leader>z', group = 'xxx' },
        { 'z', group = 'folds' },
      }
    end,
  },

  -- folds
  {
    'kevinhwang91/nvim-ufo',
    dependencies = 'kevinhwang91/promise-async',
    event = 'BufRead',
    keys = {
      {
        'zR',
        function()
          require('ufo').openAllFolds()
        end,
        { desc = 'Open all folds' },
      },
      {
        'zM',
        function()
          require('ufo').closeAllFolds()
        end,
        { desc = 'Close all folds' },
      },
      {
        'zr',
        function()
          require('ufo').openFoldsExceptKinds()
        end,
        { desc = 'Open folds except kinds' },
      },
      {
        'zm',
        function()
          require('ufo').closeFoldsWith()
        end,
        { desc = 'Close folds with' },
      },
      {
        'K',
        function()
          local winid = require('ufo').peekFoldedLinesUnderCursor()
          if not winid then
            -- choose one of coc.nvim and nvim lsp
            vim.lsp.buf.hover()
          end
        end,
      },
    },
    config = function()
      local fn = vim.fn

      local handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = ('  %d '):format(endLnum - lnum)
        local sufWidth = fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, 'MoreMsg' })
        return newVirtText
      end

      require('ufo').setup {
        fold_virt_text_handler = handler,
      }
    end,
  },

  {
    'luukvbaal/statuscol.nvim',
    config = function()
      local builtin = require 'statuscol.builtin'
      require('statuscol').setup {
        relculright = true,
        segments = {
          -- fold column
          { text = { builtin.foldfunc }, click = 'v:lua.ScFa' },
          -- sign column
          { sign = { name = { '.*' }, namespace = { '.*' }, maxwidth = 1, colwidth = 1 }, click = 'v:lua.ScSa' },
          -- number column
          { text = { builtin.lnumfunc }, click = 'v:lua.ScLa' },
          -- gitsigns
          {
            sign = { namespace = { 'gitsigns' }, name = { '.*' }, maxwidth = 1, colwidth = 1, auto = false },
            click = 'v:lua.ScSa',
          },
        },
      }
    end,
  },

  -- status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      {
        'letieu/harpoon-lualine',
        dependencies = {
          {
            'ThePrimeagen/harpoon',
            branch = 'harpoon2',
          },
        },
      },
    },
    opts = function()
      local conditions = {
        buffer_not_empty = function()
          return vim.fn.empty(vim.fn.expand '%:t') ~= 1
        end,
        hide_in_width = function()
          return vim.fn.winwidth(0) > 80
        end,
        check_git_workspace = function()
          local filepath = vim.fn.expand '%:p:h'
          local gitdir = vim.fn.finddir('.git', filepath .. ';')
          return gitdir and #gitdir > 0 and #gitdir < #filepath
        end,
      }

      -- Config
      local config = {
        options = {
          globalstatus = true,
          -- Disable sections and component separators
          component_separators = '',
          section_separators = '',
          theme = {
            -- We are going to use lualine_c an lualine_x as left and
            -- right section. Both are highlighted by c theme .  So we
            -- are just setting default looks o statusline
            normal = { c = { fg = Colors.FOREGROUND, bg = Colors.GREY } },
            inactive = { c = { fg = Colors.FOREGROUND, bg = Colors.GREY } },
          },
        },
        sections = {
          -- these are to remove the defaults
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          -- These will be filled later
          lualine_c = {},
          lualine_x = {},
        },
        inactive_sections = {
          -- these are to remove the defaults
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          lualine_c = {},
          lualine_x = {},
        },
      }

      -- Inserts a component in lualine_c at left section
      local function ins_left(component)
        table.insert(config.sections.lualine_c, component)
      end

      -- Inserts a component in lualine_x at right section
      local function ins_right(component)
        table.insert(config.sections.lualine_x, component)
      end

      -- bookend
      ins_left {
        function()
          return '▊'
        end,
        color = { fg = Colors.BLUE }, -- Sets highlighting of component
        padding = { left = 0, right = 1 }, -- We don't need space before this
      }

      -- mode
      ins_left {
        -- mode component
        function()
          -- auto change color according to neovims mode
          local mode_color = {
            n = Colors.RED,
            i = Colors.GREEN,
            v = Colors.BLUE,
            [''] = Colors.BLUE,
            V = Colors.BLUE,
            c = Colors.PURPLE,
            no = Colors.RED,
            s = Colors.ORANGE,
            S = Colors.ORANGE,
            ic = Colors.YELLOW,
            R = Colors.PURPLE,
            Rv = Colors.PURPLE,
            cv = Colors.RED,
            ce = Colors.RED,
            r = Colors.ACCENT,
            rm = Colors.ACCENT,
            ['r?'] = Colors.ACCENT,
            ['!'] = Colors.RED,
            t = Colors.RED,
          }
          vim.api.nvim_command('hi! LualineMode guifg=' .. mode_color[vim.fn.mode()] .. ' guibg=' .. Colors.GREY)
          return ''
        end,
        color = 'LualineMode',
        padding = { right = 1 },
      }

      -- git branch
      ins_left {
        'branch',
        icon = '',
        color = { fg = Colors.PURPLE, gui = 'bold' },
      }

      -- file name
      ins_left {
        'filename',
        cond = conditions.buffer_not_empty,
        symbols = {
          modified = '●', -- Text to show when the file is modified.
          readonly = '', -- Text to show when the file is non-modifiable or readonly.
          unnamed = '', -- Text to show for unnamed buffers.
          newfile = '', -- Text to show for newly created file before first write
        },
        color = function()
          -- Return red color for modified files, accent color otherwise
          return { fg = vim.bo.modified and Colors.RED or Colors.ACCENT, gui = 'bold' }
        end,
      }

      -- git diff
      ins_left {
        'diff',
        -- Is it me or the symbol for modified us really weird
        symbols = { added = ' ', modified = '󰝤 ', removed = ' ' },
        diff_color = {
          added = { fg = Colors.GREEN },
          modified = { fg = Colors.BLUE },
          removed = { fg = Colors.RED },
        },
        cond = conditions.hide_in_width,
      }

      -- Middle Section
      ins_left {
        '%=',
      }
      ins_left {
        'harpoon2',
      }

      -- file size
      ins_right {
        -- filesize component
        'filesize',
        cond = conditions.buffer_not_empty,
      }

      -- location
      ins_right { 'location' }

      -- progress
      ins_right { 'progress', color = { fg = Colors.FOREGROUND, gui = 'bold' } }

      -- lsp server
      ins_right {
        function()
          local msg = ''
          local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
          local clients = vim.lsp.get_clients()
          if next(clients) == nil then
            return msg
          end
          for _, client in ipairs(clients) do
            local filetypes = client.config.filetypes
            if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
              return client.name
            end
          end
          return msg
        end,
        icon = '',
        color = { fg = Colors.white, gui = 'bold' },
      }

      -- diagnostics
      ins_right {
        'diagnostics',
        sources = { 'nvim_diagnostic' },
        symbols = { error = ' ', warn = ' ', info = ' ' },
        diagnostics_color = {
          color_error = { fg = Colors.RED },
          color_warn = { fg = Colors.YELLOW },
          color_info = { fg = Colors.BLUE },
        },
      }

      -- bookend
      ins_right {
        function()
          return '▊'
        end,
        color = { fg = Colors.BLUE },
        padding = { left = 1 },
      }

      return config
    end,
  },

  -- diagnostics
  {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'BufEnter',
    keys = {
      {
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Diagnostics (Trouble)',
      },
      {
        '<leader>xX',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = 'Buffer Diagnostics (Trouble)',
      },
      {
        '<leader>cs',
        '<cmd>Trouble symbols toggle focus=false<cr>',
        desc = 'Symbols (Trouble)',
      },
      {
        '<leader>cl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = 'LSP Definitions / references / ... (Trouble)',
      },
      {
        '<leader>xl',
        '<cmd>Trouble loclist toggle<cr>',
        desc = 'Location List (Trouble)',
      },
      {
        '<leader>xq',
        '<cmd>Trouble qflist toggle<cr>',
        desc = 'Quickfix List (Trouble)',
      },
    },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },

  -- peek lines
  {
    'nacro90/numb.nvim',
    config = true,
  },

  -- toggle rspec tests
  {
    'HoganMcDonald/rails-rspec-toggle.nvim',
    dev = true,
    keys = {
      {
        '<leader>tt',
        function()
          require('rails-rspec-toggle').toggle()
        end,
        desc = 'Toggle rspec test file',
      },
    },
    opts = {
      spec_directory = 'spec',
    },
    config = function(_, opts)
      require('rails-rspec-toggle').setup(opts)
    end,
  },
}
