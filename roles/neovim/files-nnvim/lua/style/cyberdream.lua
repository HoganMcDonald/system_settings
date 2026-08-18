local pack = require("lib.pack")

return {
  src = pack.github("scottmckendry/cyberdream.nvim.git"),
  config = function()
    require("cyberdream").setup({
      borderless_pickers = true,
      italic_comments = true,
      terminal_colors = true,
      transparent = true,
      extensions = {
        whichkey = true,
      },
    })
    vim.cmd.colorscheme("cyberdream")
  end,
}
