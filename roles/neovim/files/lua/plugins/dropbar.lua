return {
  {
    'Bekaboo/dropbar.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim',
    },
    keys = {
      {
        '<leader>;',
        function()
          require('dropbar.api').pick()
        end,
        desc = 'Pick symbols in winbar',
      },
      {
        '[;',
        function()
          require('dropbar.api').goto_context_start()
        end,
        desc = 'Go to start of current context',
      },
      {
        '];',
        function()
          require('dropbar.api').select_next_context()
        end,
        desc = 'Select next context',
      },
    },
    opts = {
      general = {
        enable = function(buf, win)
          -- Disable in floating windows
          local config = vim.api.nvim_win_get_config(win)
          if config.relative ~= '' then
            return false
          end

          -- Disable in special buffer types
          local buftype = vim.bo[buf].buftype
          if buftype ~= '' and buftype ~= 'terminal' then
            return false
          end

          -- Disable in specific filetypes
          local filetype = vim.bo[buf].filetype
          local excluded_filetypes = {
            'snacks_dashboard',
            'snacks_notif',
            'snacks_terminal',
            'snacks_win',
            'prompt',
            'TelescopePrompt',
            'neo-tree',
            'NvimTree',
            'fugitive',
            'help',
            'qf',
            'quickfix',
            'dashboard',
            'alpha',
            'ministarter',
            'lazy',
            'mason',
            'notify',
            'noice',
            'toggleterm',
          }
          for _, ft in ipairs(excluded_filetypes) do
            if filetype == ft then
              return false
            end
          end

          return true
        end,
        attach_events = {
          'OptionSet',
          'BufWinEnter',
          'BufWritePost',
        },
      },
      icons = {
        kinds = {
          use_devicons = true,
        },
        ui = {
          bar = {
            separator = ' › ',
            extends = '…',
          },
          menu = {
            separator = ' ',
            indicator = ' ',
          },
        },
      },
      bar = {
        sources = function(buf, _)
          local sources = require('dropbar.sources')
          local utils = require('dropbar.utils')
          if vim.bo[buf].ft == 'markdown' then
            return {
              sources.path,
              sources.markdown,
            }
          end
          if vim.bo[buf].buftype == 'terminal' then
            return {
              sources.terminal,
            }
          end
          return {
            sources.path,
            utils.source.fallback({
              sources.lsp,
              sources.treesitter,
            }),
          }
        end,
      },
      menu = {
        preview = true,
        quick_navigation = true,
        entry = {
          padding = {
            left = 1,
            right = 1,
          },
        },
        keymaps = {
          ['q'] = '<C-w>q',
          ['<Esc>'] = '<C-w>q',
          ['<LeftMouse>'] = function()
            local menu = require('dropbar.api').get_current_dropbar_menu()
            if not menu then
              return
            end
            local mouse = vim.fn.getmousepos()
            local clicked_menu = require('dropbar.api').get_dropbar_menu(mouse.winid)
            if clicked_menu then
              clicked_menu:click_at({ mouse.line, mouse.column }, nil, 1, 'l')
            end
          end,
          ['<CR>'] = function()
            local menu = require('dropbar.api').get_current_dropbar_menu()
            if not menu then
              return
            end
            local cursor = vim.api.nvim_win_get_cursor(menu.win)
            local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
            if component then
              menu:click_on(component, nil, 1, 'l')
            end
          end,
          ['i'] = function()
            local menu = require('dropbar.api').get_current_dropbar_menu()
            if not menu then
              return
            end
            menu:fuzzy_find_open()
          end,
        },
      },
    },
  },
}
