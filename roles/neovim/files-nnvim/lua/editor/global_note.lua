local pack = require("lib.pack")

return {
  src = pack.github("backdround/global-note.nvim"),
  keys = {
    {
      "<leader>n",
      function()
        require("global-note").toggle_note()
      end,
      desc = "Toggle global note",
    },
  },
  config = function()
    require("global-note").setup({
      filename = "global.md",
      directory = vim.fs.joinpath(vim.fn.stdpath("data"), "global-note"),
      title = "Global Note",
      window_config = function()
        local ui = vim.api.nvim_list_uis()[1]
        return {
          relative = "editor",
          border = "rounded",
          title = "Global Note",
          title_pos = "center",
          width = math.floor(0.7 * ui.width),
          height = math.floor(0.85 * ui.height),
          row = math.floor(0.05 * ui.height),
          col = math.floor(0.15 * ui.width),
        }
      end,
      autosave = true,
    })
  end,
}
