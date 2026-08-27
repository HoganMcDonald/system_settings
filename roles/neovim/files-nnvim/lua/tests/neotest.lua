local pack = require("lib.pack")

local function jest_root(file)
  local match = file:match("(.*/packages/[^/]+/)")
  return match or vim.fn.getcwd()
end

local function refresh_which_key(buffer)
  local function refresh()
    if vim.api.nvim_buf_is_valid(buffer) then
      require("which-key.buf").get({ buf = buffer, mode = "n", update = true })
    end
  end

  if vim.v.vim_did_enter == 1 then
    refresh()
  else
    vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = refresh })
  end
end

return {
  src = pack.github("nvim-neotest/neotest"),
  dependencies = {
    pack.github("nvim-neotest/neotest-jest"),
    pack.github("nvim-neotest/neotest-python"),
    pack.github("nvim-neotest/nvim-nio"),
    pack.github("nvim-lua/plenary.nvim"),
  },
  autocmds = {
    {
      event = require("lib.autocmd").event("BufReadPost"),
      pattern = { "*.test.*", "*.spec.*", "test_*.py", "*_test.py" },
      callback = function(args)
        local buffer = args.buf
        vim.schedule(function()
          require("lib.edgy").close_filetype("codecompanion")
          require("neotest").summary.open()
          refresh_which_key(buffer)
        end)
      end,
    },
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
