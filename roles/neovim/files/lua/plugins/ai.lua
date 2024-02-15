return {
  -- {
  --   "robitx/gp.nvim",
  --   cmd = 'GpChatNew',
  --   keys = {
  --     { '<leader>ai', '<cmd>GpChatToggle popup<CR>', desc = 'toggle a GPT popup' }
  --
  --   },
  --   opts = {
  --     openai_api_key = { "cat", "~/.openai_api_key" },
  --   },
  --   config = function(_, opts)
  --     require("gp").setup(opts)
  --   end,
  -- }
  {
    "Exafunction/codeium.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      require("codeium").setup({
      })
    end
  },
}
