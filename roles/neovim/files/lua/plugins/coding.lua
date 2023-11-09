local Colors = require('util.colors')
local bg = require('util.highlight').bg

return {
  {
    'kkoomen/vim-doge',
    event = 'BufEnter',
    build = ':call doge#install()',
  },

  -- completion
  {
    "hrsh7th/nvim-cmp",
    version = false, -- last release is way too old
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
    },
    opts = function()
      vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
      local cmp = require("cmp")
      local defaults = require("cmp.config.default")()
      return {
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ["<S-CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ["<C-CR>"] = function(fallback)
            cmp.abort()
            fallback()
          end,
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
        formatting = {
          format = function(_, item)
            local icons = {
              Array         = " ",
              Boolean       = "󰨙 ",
              Class         = " ",
              Codeium       = "󰘦 ",
              Color         = " ",
              Control       = " ",
              Collapsed     = " ",
              Constant      = "󰏿 ",
              Constructor   = " ",
              Copilot       = " ",
              Enum          = " ",
              EnumMember    = " ",
              Event         = " ",
              Field         = " ",
              File          = " ",
              Folder        = " ",
              Function      = "󰊕 ",
              Interface     = " ",
              Key           = " ",
              Keyword       = " ",
              Method        = "󰊕 ",
              Module        = " ",
              Namespace     = "󰦮 ",
              Null          = " ",
              Number        = "󰎠 ",
              Object        = " ",
              Operator      = " ",
              Package       = " ",
              Property      = " ",
              Reference     = " ",
              Snippet       = " ",
              String        = " ",
              Struct        = "󰆼 ",
              TabNine       = "󰏚 ",
              Text          = " ",
              TypeParameter = " ",
              Unit          = " ",
              Value         = " ",
              Variable      = "󰀫 ",
            }
            if icons[item.kind] then
              item.kind = icons[item.kind] .. item.kind
            end
            return item
          end,
        },
        experimental = {
          ghost_text = {
            hl_group = "CmpGhostText",
          },
        },
        sorting = defaults.sorting,
      }
    end,
    config = function(_, opts)
      for _, source in ipairs(opts.sources) do
        source.group_index = source.group_index or 1
      end
      require("cmp").setup(opts)
    end,
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
  {
    'echasnovski/mini.pairs',
    event = 'VeryLazy',
    opts = {},
  },

  -- Fast and feature-rich surround actions. For text that includes
  -- surrounding characters like brackets or quotes, this allows you
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
