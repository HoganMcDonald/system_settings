local Colors = require 'util.colors'
local bg = require('util.highlight').bg

return {
  -- completion
  {
    'hrsh7th/nvim-cmp',
    version = false, -- last release is way too old
    event = 'InsertEnter',
    dependencies = {
      {
        -- snippet plugin
        'L3MON4D3/LuaSnip',
        dependencies = 'rafamadriz/friendly-snippets',
        opts = { history = true, updateevents = 'TextChanged,TextChangedI' },
        config = function(_, opts)
          require('luasnip').config.set_config(opts)

          -- vscode format
          require('luasnip.loaders.from_vscode').lazy_load()
          require('luasnip.loaders.from_vscode').lazy_load { paths = vim.g.vscode_snippets_path or '' }

          -- snipmate format
          require('luasnip.loaders.from_snipmate').load()
          require('luasnip.loaders.from_snipmate').lazy_load { paths = vim.g.snipmate_snippets_path or '' }

          -- lua format
          require('luasnip.loaders.from_lua').load()
          require('luasnip.loaders.from_lua').lazy_load { paths = vim.g.lua_snippets_path or '' }

          vim.api.nvim_create_autocmd('InsertLeave', {
            callback = function()
              if
                require('luasnip').session.current_nodes[vim.api.nvim_get_current_buf()]
                and not require('luasnip').session.jump_active
              then
                require('luasnip').unlink_current()
              end
            end,
          })
        end,
      },

      -- autopairing of (){}[] etc
      {
        'windwp/nvim-autopairs',
        opts = {
          fast_wrap = {},
          disable_filetype = { 'TelescopePrompt', 'vim' },
        },
        config = function(_, opts)
          require('nvim-autopairs').setup(opts)

          -- setup cmp for autopairs
          local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
          require('cmp').event:on('confirm_done', cmp_autopairs.on_confirm_done())
        end,
      },

      {
        'kawre/neotab.nvim',
        event = 'InsertEnter',
        opts = {
          -- configuration goes here
        },
      },

      -- sources
      {
        'saadparwaiz1/cmp_luasnip',
        'hrsh7th/cmp-nvim-lua',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-emoji',
        'roobert/tailwindcss-colorizer-cmp.nvim',
      },
    },
    opts = function()
      vim.api.nvim_set_hl(0, 'CmpGhostText', { link = 'Comment', default = true })
      local cmp = require 'cmp'
      local icons = require('util.icons').icons
      local types = require 'cmp.types'
      local auto_select = true
      local luasnip = require 'luasnip'
      require('luasnip/loaders/from_vscode').lazy_load()
      require('luasnip').filetype_extend('typescriptreact', { 'html' })

      local check_backspace = function()
        local col = vim.fn.col '.' - 1
        return col == 0 or vim.fn.getline('.'):sub(col, col):match '%s'
      end

      return {
        -- configure any filetype to auto add brackets
        auto_brackets = {},

        completion = {
          completeopt = 'menu,menuone,noinsert' .. (auto_select and '' or ',noselect'),
        },

        preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,

        mapping = cmp.mapping.preset.insert {
          ['<C-k>'] = cmp.mapping(
            cmp.mapping.select_prev_item { behavior = types.cmp.SelectBehavior.Select },
            { 'i', 'c' }
          ),
          ['<C-j>'] = cmp.mapping(
            cmp.mapping.select_next_item { behavior = types.cmp.SelectBehavior.Select },
            { 'i', 'c' }
          ),
          ['<C-p>'] = cmp.mapping(
            cmp.mapping.select_prev_item { behavior = types.cmp.SelectBehavior.Select },
            { 'i', 'c' }
          ),
          ['<C-n>'] = cmp.mapping(
            cmp.mapping.select_next_item { behavior = types.cmp.SelectBehavior.Select },
            { 'i', 'c' }
          ),
          ['<C-h>'] = function()
            if cmp.visible_docs() then
              cmp.close_docs()
            else
              cmp.open_docs()
            end
          end,
          ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-1), { 'i', 'c' }),
          ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(1), { 'i', 'c' }),
          ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
          ['<C-e>'] = cmp.mapping {
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
          },
          -- Accept currently selected item. If none selected, `select` first item.
          -- Set `select` to `false` to only confirm explicitly selected items.
          ['<CR>'] = cmp.mapping.confirm { select = true },
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expandable() then
              luasnip.expand()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif check_backspace() then
              -- fallback()
              require('neotab').tabout()
            else
              require('neotab').tabout()
              -- fallback()
            end
          end, {
            'i',
            's',
          }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, {
            'i',
            's',
          }),
        },

        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },

        sources = cmp.config.sources {
          { name = 'copilot' },
          {
            name = 'nvim_lsp',
            entry_filter = function(entry, ctx)
              local kind = require('cmp.types.lsp').CompletionItemKind[entry:get_kind()]
              if kind == 'Snippet' and ctx.prev_context.filetype == 'java' then
                return false
              end

              if ctx.prev_context.filetype == 'markdown' then
                return true
              end

              if kind == 'Text' then
                return false
              end

              return true
            end,
          },
          { name = 'luasnip' },
          { name = 'cmp_tabnine' },
          { name = 'nvim_lua' },
          { name = 'buffer' },
          { name = 'path' },
          { name = 'calc' },
          { name = 'emoji' },
          { name = 'treesitter' },
          { name = 'crates' },
          { name = 'tmux' },
        },

        formatting = {
          fields = { 'kind', 'abbr', 'menu' },
          expandable_indicator = true,
          format = function(entry, vim_item)
            vim_item.kind = icons.kind[vim_item.kind]
            vim_item.menu = ({
              nvim_lsp = '',
              nvim_lua = '',
              luasnip = '',
              buffer = '',
              path = '',
              emoji = '',
            })[entry.source.name]

            if vim.tbl_contains({ 'nvim_lsp' }, entry.source.name) then
              local duplicates = {
                buffer = 1,
                path = 1,
                nvim_lsp = 0,
                luasnip = 1,
              }

              local duplicates_default = 0

              vim_item.dup = duplicates[entry.source.name] or duplicates_default
            end

            if vim.tbl_contains({ 'nvim_lsp' }, entry.source.name) then
              local words = {}
              for word in string.gmatch(vim_item.word, '[^-]+') do
                table.insert(words, word)
              end

              local color_name, color_number
              if
                words[2] == 'x'
                or words[2] == 'y'
                or words[2] == 't'
                or words[2] == 'b'
                or words[2] == 'l'
                or words[2] == 'r'
              then
                color_name = words[3]
                color_number = words[4]
              else
                color_name = words[2]
                color_number = words[3]
              end

              if color_name == 'white' or color_name == 'black' then
                local color
                if color_name == 'white' then
                  color = 'ffffff'
                else
                  color = '000000'
                end

                local hl_group = 'lsp_documentColor_mf_' .. color
                -- vim.api.nvim_set_hl(0, hl_group, { fg = "#" .. color, bg = "#" .. color })
                vim.api.nvim_set_hl(0, hl_group, { fg = '#' .. color, bg = 'NONE' })
                vim_item.kind_hl_group = hl_group

                -- make the color square 2 chars wide
                vim_item.kind = string.rep('▣', 1)

                return vim_item
              elseif #words < 3 or #words > 4 then
                -- doesn't look like this is a tailwind css color
                return vim_item
              end

              if not color_name or not color_number then
                return vim_item
              end

              local color_index = tonumber(color_number)
              local tailwindcss_colors = require('tailwindcss-colorizer-cmp.colors').TailwindcssColors

              if not tailwindcss_colors[color_name] then
                return vim_item
              end

              if not tailwindcss_colors[color_name][color_index] then
                return vim_item
              end

              local color = tailwindcss_colors[color_name][color_index]

              local hl_group = 'lsp_documentColor_mf_' .. color
              -- vim.api.nvim_set_hl(0, hl_group, { fg = "#" .. color, bg = "#" .. color })
              vim.api.nvim_set_hl(0, hl_group, { fg = '#' .. color, bg = 'NONE' })

              vim_item.kind_hl_group = hl_group

              -- make the color square 2 chars wide
              vim_item.kind = string.rep('▣', 1)

              -- return vim_item
            end

            if entry.source.name == 'copilot' then
              vim_item.kind = icons.git.Octoface
              vim_item.kind_hl_group = 'CmpItemKindCopilot'
            end

            if entry.source.name == 'cmp_tabnine' then
              vim_item.kind = icons.misc.Robot
              vim_item.kind_hl_group = 'CmpItemKindTabnine'
            end

            if entry.source.name == 'crates' then
              vim_item.kind = icons.misc.Package
              vim_item.kind_hl_group = 'CmpItemKindCrate'
            end

            if entry.source.name == 'lab.quick_data' then
              vim_item.kind = icons.misc.CircuitBoard
              vim_item.kind_hl_group = 'CmpItemKindConstant'
            end

            if entry.source.name == 'emoji' then
              vim_item.kind = icons.misc.Smiley
              vim_item.kind_hl_group = 'CmpItemKindEmoji'
            end

            return vim_item
          end,
        },

        confirm_opts = {
          behavior = cmp.ConfirmBehavior.Replace,
          select = false,
        },

        view = {
          entries = {
            name = 'custom',
            selection_order = 'top_down',
          },
          docs = {
            auto_open = true,
          },
        },

        window = {
          completion = {
            winhighlight = 'Normal:Pmenu,CursorLine:PmenuSel,FloatBorder:FloatBorder,Search:None',
            col_offset = -3,
            side_padding = 1,
            scrollbar = true,
            scrolloff = 8,
          },
        },

        experimental = {
          ghost_text = false,
        },
      }
    end,
    config = function(_, opts)
      require('tailwindcss-colorizer-cmp').setup {
        color_square_width = 2,
      }

      vim.api.nvim_set_hl(0, 'CmpItemKindCopilot', { fg = Colors.BLUE })
      vim.api.nvim_set_hl(0, 'CmpItemKindTabnine', { fg = Colors.MAGENTA })
      vim.api.nvim_set_hl(0, 'CmpItemKindCrate', { fg = Colors.RED })
      vim.api.nvim_set_hl(0, 'CmpItemKindEmoji', { fg = Colors.ACCENT })

      for _, source in ipairs(opts.sources) do
        source.group_index = source.group_index or 1
      end
      require('cmp').setup(opts)
    end,
  },

  -- formatter
  {
    'stevearc/conform.nvim',
    keys = {
      {
        '<leader>bf',
        function()
          require('conform').format {
            timeout_ms = 1000,
            lsp_fallback = true,
          }
        end,
        desc = 'Format buffer',
      },
    },
    opts = {
      log_level = vim.log.levels.DEBUG,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform will run multiple formatters sequentially
        python = { 'isort', 'black' },
        ruby = { 'rubocop', 'solargraph' },
        -- Use a sub-list to run only the first available formatter
        javascript = { 'biome', 'prettierd', stop_after_first = true },
        typescript = { 'biome', 'prettierd', stop_after_first = true },
        javascriptreact = { 'prettierd', 'biome', stop_after_first = true },
        typescriptreact = { 'prettierd', 'biome', stop_after_first = true },
      },
      formatters = {
        rubocop = {
          args = { '--server', '--auto-correct-all', '--stderr', '--force-exclusion', '--stdin', '$FILENAME' },
        },
      },
    },
  },

  -- test runner
  -- vim-test because rspec adapter doesn't support dap
  {
    'vim-test/vim-test',
    keys = {
      {
        '<leader>td',
        ':TestNearest<CR>',
        desc = '[vim-test] debug nearest',
      },
    },
    config = function()
      vim.g['test#strategy'] = 'neovim'
    end,
  },

  -- neotest
  {
    'nvim-neotest/neotest',
    lazy = false,
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',

      -- providers
      'olimorris/neotest-rspec',
      'nvim-neotest/neotest-vim-test',
      'nvim-neotest/neotest-jest',
      'marilari88/neotest-vitest',
    },
    keys = {
      {
        '<leader>tn',
        function()
          require('neotest').run.run()
        end,
        desc = '[neotest] Test nearest',
      },
      {
        '<leader>tf',
        function()
          require('neotest').run.run(vim.fn.expand '%')
        end,
        desc = '[neotest] Test file',
      },
      {
        '<leader>tl',
        function()
          require('neotest').run.run_last()
        end,
        desc = '[neotest] Run last test',
      },
      {
        '<leader>to',
        function()
          require('neotest').output_panel.open()
        end,
        desc = '[neotest] Open test output',
      },
      {
        '<leader>ts',
        function()
          require('neotest').summary.toggle()
        end,
        desc = '[neotest] Toggle test summary',
      },
      {
        '<leader>twn',
        function()
          require('neotest').watch.toggle()
        end,
        desc = '[neotest] Watch nearest test',
      },
      {
        '<leader>twf',
        function()
          require('neotest').watch.toggle { vim.fn.expand '%' }
        end,
        desc = '[neotest] Watch file',
      },
      {
        '<leader>twa',
        function()
          require('neotest').watch.toggle { suite = true }
        end,
        desc = '[neotest] Watch all tests',
      },
      {
        '<leader>twa',
        function()
          require('neotest').watch.stop()
        end,
        desc = '[neotest] Stop watching',
      },
    },
    config = function()
      require('neotest').setup {
        log_level = vim.log.levels.DEBUG,
        icons = {
          expanded = '',
          child_prefix = '',
          child_indent = '',
          final_child_prefix = '',
          non_collapsible = '',
          collapsed = '',

          passed = '',
          running = '',
          failed = '',
          unknown = '',
          skipped = '',
        },
        floating = {
          border = 'single',
          max_height = 0.8,
          max_width = 0.9,
        },
        summary = {
          mappings = {
            attach = 'a',
            expand = { '<CR>', '<2-LeftMouse>' },
            expand_all = 'e',
            jumpto = 'i',
            output = 'o',
            run = 'r',
            short = 'O',
            stop = 'u',
          },
        },
        adapters = {
          require 'neotest-rspec',
          require 'neotest-jest',
          require 'neotest-vitest',
          require 'neotest-vim-test' {
            ignore_filetypes = { 'ruby', 'javascript', 'typescript', 'typescriptreact', 'javascriptreact' },
          },
        },
      }
    end,
  },

  -- color column but only when you need it
  {
    'm4xshen/smartcolumn.nvim',
    event = 'BufEnter',
    opts = {
      colorcolumn = '120',
      disabled_filetypes = {
        'help',
        'text',
        'markdown',
        'dashboard',
        'NvimTree',
        'Lazy',
        'mason',
        'help',
        'eruby',
      },
      custom_colorcolumn = {},
      scope = 'window',
    },
    config = function(_, opts)
      require('smartcolumn').setup(opts)
      bg('ColorColumn', Colors.GREY)
    end,
  },

  -- comments
  {
    'echasnovski/mini.comment',
    dependencies = {
      { 'JoosepAlviste/nvim-ts-context-commentstring', lazy = true },
    },
    event = 'VeryLazy',
    opts = {
      options = {
        custom_commentstring = function()
          return require('ts_context_commentstring.internal').calculate_commentstring() or vim.bo.commentstring
        end,
      },
    },
  },

  -- surround
  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup {
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },

  -- todo comments
  {
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },

  -- macros
  {
    'chrisgrieser/nvim-recorder',
    dependencies = 'rcarriga/nvim-notify',
    opts = {},
  },

  {
    'rest-nvim/rest.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        table.insert(opts.ensure_installed, 'http')
      end,
    },
    cmd = 'Rest',
    keys = {
      {
        '<leader>rr',
        '<cmd>Rest run<cr>',
        desc = '[rest] run current request',
      },
      {
        '<leader>ro',
        '<cmd>Rest open<cr>',
        desc = '[rest] open request viewer',
      },
      {
        '<leader>re',
        '<cmd>Rest env select<cr>',
        desc = '[rest] select env file',
      },
      {
        '<leader>rl',
        '<cmd>Rest last<cr>',
        desc = '[rest] run the most recent request',
      },
    },
  },
}
