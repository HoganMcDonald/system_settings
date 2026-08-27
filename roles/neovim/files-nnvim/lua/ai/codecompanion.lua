local pack = require("lib.pack")

-- ACP adapters delegate authentication to the agent's own CLI, so no keys are
-- stored for the editor. `opencode` spawns `opencode acp` and reuses the
-- credentials in ~/.local/share/opencode/auth.json, which is an OAuth login.
local adapter = "opencode"

return {
  src = pack.github("olimorris/codecompanion.nvim"),
  dependencies = pack.github("nvim-lua/plenary.nvim"),
  cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionChat", "CodeCompanionCmd" },
  autocmds = {
    {
      event = require("lib.autocmd").event("FileType"),
      pattern = "codecompanion",
      callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
      end,
    },
  },
  keys = {
    {
      "<leader>aa",
      function()
        require("lib.edgy").close_filetype("neotest-summary")
        vim.cmd("CodeCompanionChat Toggle")
      end,
      mode = { "n", "x" },
      desc = "Chat",
    },
    { "<leader>ax", "<cmd>CodeCompanionActions<cr>", mode = { "n", "x" }, desc = "Actions" },
    { "<leader>ai", "<cmd>CodeCompanion<cr>", mode = { "n", "x" }, desc = "Inline prompt" },
    { "<leader>aA", "<cmd>CodeCompanionChat Add<cr>", mode = "x", desc = "Add selection to chat" },
  },
  config = function()
    require("codecompanion").setup({
      adapters = {
        acp = {
          extend = {
            -- The codex CLI is signed in with a ChatGPT account rather than an
            -- API key, so it is reachable from the chat's adapter picker.
            codex = {
              defaults = { auth_method = "chat-gpt" },
            },
          },
        },
      },
      -- `background`, `chat`, `cmd` and `inline` each default to copilot.
      interactions = {
        background = { adapter = adapter },
        chat = { adapter = adapter },
        cmd = { adapter = adapter },
        inline = { adapter = adapter },
      },
      display = {
        chat = {
          -- A vertical split rather than a float, so edgy can adopt it into the
          -- right sidebar. Sizing is left to edgy.
          window = {
            layout = "vertical",
            position = "right",
            full_height = true,
          },
        },
      },
    })
  end,
}
