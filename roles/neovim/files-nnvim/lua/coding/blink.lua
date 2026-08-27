local pack = require("lib.pack")

-- Loaded eagerly, and sorted ahead of `lsp.lua`, so servers advertise blink's
-- completion capabilities before any of them are enabled.
return {
  src = pack.github("saghen/blink.cmp"),
  -- Pinned to a tagged release: blink only downloads its prebuilt fuzzy matcher
  -- when the checkout is on a git tag, and otherwise falls back to a slower
  -- Lua implementation.
  version = vim.version.range("1"),
  dependencies = {
    pack.github("rafamadriz/friendly-snippets"),
    pack.github("disrupted/blink-cmp-conventional-commits"),
  },
  config = function()
    local blink = require("blink.cmp")

    blink.setup({
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        list = { selection = { preselect = false, auto_insert = true } },
      },
      signature = { enabled = true },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        -- Commit messages have no LSP or snippets to offer, so the list is
        -- replaced rather than extended. Scopes are read out of `git log`.
        per_filetype = { gitcommit = { "conventional_commits", "buffer" } },
        providers = {
          conventional_commits = {
            name = "Conventional Commits",
            module = "blink-cmp-conventional-commits",
          },
        },
      },
    })

    -- blink does not register these itself.
    vim.lsp.config("*", {
      capabilities = blink.get_lsp_capabilities({}, true),
    })
  end,
}
