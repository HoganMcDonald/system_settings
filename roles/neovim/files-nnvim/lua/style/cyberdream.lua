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
        blinkcmp = true,
        whichkey = true,
      },
      -- The editor stays transparent while the edgy sidebar keeps an opaque
      -- background, with its separators blended in to hide the outline.
      overrides = function(colors)
        local sidebar = { bg = colors.bg_solid }
        local seamless = { fg = colors.bg_solid, bg = colors.bg_solid }

        return {
          EdgyNormal = sidebar,
          EdgySeparator = seamless,
          WinSeparator = seamless,
          EdgyIcon = { bg = colors.bg_solid, fg = colors.grey },
          EdgyIconActive = { bg = colors.bg_solid, fg = colors.cyan },
          EdgyTitle = { bg = colors.bg_solid, fg = colors.cyan, bold = true },
          EdgyWinBar = { bg = colors.bg_solid, fg = colors.grey },
          EdgyWinBarNC = { bg = colors.bg_solid, fg = colors.grey },
          NeoTreeNormal = sidebar,
          NeoTreeNormalNC = sidebar,
          NeoTreeEndOfBuffer = sidebar,
          NeoTreeWinSeparator = seamless,
          MasonNormal = sidebar,
        }
      end,
    })
    vim.cmd.colorscheme("cyberdream")
  end,
}
