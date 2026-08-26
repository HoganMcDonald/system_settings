local pack = require("lib.pack")

local excluded_filetypes = {
  ["TelescopePrompt"] = true,
  ["codecompanion"] = true,
  ["dashboard"] = true,
  ["help"] = true,
  ["lazy"] = true,
  ["mason"] = true,
  ["neo-tree"] = true,
  ["noice"] = true,
  ["qf"] = true,
  ["snacks_dashboard"] = true,
  ["yazi"] = true,
}

return {
  src = pack.github("Bekaboo/dropbar.nvim"),
  event = { "BufReadPost", "BufNewFile" },
  keys = {
    { "<leader>;", function() require("dropbar.api").pick() end, desc = "Pick symbols in winbar" },
    { "[;", function() require("dropbar.api").goto_context_start() end, desc = "Context start" },
    { "];", function() require("dropbar.api").select_next_context() end, desc = "Next context" },
  },
  config = function()
    require("dropbar").setup({
      general = {
        enable = function(buf, win)
          if vim.api.nvim_win_get_config(win).relative ~= "" then
            return false
          end
          return vim.bo[buf].buftype == "" and not excluded_filetypes[vim.bo[buf].filetype]
        end,
        attach_events = { "OptionSet", "BufWinEnter", "BufWritePost" },
      },
      icons = {
        kinds = { use_devicons = true },
        ui = {
          bar = { separator = " › ", extends = "…" },
          menu = { separator = " ", indicator = " " },
        },
      },
      bar = {
        sources = function(buf, _)
          local sources = require("dropbar.sources")
          local utils = require("dropbar.utils")
          if vim.bo[buf].filetype == "markdown" then
            return { sources.path, sources.markdown }
          end
          return { sources.path, utils.source.fallback({ sources.lsp, sources.treesitter }) }
        end,
      },
      menu = {
        preview = true,
        quick_navigation = true,
      },
    })
  end,
}
