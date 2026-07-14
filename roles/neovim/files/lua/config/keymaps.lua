-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Copy current file path to clipboard
vim.keymap.set("n", "<leader>fy", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied to clipboard: " .. path, vim.log.levels.INFO)
end, { desc = "Copy file path" })

-- CodeDiff keybindings (replaces lazygit)
vim.keymap.set("n", "<leader>gg", "<cmd>CodeDiff<cr>", { desc = "CodeDiff" })
vim.keymap.set("n", "<leader>gh", function()
  vim.cmd("CodeDiff history %")
end, { desc = "CodeDiff History (current)" })
vim.keymap.set("n", "<leader>gH", "<cmd>CodeDiff history<cr>", { desc = "CodeDiff History (all)" })
