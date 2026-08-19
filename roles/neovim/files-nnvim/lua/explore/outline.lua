local pack = require("lib.pack")

return {
  src = pack.github("hedyhli/outline.nvim"),
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    { "<leader>cs", "<cmd>Outline<cr>", desc = "Symbol outline" },
  },
  config = function()
    require("outline").setup({
      outline_window = {
        position = "left",
        auto_close = false,
        auto_jump = false,
        -- Outline blanks winhighlight by default, which drops the styling edgy
        -- applies to its sidebar windows.
        winhl = table.concat({
          "Normal:EdgyNormal",
          "WinBar:EdgyWinBar",
          "WinBarNC:EdgyWinBarNC",
          "WinSeparator:EdgySeparator",
        }, ","),
      },
      preview_window = { auto_preview = false },
      symbol_folding = { autofold_depth = 2 },
    })
  end,
}
