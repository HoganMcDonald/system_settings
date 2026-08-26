local pack = require("lib.pack")

local commit_types = {
  "feat",
  "fix",
  "docs",
  "style",
  "refactor",
  "perf",
  "test",
  "build",
  "ci",
  "chore",
}

local function commit()
  vim.ui.select(commit_types, {
    prompt = "Commit type",
    format_item = function(kind)
      return kind .. ":"
    end,
  }, function(kind)
    if not kind then
      return
    end

    vim.ui.input({ prompt = kind .. ": " }, function(subject)
      if not subject or subject == "" then
        return
      end

      vim.system({ "git", "commit", "-m", kind .. ": " .. subject }, { text = true }, function(result)
        vim.schedule(function()
          if result.code == 0 then
            vim.notify("Commit successful")
          else
            vim.notify(result.stderr, vim.log.levels.ERROR)
          end
        end)
      end)
    end)
  end)
end

return {
  {
    src = pack.github("lewis6991/gitsigns.nvim"),
    keys = {
      { "<leader>ghp", function() require("gitsigns").preview_hunk_inline() end, desc = "Preview hunk inline" },
      { "<leader>ghP", function() require("gitsigns").preview_hunk() end, desc = "Preview hunk" },
      { "<leader>ghs", function() require("gitsigns").stage_hunk() end, desc = "Stage hunk" },
      { "<leader>ghr", function() require("gitsigns").reset_hunk() end, desc = "Reset hunk" },
      {
        "<leader>ghs",
        function()
          require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end,
        mode = "x",
        desc = "Stage hunk",
      },
      {
        "<leader>ghr",
        function()
          require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end,
        mode = "x",
        desc = "Reset hunk",
      },
      { "]h", function() require("gitsigns").next_hunk() end, desc = "Next hunk" },
      { "[h", function() require("gitsigns").prev_hunk() end, desc = "Previous hunk" },
    },
    config = function()
      require("gitsigns").setup()
    end,
  },
  {
    src = pack.github("tpope/vim-fugitive"),
    cmd = {
      "G",
      "Git",
      "Gdiffsplit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "GMove",
      "GDelete",
      "GBrowse",
      "GRemove",
      "GRename",
      "Glgrep",
      "Gedit",
    },
    keys = {
      { "<leader>gc", commit, desc = "Create commit" },
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
      { "<leader>gp", "<cmd>Git push<cr>", desc = "Git push" },
      { "<leader>gP", "<cmd>Git pull<cr>", desc = "Git pull" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
      { "<leader>gB", "<cmd>GBrowse<cr>", desc = "Git browse" },
      { "<leader>gw", "<cmd>Gwrite<cr>", desc = "Stage current file" },
      { "<leader>gr", "<cmd>Gread<cr>", desc = "Checkout current file" },
    },
  },
}
