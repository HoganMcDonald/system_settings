-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Copy current file path to clipboard
vim.keymap.set("n", "<leader>fy", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied to clipboard: " .. path, vim.log.levels.INFO)
end, { desc = "Copy file path" })

-- Diffview keybindings (replaces lazygit)
vim.keymap.set("n", "<leader>gg", function()
  local lib = require("diffview.lib")
  local view = lib.get_current_view()
  if view then
    vim.cmd("DiffviewClose")
  else
    vim.cmd("DiffviewOpen")
  end
end, { desc = "Toggle Diffview" })
vim.keymap.set("n", "<leader>gh", function()
  vim.cmd("DiffviewFileHistory %")
end, { desc = "File History (current)" })
vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "File History (all)" })
