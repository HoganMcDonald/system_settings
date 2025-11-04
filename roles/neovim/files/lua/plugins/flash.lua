return {
  {
    "folke/flash.nvim",
    opts = {
      modes = {
        char = {
          enabled = false, -- Disable default f/F/t/T flash behavior
        },
      },
    },
    keys = {
      -- Disable default s/S keybindings (restore to default vim behavior)
      { "s", mode = { "n", "x", "o" }, false },
      { "S", mode = { "n", "x", "o" }, false },
      -- Disable default t/T keybindings as well
      { "t", mode = { "n", "x", "o" }, false },
      { "T", mode = { "n", "x", "o" }, false },

      -- Map f/F to use flash.nvim's jump functionality (previously on s/S)
      {
        "f",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "F",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },

      -- Keep remote flash on r (useful for operator pending mode)
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },

      -- Keep treesitter search on R
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },

      -- Keep toggle flash search on <c-s> in command mode
      {
        "<c-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  },
}
