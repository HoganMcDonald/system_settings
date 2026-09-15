---Fugitive opens its editor buffers -- commit messages, rebase todos, tag
---messages -- with `keepalt split` and then waits on the buffer being wiped to
---resume the git process. Converting that window into a float leaves all of
---that wiring untouched: the same buffer is what `:wq` writes and what fugitive
---is blocked on, it just presents as a modal instead of a split.

local M = {}

---Titles are keyed by filetype so the modal names what it is editing. The
---default covers any editor buffer fugitive gains later.
local titles = {
  gitcommit = " Commit Message ",
  gitrebase = " Rebase ",
}

---Sized from the global options rather than `nvim_list_uis`, which is empty in
---headless sessions.
---@param buf integer
---@return vim.api.keyset.win_config
local function window_config(buf)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.4)

  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = titles[vim.bo[buf].filetype] or " Git ",
    title_pos = "center",
  }
end

---Relocate a fugitive editor window into a centered float.
---@param win integer?
function M.float(win)
  win = win or vim.api.nvim_get_current_win()

  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  -- Already floating when something else got there first.
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return
  end

  vim.api.nvim_win_set_config(win, window_config(vim.api.nvim_win_get_buf(win)))
end

---Registered from fugitive's plugin spec, once fugitive is actually loaded.
function M.setup()
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("Nvim_git_commit", { clear = true }),
    pattern = "FugitiveEditor",
    callback = function()
      M.float()
    end,
  })
end

return M
