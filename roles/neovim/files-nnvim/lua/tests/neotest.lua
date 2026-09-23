local autocmd = require("lib.autocmd")
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
    pack.github("marilari88/neotest-vitest"),
  },
  autocmds = {
    {
      event = autocmd.event("BufReadPost"),
      pattern = { "*.test.*", "*.spec.*", "test_*.py", "*_test.py" },
      -- Deferred so the read finishes before the layout changes underneath it.
      callback = function()
        vim.schedule(function()
          -- The chat holds the same edgebar slot. Opening a test file should not
          -- throw a conversation away, so `<leader>ts` stays the way to take the
          -- slot back.
          local edgy = require("lib.edgy")
          local diffview = package.loaded["diffview.lib"]

          if
            edgy.has_filetype("codecompanion")
            or edgy.has_filetype("review-diff")
            or (diffview and diffview.get_current_view())
          then
            return
          end

          require("neotest").summary.open()
        end)
      end,
    },
    {
      -- Fired by neotest after the window exists, which covers `summary.open`
      -- above as well as the async `summary.toggle` behind `<leader>ts`.
      event = autocmd.event("User"),
      pattern = "NeotestSummaryOpen",
      callback = function()
        vim.schedule(require("lib.which_key").resync)
      end,
    },
  },
  keys = {
    {
      "<leader>tt",
      function()
        require("neotest").run.run()
      end,
      desc = "Run nearest test",
    },
    {
      "<leader>tT",
      function()
        require("neotest").run.run(vim.fn.expand("%"))
      end,
      desc = "Run test file",
    },
    {
      "<leader>ta",
      function()
        require("neotest").run.run(vim.fn.getcwd())
      end,
      desc = "Run all tests",
    },
    {
      "<leader>tl",
      function()
        require("neotest").run.run_last()
      end,
      desc = "Run last test",
    },
    {
      "<leader>ts",
      function()
        require("lib.edgy").close_filetype("codecompanion")
        require("neotest").summary.toggle()
      end,
      desc = "Test summary",
    },
    {
      "<leader>to",
      function()
        require("neotest").output.open({ enter = true })
      end,
      desc = "Test output",
    },
    {
      "<leader>tO",
      function()
        require("neotest").output_panel.toggle()
      end,
      desc = "Test output panel",
    },
    {
      "<leader>tS",
      function()
        require("neotest").run.stop()
      end,
      desc = "Stop tests",
    },
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
        require("neotest-vitest"),
      },
    })
  end,
}
