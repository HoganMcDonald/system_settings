local pack = require("lib.pack")

-- Captured while the spec is collected, so the footer can report how long the
-- rest of startup took. `snacks.dashboard`'s own startup section is skipped
-- because it reads stats from lazy.nvim, which this config does not use.
local started_at = vim.uv.hrtime()

local header = [[
 ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓
 ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒
▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░
▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██
▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒
░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░
]]

---@type boolean?
local git_usable

---The git section shells out, and a failure surfaces as a blocking job-error
---popup. `git` on PATH is not enough: the macOS shim resolves through
---DEVELOPER_DIR, which a stale environment can point somewhere without git. So
---probe once per session, only when the dashboard is actually rendered.
---@return boolean
local function in_git_repo()
  if git_usable == nil then
    git_usable = vim.fn.executable("git") == 1
      and vim.system({ "git", "rev-parse", "--is-inside-work-tree" }):wait(2000).code == 0
  end

  return git_usable
end

---@return snacks.dashboard.Section
local function startup()
  local elapsed = (vim.uv.hrtime() - started_at) / 1e6
  -- `info = false` skips a git query per plugin.
  local managed = vim.pack.get(nil, { info = false })

  return {
    align = "center",
    text = {
      { "⚡ ", hl = "footer" },
      { ("%d/%d"):format(#pack.loaded(), #managed), hl = "special" },
      { " plugins loaded in ", hl = "footer" },
      { ("%.1fms"):format(elapsed), hl = "special" },
    },
  }
end

-- Loaded eagerly so the dashboard is configured before VimEnter.
return {
  src = pack.github("folke/snacks.nvim"),
  config = function()
    require("snacks").setup({
      -- Replaces `vim.ui.input`, which also gives opencode.nvim's `ask()` a
      -- floating prompt instead of the command line.
      input = { enabled = true },
      dashboard = {
        enabled = true,
        preset = {
          header = header,
          keys = {
            { icon = " ", key = "f", desc = "Find file", action = ":Telescope find_files" },
            { icon = " ", key = "g", desc = "Grep text", action = ":Telescope live_grep" },
            { icon = " ", key = "r", desc = "Recent files", action = ":Telescope oldfiles" },
            { icon = " ", key = "s", desc = "Restore previous session", action = ":PersistenceLoadLast" },
            { icon = " ", key = "n", desc = "New file", action = ":enew | startinsert" },
            {
              icon = " ",
              key = "e",
              desc = "Explorer",
              action = function()
                require("edgy").toggle("left")
              end,
            },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":Telescope find_files cwd=" .. vim.fn.stdpath("config"),
            },
            {
              icon = "󰚰 ",
              key = "u",
              desc = "Update plugins",
              action = function()
                vim.pack.update()
              end,
            },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          {
            pane = 2,
            icon = " ",
            title = "Recent files",
            section = "recent_files",
            limit = 6,
            indent = 2,
            padding = 1,
          },
          {
            pane = 2,
            icon = " ",
            title = "Git status",
            section = "terminal",
            enabled = in_git_repo,
            cmd = "git status --short --branch --renames",
            height = 8,
            ttl = 60,
            indent = 2,
            padding = 1,
          },
          startup,
        },
      },
    })

    -- Opened outside of startup, the dashboard is a full-size float whose
    -- buffer is wiped on hide, so closing it restores the previous window.
    vim.keymap.set("n", "<leader>D", function()
      if vim.bo.filetype == "snacks_dashboard" then
        vim.cmd.bdelete()
      else
        require("snacks").dashboard.open()
      end
    end, { desc = "Dashboard (toggle)" })
  end,
}
