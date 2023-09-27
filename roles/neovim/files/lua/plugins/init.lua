-----------------------------------------------------------
-- Plugin manager configuration file
-----------------------------------------------------------

local g = vim.g
local fn = vim.fn
local opt = vim.opt
local loop = vim.loop

g.mapleader = ' '

local lazypath = fn.stdpath("data") .. "/lazy/lazy.nvim"
if not loop.fs_stat(lazypath) then
  fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
opt.rtp:prepend(lazypath)

local plugins = {
  'nvim-lua/plenary.nvim',

  -- colorscheme
  {
    'kwsp/halcyon-neovim',
    lazy = false,
    config = function()
      require('plugins.configs.halcyon')
    end,
  },

  -- start screen
  {
    'glepnir/dashboard-nvim',
    dependencies = 'kwsp/halcyon-neovim',
    config = function()
      require('plugins.configs.dashboardNvim')
    end,
  },

  -- fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = 'Telescope',
    keys = {
      { '<leader>pf', ':Telescope find_files<cr>' },
      { '<leader>po', ':Telescope oldfiles<cr>' },
      { '<leader>fa', ':Telescope live_grep<cr>' },
      { '<leader>fw', ':Telescope grep_string<cr>' },
      { '<leader>gs', ':Telescope git_status<cr>' },
      { '<leader>fr', ':%s/' }
    },
    config = function()
      require('plugins.configs.telescope')
    end,
  },

  -- icons
  {
    'kyazdani42/nvim-web-devicons',
    config = function()
      require('plugins.configs.nvimWebDevicons')
    end,
  },

  -- buffer tabs
  {
    'akinsho/bufferline.nvim',
    dependencies = 'kyazdani42/nvim-web-devicons',
    event = 'BufEnter',
    keys = {
      { '<leader>bp', ':BufferLineCyclePrev<cr>' },
      { '<leader>bn', ':BufferLineCycleNext<cr>' },
      { '<S-TAB>', ':BufferLineCyclePrev<cr>' },
      { '<TAB>', ':BufferLineCycleNext<cr>' },
      { '<leader>bd', ':BufferLinePickClose<cr>' },
      { '<leader>b1', ':BufferLineGoToBuffer 1<cr>' },
      { '<leader>b2', ':BufferLineGoToBuffer 2<cr>' },
      { '<leader>b3', ':BufferLineGoToBuffer 3<cr>' },
      { '<leader>b4', ':BufferLineGoToBuffer 4<cr>' },
      { '<leader>b5', ':BufferLineGoToBuffer 5<cr>' },
      { '<leader>b6', ':BufferLineGoToBuffer 6<cr>' },
      { '<leader>b7', ':BufferLineGoToBuffer 7<cr>' },
      { '<leader>b8', ':BufferLineGoToBuffer 8<cr>' },
      { '<leader>b9', ':BufferLineGoToBuffer 9<cr>' },
    },
    config = function()
      require('plugins.configs.bufferline')
    end,
  },

  -- file tree
  {
    'kyazdani42/nvim-tree.lua',
    dependencies = {
      'kwsp/halcyon-neovim',
      'kyazdani42/nvim-web-devicons',
    },
    keys = {
      { '<leader>ft', ':NvimTreeToggle<cr>' },
      { '<leader>ff', ':NvimTreeFocus<cr>' }
    },
    config = function()
      require('plugins.configs.nvimTree')
    end,
  },

  -- tab lines
  {
    'lukas-reineke/indent-blankline.nvim',
    event = 'BufRead',
    config = function()
      require('plugins.configs.indentBlankline')
    end,
  },

  -- folds
  {
    'kevinhwang91/nvim-ufo',
    dependencies = 'kevinhwang91/promise-async',
    event = 'BufRead',
    config = function()
      require('plugins.configs.ufo')
    end,
  },

  {
    "luukvbaal/statuscol.nvim",
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup(
        {
          relculright = true,
          segments = {
            { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
            { text = { "%s" }, click = "v:lua.ScSa" },
            { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" }
          }
        }
      )
    end
  },

  -- display colors
  {
    'norcalli/nvim-colorizer.lua',
    event = 'BufRead',
    config = function()
      require('plugins.configs.colorizer')
    end,
  },

  -- treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    event = 'BufRead',
    config = function()
      require('plugins.configs.treesitter')
    end,
  },

  -- documentation
  {
    'kkoomen/vim-doge',
    event = 'BufEnter',
    --[[ config = function()
      cmd('call doge#install()')
    end, ]]
  },

  -- git
  {
    'tpope/vim-fugitive',
    keys = {
      { '<leader>g', ':Git ' },
      { '<leader>gb', ':Git blame<cr>' },
      { '<leader>ga', ':Git add -p<cr>' },
      { '<leader>gc', ':Git commit<cr>' },
    },
  },

  {
    'lewis6991/gitsigns.nvim',
    event = 'BufRead',
    keys = {
      { '<leader>hn', ':Gitsigns next_hunk<cr>' },
      { '<leader>hp', ':Gitsigns prev_hunk<cr>' },
      { '<leader>hs', ':Gitsigns stage_hunk<cr>' },
      { '<leader>hr', ':Gitsigns reset_hunk<cr>' },
      { '<leader>br', ':Gitsigns reset_buffer<cr>' },
    },
    config = function()
      require('plugins.configs.gitsigns')
    end,
  },

  {
    'sindrets/diffview.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    keys = {
      { '<leader>dv', ':DiffviewOpen<cr>' },
      { '<leader>dc', ':DiffviewClose<cr>' },
      { '<leader>gh', ':DiffviewFileHistory<cr>' },
    },
    config = function()
      require('plugins.configs.diffview')
    end,
  },

  -- smooth scrolling
  {
    'karb94/neoscroll.nvim',
    event = 'BufEnter',
    config = function()
      require('plugins.configs.neoscroll')
    end,
  },

  -- his holiness
  'tpope/vim-abolish',
  'tpope/vim-endwise',
  'tpope/vim-rails',

  -- lsp
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
    },
  },

  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    config = function()
      require("lsp_lines").setup()
    end,
  },

  -- completion
  {
    'ms-jpq/coq_nvim',
    dependencies = {
      'ms-jpq/coq.artifacts',
    },
    config = function()
      require('plugins.configs.coq')
    end,
  },

  -- autotag xml
  {
    'windwp/nvim-ts-autotag',
    config = function()
      require('plugins.configs.autotag')
    end,
  },

  -- close quotes
  'Raimondi/delimitMate',

  -- toggle comments
  'b3nj5m1n/kommentary',

  -- status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = 'kyazdani42/nvim-web-devicons',
    config = function()
      require('plugins.configs.luaLine')
    end,
  },

  -- winbar
  {
    'fgheng/winbar.nvim',
    config = function()
      require('plugins.configs.winbar')
    end,
  },

  -- test runner
  {
    'vim-test/vim-test',
    keys = {
      { '<leader>tf', ':TestFile<cr>' },
      { '<leader>tn', ':TestNearest<cr>' },
      { '<leader>tl', ':TestLast<cr>' },
      { '<leader>ta', ':TestSuite<cr>' },
    },
    config = function()
      vim.g['test#strategy'] = 'neovim'
    end,
  },

  --terminal
  {
    'akinsho/toggleterm.nvim',
    keys = {
      { '\\', ':ToggleTerm<cr>' },
    },
    config = function()
      require('plugins.configs.toggleterm')
    end,
  },

  -- editor
  {
    "m4xshen/smartcolumn.nvim",
    event = 'BufEnter',
    config = function()
      require('plugins.configs.smartcolumn')
    end
  },

  -- ducks
  {
    'tamton-aquib/duck.nvim',
    keys = {
      { '<leader>dd', function() require("duck").hatch("🦀") end },
      { '<leader>dk', function() require("duck").cook() end },
    },
  }
}

local options = {}

require("lazy").setup(plugins, options)
