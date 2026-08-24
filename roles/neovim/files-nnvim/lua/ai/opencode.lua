local pack = require("lib.pack")

-- The plugin attaches to any `opencode` already exposing a server, which only
-- happens when it was started with `--port`. Sessions started without it are
-- invisible, so this command is used for an editor-local instance instead.
local command = "opencode --port"

---@type snacks.terminal.Opts
local terminal = {
  win = {
    position = "right",
    enter = false,
  },
}

return {
  src = pack.github("nickjvandyke/opencode.nvim"),
  version = vim.version.range("*"),
  -- Options are read from a global, so they are set before the plugin loads.
  init = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        start = function()
          require("snacks.terminal").open(command, terminal)
        end,
      },
    }
  end,
  keys = {
    {
      "<leader>aa",
      function()
        require("opencode").ask("@this: ")
      end,
      mode = { "n", "x" },
      desc = "Ask opencode",
    },
    {
      "<leader>ap",
      function()
        require("opencode").select()
      end,
      mode = { "n", "x" },
      desc = "Opencode prompts",
    },
    {
      "<leader>ab",
      function()
        require("opencode").ask("@buffer: ")
      end,
      desc = "Ask opencode about buffer",
    },
    {
      "<leader>ad",
      function()
        require("opencode").prompt("Explain @diagnostics")
      end,
      desc = "Explain diagnostics",
    },
    {
      "<leader>ao",
      function()
        require("snacks.terminal").toggle(command, terminal)
      end,
      desc = "Toggle opencode",
    },
  },
}
