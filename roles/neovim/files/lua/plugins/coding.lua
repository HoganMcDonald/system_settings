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

      -- sources
      {
        'saadparwaiz1/cmp_luasnip',
        'hrsh7th/cmp-nvim-lua',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-emoji',
      },
    },
    opts = function()
      vim.api.nvim_set_hl(0, 'CmpGhostText', { link = 'Comment', default = true })
      local cmp = require 'cmp'
      local defaults = require 'cmp.config.default'()
      return {

        completion = {
          completeopt = 'menu,menuone,noinsert',
        },

        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
          ['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm { select = true }, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ['<S-CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ['<C-CR>'] = function(fallback)
            cmp.abort()
            fallback()
          end,
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif require('luasnip').expand_or_jumpable() then
              vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-expand-or-jump', true, true, true), '')
            else
              fallback()
            end
          end, {
            'i',
            's',
          }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif require('luasnip').jumpable(-1) then
              vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-jump-prev', true, true, true), '')
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
          { name = 'codeium' },
          { name = 'nvim_lsp' },
          { name = 'path' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'nvim_lua' },
          { name = 'emoji' },
        },

        formatting = {
          format = function(_, item)
            local icons = require('util.cmp').icons
            if icons[item.kind] then
              item.kind = icons[item.kind] .. item.kind
            end
            return item
          end,
        },

        experimental = {
          ghost_text = {
            hl_group = 'CmpGhostText',
          },
        },

        sorting = defaults.sorting,
      }
    end,
    config = function(_, opts)
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
            timeout_ms = 500,
            lsp_fallback = true,
          }
        end,
        desc = 'Format buffer',
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform will run multiple formatters sequentially
        python = { 'isort', 'black' },
        -- Use a sub-list to run only the first available formatter
        javascript = { { 'prettierd', 'prettier' } },
        typescript = { { 'prettierd', 'prettier' } },
        javascriptreact = { { 'prettierd', 'prettier' } },
        typescriptreact = { { 'prettierd', 'prettier' } },
      },
    },
  },

  -- test runner
  {
    'vim-test/vim-test',
    keys = {
      { '<leader>tf', ':TestFile<cr>', desc = 'Run test file' },
      { '<leader>tn', ':TestNearest<cr>', desc = 'Run nearest test' },
      { '<leader>tl', ':TestLast<cr>', desc = 'Re-run last test' },
      { '<leader>ta', ':TestSuite<cr>', desc = 'Run entire test suite' },
    },
    config = function()
      vim.g['test#strategy'] = 'neovim'
    end,
  },

  -- color column but only when you need it
  {
    'm4xshen/smartcolumn.nvim',
    event = 'BufEnter',
    opts = {
      colorcolumn = '80',
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

  -- indent guides for Neovim
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {},
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
}
