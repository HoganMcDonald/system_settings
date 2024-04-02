local Colors = require("util.colors")

-- TODO:
-- "lewis6991/hover.nvim", -- Better [vim.lsp.buf.hover()]
-- "VidocqH/lsp-lens.nvim", -- LSP definition, references in virtual text
-- "https://git.sr.ht/~whynothugo/lsp_lines.nvim", -- LSP diagnostic as lines
-- "hrsh7th/cmp-nvim-lsp", -- LSP for nvim-cmp
-- "antosha417/nvim-lsp-file-operations", -- LSP for file-operations
-- "ray-x/lsp_signature.nvim", -- Signature Hint
-- "zeioth/garbage-day.nvim", -- Automatic Toggle of LSP clients to free RAM
-- "chrisgrieser/nvim-dr-lsp", -- LSP References and Definitions in statusline
-- "soulis-1256/eagle.nvim", -- Mouse CursorHold on object to see Hover thing
-- "folke/neodev.nvim", -- NeoDev for lua things
-- "askfiy/lsp_extra_dim", -- Dim Unused variables
-- "nvimdev/lspsaga.nvim", -- Better LSP things overall
-- "filipdutescu/renamer.nvim", -- Rename LSP variables
-- "folke/trouble.nvim", -- LSP Diagnostics in a split
-- "folke/todo-comments.nvim", -- TODO and all these comment types

-- DONE:
-- "neovim/nvim-lspconfig", -- The main LSP thing
-- "utilyre/barbecue.nvim", -- Winbar LSP
-- "SmiteshP/nvim-navic", -- Required for barbecue
-- "aznhe21/actions-preview.nvim", -- Better [vim.lsp.buf.codeaction()]
-- "j-hui/fidget.nvim", -- LSP things status

-- NOPE:

return {
  -- lsp installer
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
    },
  },

  -- ---------------------
  -- lsp ui elements
  -- ---------------------
  -- lsp progress
  {
    "j-hui/fidget.nvim",
    opts = {
      -- options
    },
  },

  -- virtual text lines
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    config = function()
      require("lsp_lines").setup()
    end,
  },

  -- lsp hover
  {
    "lewis6991/hover.nvim",
    keys = {
      { "K", function() require("hover").hover() end, desc = "[hover.nvim] LSP Hover" },
      { "gK", function() require("hover").hover_select() end, desc = "[hover.nvim] LSP Hover (select)" },
      {
        "<C-p>",
        function()
          require("hover").hover_switch("previous")
        end,
        desc = "[hover.nvim] Previous Source",
      },
      {
        "<C-n>",
        function()
          require("hover").hover_switch("next")
        end,
        desc = "[hover.nvim] Next Source",
      },
    },
    opts = {
      init = function()
        require("hover.providers.lsp")
        -- require('hover.providers.gh')
        -- require('hover.providers.gh_user')
        -- require('hover.providers.jira')
        require("hover.providers.man")
        require("hover.providers.dictionary")
      end,
    },
  },

  -- code actions previews
  {
    "aznhe21/actions-preview.nvim",
    keys = {
      {
        "<leader>ca",
        function()
          require("actions-preview").code_actions()
        end,
        desc = "Code Action",
        mode = { "n", "v" },
      },
    },
  },

  -- winbar
  {
    "SmiteshP/nvim-navic", -- statusline/winbar component using lsp
    dependencies = "neovim/nvim-lspconfig",
    opts = {
      highlight = true,
      separator = " 〉",
      -- VScode-like icons
      icons = {
        File = " ",
        Module = " ",
        Namespace = " ",
        Package = " ",
        Class = " ",
        Method = " ",
        Property = " ",
        Field = " ",
        Constructor = " ",
        Enum = " ",
        Interface = " ",
        Function = " ",
        Variable = " ",
        Constant = " ",
        String = " ",
        Number = " ",
        Boolean = " ",
        Array = " ",
        Object = " ",
        Key = " ",
        Null = " ",
        EnumMember = " ",
        Struct = " ",
        Event = " ",
        Operator = " ",
        TypeParameter = " ",
      },
    },
  },

  {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    dependencies = {
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    opts = {
      theme = {
        normal = { bg = Colors.BLACK },
      },
    },
  },
}
