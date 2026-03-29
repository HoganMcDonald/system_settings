return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-nvim-theme",
    priority = 1000,
    opts = {
      options = {
        transparent = true,
        styles = {
          comments = "italic",
          keywords = "NONE",
          conditionals = "italic",
        },
      },
      groups = {
        all = {
          -- Make yazi floating window background solid like Telescope
          YaziFloat = { bg = "#0d1117" },
          YaziBorder = { bg = "#0d1117", fg = "#58a6ff" },
        },
      },
    },
    config = function(_, opts)
      require("github-theme").setup(opts)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_dark",
    },
  },
}
