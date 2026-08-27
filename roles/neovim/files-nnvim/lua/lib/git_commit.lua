---Floating commit-message editor. The buffer is a real `gitcommit` buffer, so
---blink's conventional-commits source supplies the type and scope completions
---that would otherwise need a static cheatsheet alongside it.

local M = {}

---@class NvimGitCommitState
---@field win integer?
---@field buf integer?
local state = {}

---Sized from the global options rather than `nvim_list_uis`, which is empty in
---headless sessions.
---@return vim.api.keyset.win_config
local function window_config()
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.4)

  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " Commit Message ",
    title_pos = "center",
  }
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end

  state = {}
end

local function abort()
  M.close()
  vim.notify("Commit aborted")
end

---Runs the commit synchronously: `:w` has to report the outcome before `:wq`
---moves on to closing the window.
local function write()
  local message = vim.trim(table.concat(vim.api.nvim_buf_get_lines(state.buf, 0, -1, false), "\n"))

  -- Cleared either way, so an unwanted message can still be discarded with `:q`
  -- instead of tripping over 'modified'.
  vim.bo[state.buf].modified = false

  if message == "" then
    vim.notify("Commit message cannot be empty", vim.log.levels.ERROR)
    return
  end

  local result = vim.system({ "git", "commit", "-m", message }, { text = true }):wait()

  if result.code == 0 then
    -- The window is left open for `:wq` to close on its own. Closing it here
    -- would leave the trailing `:q` to quit whatever window came next.
    vim.notify("Commit successful")
  else
    vim.notify(result.stderr, vim.log.levels.ERROR)
  end
end

function M.open()
  if not vim.fs.root(vim.fn.getcwd(), ".git") then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  -- Exits 0 when the index holds no changes.
  if vim.system({ "git", "diff", "--cached", "--quiet" }):wait().code == 0 then
    vim.notify("No staged changes to commit", vim.log.levels.WARN)
    return
  end

  M.close()

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(state.buf, "COMMIT_MSG")
  vim.bo[state.buf].filetype = "gitcommit"
  -- `acwrite` routes `:w` through BufWriteCmd instead of writing a file.
  vim.bo[state.buf].buftype = "acwrite"

  state.win = vim.api.nvim_open_win(state.buf, true, window_config())

  local group = vim.api.nvim_create_augroup("Nvim_git_commit", { clear = true })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = group,
    buffer = state.buf,
    callback = write,
  })

  -- Covers the window being closed by anything other than the maps below.
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(state.win),
    callback = function()
      vim.schedule(M.close)
    end,
  })

  local opts = { buffer = state.buf, desc = "Abort commit" }
  vim.keymap.set("n", "q", abort, opts)
  vim.keymap.set("n", "<esc>", abort, opts)
  vim.keymap.set({ "n", "i" }, "<C-c>", abort, opts)

  vim.cmd.startinsert()
end

return M
