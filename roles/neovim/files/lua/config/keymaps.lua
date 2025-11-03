-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Diffview keybindings (override any defaults)
vim.keymap.set("n", "<leader>gd", function()
  require("diffview").open()
end, { desc = "Open Diffview" })
vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" })
vim.keymap.set("n", "<leader>gh", function()
  vim.cmd("DiffviewFileHistory %")
end, { desc = "File History (current)" })
vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "File History (all)" })

-- Buffer navigation with Tab and Shift+Tab
vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>bprev<cr>", { desc = "Previous buffer" })
