local pack = require("lib.pack")

local function jest_root(file)
  local match = file:match("(.*/packages/[^/]+/)")
  return match or vim.fn.getcwd()
end

return {
  src = pack.github("nvim-neotest/neotest"),
  dependencies = {
    pack.github("nvim-neotest/neotest-jest"),
    pack.github("nvim-neotest/neotest-python"),
    pack.github("nvim-neotest/nvim-nio"),
    pack.github("nvim-lua/plenary.nvim"),
  },
  keys = {
    { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
    { "<leader>tT", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run test file" },
    { "<leader>ta", function() require("neotest").run.run(vim.fn.getcwd()) end, desc = "Run all tests" },
    { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run last test" },
    {
      "<leader>ts",
      function()
        require("lib.edgy").close_filetype("codecompanion")
        require("neotest").summary.toggle()
      end,
      desc = "Test summary",
    },
    { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Test output panel" },
    { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop tests" },
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("rustaceanvim.neotest"),
        require("neotest-jest")({
          jestConfigFile = function(file)
            return vim.fs.joinpath(jest_root(file), "jest.config.js")
          end,
          cwd = jest_root,
        }),
        require("neotest-python")({}),
      },
    })
  end,
}
