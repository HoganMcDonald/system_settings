local M = {}

-- Conventional commit types reference
M.commit_types = {
  "feat:     A new feature",
  "fix:      A bug fix",
  "docs:     Documentation only changes",
  "style:    Changes that don't affect code meaning",
  "refactor: Neither fixes bug nor adds feature",
  "perf:     Performance improvement",
  "test:     Adding or correcting tests",
  "build:    Build system or dependencies",
  "ci:       CI configuration changes",
  "chore:    Other changes",
}

-- Window state tracking
M.state = {
  ref_win = nil,
  ref_buf = nil,
  commit_win = nil,
  commit_buf = nil,
}

-- Calculate window dimensions
function M.get_window_config()
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(0.6 * ui.width)
  local total_height = math.floor(0.6 * ui.height)
  local col = math.floor((ui.width - width) / 2)
  local start_row = math.floor((ui.height - total_height) / 2)

  local ref_height = #M.commit_types + 2
  local commit_height = total_height - ref_height - 1

  return {
    width = width,
    col = col,
    ref = {
      row = start_row,
      height = ref_height,
    },
    commit = {
      row = start_row + ref_height + 1,
      height = commit_height,
    },
  }
end

function M.close()
  -- Close windows if they exist
  if M.state.ref_win and vim.api.nvim_win_is_valid(M.state.ref_win) then
    vim.api.nvim_win_close(M.state.ref_win, true)
  end
  if M.state.commit_win and vim.api.nvim_win_is_valid(M.state.commit_win) then
    vim.api.nvim_win_close(M.state.commit_win, true)
  end

  -- Delete buffers
  if M.state.ref_buf and vim.api.nvim_buf_is_valid(M.state.ref_buf) then
    vim.api.nvim_buf_delete(M.state.ref_buf, { force = true })
  end
  if M.state.commit_buf and vim.api.nvim_buf_is_valid(M.state.commit_buf) then
    vim.api.nvim_buf_delete(M.state.commit_buf, { force = true })
  end

  -- Reset state
  M.state = {
    ref_win = nil,
    ref_buf = nil,
    commit_win = nil,
    commit_buf = nil,
  }
end

function M.setup_keymaps()
  local buf = M.state.commit_buf
  local opts = { buffer = buf, silent = true }

  -- Close/abort without committing
  vim.keymap.set("n", "q", function()
    M.close()
    vim.notify("Commit aborted", vim.log.levels.INFO)
  end, opts)

  vim.keymap.set("n", "<Esc>", function()
    M.close()
    vim.notify("Commit aborted", vim.log.levels.INFO)
  end, opts)

  vim.keymap.set({ "n", "i" }, "<C-c>", function()
    M.close()
    vim.notify("Commit aborted", vim.log.levels.INFO)
  end, opts)
end

function M.setup_autocmds()
  local buf = M.state.commit_buf

  -- Handle :w and :wq to execute the commit
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local message = table.concat(lines, "\n")

      -- Trim whitespace
      message = message:gsub("^%s+", ""):gsub("%s+$", "")

      -- Validate commit message
      if message == "" then
        vim.notify("Commit message cannot be empty", vim.log.levels.ERROR)
        -- Mark as not modified so :wq doesn't complain
        vim.api.nvim_set_option_value("modified", false, { buf = buf })
        return
      end

      -- Execute git commit
      local result = vim.fn.system({ "git", "commit", "-m", message })

      if vim.v.shell_error == 0 then
        vim.notify("Commit successful", vim.log.levels.INFO)
        M.close()
      else
        vim.notify("Commit failed: " .. result, vim.log.levels.ERROR)
        -- Mark as not modified so user can quit if needed
        vim.api.nvim_set_option_value("modified", false, { buf = buf })
      end
    end,
  })

  -- Clean up if buffer is closed another way
  vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(args)
      local win = tonumber(args.match)
      if win == M.state.commit_win or win == M.state.ref_win then
        vim.schedule(function()
          M.close()
        end)
      end
    end,
  })
end

function M.open()
  -- Check if we're in a git repository
  local git_dir = vim.fn.finddir(".git", vim.fn.getcwd() .. ";")
  if git_dir == "" then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  -- Check for staged changes
  vim.fn.system("git diff --cached --quiet")
  if vim.v.shell_error == 0 then
    vim.notify("No staged changes to commit", vim.log.levels.WARN)
    return
  end

  -- Close any existing windows
  M.close()

  local config = M.get_window_config()

  -- Create reference buffer (read-only)
  M.state.ref_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(M.state.ref_buf, 0, -1, false, M.commit_types)
  vim.api.nvim_set_option_value("modifiable", false, { buf = M.state.ref_buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = M.state.ref_buf })

  -- Create reference window (non-focusable)
  M.state.ref_win = vim.api.nvim_open_win(M.state.ref_buf, false, {
    relative = "editor",
    width = config.width,
    height = config.ref.height,
    row = config.ref.row,
    col = config.col,
    border = "rounded",
    title = " Conventional Commits ",
    title_pos = "center",
    focusable = false,
    style = "minimal",
  })

  -- Create commit buffer
  M.state.commit_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(M.state.commit_buf, "COMMIT_MSG")
  vim.api.nvim_set_option_value("filetype", "gitcommit", { buf = M.state.commit_buf })
  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = M.state.commit_buf })

  -- Create commit window (focusable)
  M.state.commit_win = vim.api.nvim_open_win(M.state.commit_buf, true, {
    relative = "editor",
    width = config.width,
    height = config.commit.height,
    row = config.commit.row,
    col = config.col,
    border = "rounded",
    title = " Commit Message ",
    title_pos = "center",
  })

  -- Enter insert mode
  vim.cmd("startinsert")

  -- Set up keymaps and autocmds
  M.setup_keymaps()
  M.setup_autocmds()
end

return M
