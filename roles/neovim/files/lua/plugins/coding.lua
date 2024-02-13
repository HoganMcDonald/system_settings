local Colors = require('util.colors')
local bg = require('util.highlight').bg

return {
  -- completion
  -- {
  --   "hrsh7th/nvim-cmp",
  --   event = "InsertEnter",
  --   dependencies = {
  --     -- {
  --     --   -- snippet plugin
  --     --   "L3MON4D3/LuaSnip",
  --     --   dependencies = "rafamadriz/friendly-snippets",
  --     --   opts = { history = true, updateevents = "TextChanged,TextChangedI" },
  --     --   config = function(_, opts)
  --     --     require("plugins.configs.others").luasnip(opts)
  --     --   end,
  --     -- },
  --
  --     -- autopairing of (){}[] etc
  --     {
  --       "windwp/nvim-autopairs",
  --       opts = {
  --         fast_wrap = {},
  --         disable_filetype = { "TelescopePrompt", "vim" },
  --       },
  --       config = function(_, opts)
  --         require("nvim-autopairs").setup(opts)
  --
  --         -- setup cmp for autopairs
  --         local cmp_autopairs = require "nvim-autopairs.completion.cmp"
  --         require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
  --       end,
  --     },
  --
  --     -- cmp sources plugins
  --     {
  --       "saadparwaiz1/cmp_luasnip",
  --       "hrsh7th/cmp-nvim-lua",
  --       "hrsh7th/cmp-nvim-lsp",
  --       "hrsh7th/cmp-buffer",
  --       "hrsh7th/cmp-path",
  --     },
  --   },
  --   opts = function()
  --     local cmp = require('cmp')
  --
  --     return {
  --       snippet = {
  --         -- REQUIRED - you must specify a snippet engine
  --         expand = function(args)
  --           vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
  --           -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
  --           -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
  --           -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
  --         end,
  --       },
  --       window = {
  --         -- completion = cmp.config.window.bordered(),
  --         -- documentation = cmp.config.window.bordered(),
  --       },
  --       mapping = cmp.mapping.preset.insert({
  --         ['<C-b>'] = cmp.mapping.scroll_docs(-4),
  --         ['<C-f>'] = cmp.mapping.scroll_docs(4),
  --         ['<C-Space>'] = cmp.mapping.complete(),
  --         ['<C-e>'] = cmp.mapping.abort(),
  --         ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  --       }),
  --       sources = cmp.config.sources({
  --         { name = 'nvim_lsp' },
  --         { name = 'vsnip' }, -- For vsnip users.
  --         -- { name = 'luasnip' }, -- For luasnip users.
  --         -- { name = 'ultisnips' }, -- For ultisnips users.
  --         -- { name = 'snippy' }, -- For snippy users.
  --       }, {
  --         { name = 'buffer' },
  --       })
  --     }
  --   end,
  --   config = function(_, opts)
  --     require('cmp').setup(opts)
  --   end,
  -- },
  {
    'ms-jpq/coq_nvim',
    branch = "coq",
    dependencies = {
      { "ms-jpq/coq.artifacts", branch = "artifacts" },
      { "neovim/nvim-lspconfig" },
    },
    event = 'BufEnter',
    build = function()
      vim.cmd('COQdeps')
    end,
    config = function()
      vim.g.coq_settings = {
        auto_start = "shut-up",
        display = {
          ghost_text = {
            enabled = true
          },
          pum = {
            source_context = { "(", ")" }
          }
        },
        keymap = {
          recommended = true,
          manual_complete = "<C-Space>",
          jump_to_mark = "<C-j>",
          pre_select = true
        }
      }
      vim.cmd('COQnow --shut-up')
    end,
  },

  -- formatter
  {
    'stevearc/conform.nvim',
    keys = {
      {
        '<leader>bf',
        function()
          require('conform').format({
            timeout_ms = 500,
            lsp_fallback = true,
          })
        end,
        desc = 'Format buffer'
      }
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        -- Conform will run multiple formatters sequentially
        python = { "isort", "black" },
        -- Use a sub-list to run only the first available formatter
        javascript = { { "prettierd", "prettier" } },
        typescript = { { "prettierd", "prettier" } },
      },
    },
  },

  -- test runner
  {
    'vim-test/vim-test',
    keys = {
      { '<leader>tf', ':TestFile<cr>',    desc = 'Run test file' },
      { '<leader>tn', ':TestNearest<cr>', desc = 'Run nearest test' },
      { '<leader>tl', ':TestLast<cr>',    desc = 'Re-run last test' },
      { '<leader>ta', ':TestSuite<cr>',   desc = 'Run entire test suite' },
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
    main = "ibl",
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {},
  },

  -- auto pairs
  -- {
  --   'echasnovski/mini.pairs',
  --   event = 'VeryLazy',
  --   opts = {},
  -- },

  -- Fast and feature-rich surround actions. For text that includes
  -- surroundin characters like brackets or quotes, this allows you
  -- to select the text inside, change or modify the surrounding characters,
  -- and more.
  {
    'echasnovski/mini.surround',
    keys = function(_, keys)
      -- Populate the keys based on the user's options
      local plugin = require('lazy.core.config').spec.plugins['mini.surround']
      local opts = require('lazy.core.plugin').values(plugin, 'opts', false)
      local mappings = {
        { opts.mappings.add,            desc = 'Add surrounding',                     mode = { 'n', 'v' } },
        { opts.mappings.delete,         desc = 'Delete surrounding' },
        { opts.mappings.find,           desc = 'Find right surrounding' },
        { opts.mappings.find_left,      desc = 'Find left surrounding' },
        { opts.mappings.highlight,      desc = 'Highlight surrounding' },
        { opts.mappings.replace,        desc = 'Replace surrounding' },
        { opts.mappings.update_n_lines, desc = 'Update `MiniSurround.config.n_lines`' },
      }
      mappings = vim.tbl_filter(function(m)
        return m[1] and #m[1] > 0
      end, mappings)
      return vim.list_extend(mappings, keys)
    end,
    opts = {
      mappings = {
        add = 'gza',            -- Add surrounding in Normal and Visual modes
        delete = 'gzd',         -- Delete surrounding
        find = 'gzf',           -- Find surrounding (to the right)
        find_left = 'gzF',      -- Find surrounding (to the left)
        highlight = 'gzh',      -- Highlight surrounding
        replace = 'rzr',        -- Replace surrounding
        update_n_lines = 'gzn', -- Update `n_lines`
      },
    },
  },

  -- comments
  { 'JoosepAlviste/nvim-ts-context-commentstring', lazy = true },
  {
    'echasnovski/mini.comment',
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
