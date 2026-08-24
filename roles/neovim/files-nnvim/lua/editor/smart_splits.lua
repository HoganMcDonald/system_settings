local autocmd = require("lib.autocmd")
local pack = require("lib.pack")

---smart-splits' own multiplexer integration discards the tmux exit code and so
---always reports failure. The @pane-is-vim flag tmux reads is managed here.
local function track_tmux_pane()
  if not vim.env.TMUX or not vim.env.TMUX_PANE then
    return
  end

  local pane = vim.env.TMUX_PANE
  local group = vim.api.nvim_create_augroup("Nvim_tmux_pane", { clear = true })

  local function set_flag(value)
    vim.fn.system({ "tmux", "set-option", "-pt", pane, "@pane-is-vim", value })
  end

  set_flag("1")

  autocmd.create({
    event = { autocmd.event("VimLeavePre"), autocmd.event("VimSuspend") },
    group = group,
    callback = function()
      set_flag("0")
    end,
  })

  autocmd.create({
    event = autocmd.event("VimResume"),
    group = group,
    callback = function()
      set_flag("1")
    end,
  })
end

---@type [string, string, string][]
local keymaps = {
  { "<C-h>", "move_cursor_left", "Move to left split" },
  { "<C-j>", "move_cursor_down", "Move to split below" },
  { "<C-k>", "move_cursor_up", "Move to split above" },
  { "<C-l>", "move_cursor_right", "Move to right split" },
  { "<A-=>", "resize_right", "Resize split right" },
  { "<A-->", "resize_left", "Resize split left" },
  { "<leader>wh", "swap_buf_left", "Swap buffer left" },
  { "<leader>wj", "swap_buf_down", "Swap buffer down" },
  { "<leader>wk", "swap_buf_up", "Swap buffer up" },
  { "<leader>wl", "swap_buf_right", "Swap buffer right" },
}

---@type NvimPackKeymap[]
local keys = {}
for _, keymap in ipairs(keymaps) do
  local lhs, action, description = keymap[1], keymap[2], keymap[3]
  table.insert(keys, {
    lhs,
    function()
      require("smart-splits")[action]()
    end,
    desc = description,
  })
end

return {
  src = pack.github("mrjones2014/smart-splits.nvim"),
  version = vim.version.range(">=1.0.0"),
  init = track_tmux_pane,
  keys = keys,
  config = function()
    require("smart-splits").setup({
      default_amount = 3,
      at_edge = "stop",
      move_cursor_same_row = true,
      log_level = "fatal",
      -- Disabled because @pane-is-vim is managed in init above.
      multiplexer_integration = false,
    })
  end,
}
