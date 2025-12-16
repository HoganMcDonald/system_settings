return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/git-commit-float",
    name = "git-commit-float",
    keys = {
      {
        "<leader>gc",
        function()
          require("git-commit-float").open()
        end,
        desc = "Git commit (floating)",
      },
    },
  },
}
