local map = vim.keymap.set

map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up" })

map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move up" })
map("i", "<A-j>", "<esc><cmd>move .+1<cr>==gi", { desc = "Move down" })
map("i", "<A-k>", "<esc><cmd>move .-2<cr>==gi", { desc = "Move up" })
map("x", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move down" })
map("x", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move up" })

map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bb", "<cmd>edit #<cr>", { desc = "Switch to other buffer" })
map("n", "<leader>`", "<cmd>edit #<cr>", { desc = "Switch to other buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd.nohlsearch()
  -- hlslens marks itself inactive after a `nohlsearch`; mirror that so its
  -- lens is rebuilt on the next `n`/`N` jump instead of going stale.
  local ok, hlslens = pcall(require, "hlslens")
  if ok then
    hlslens.stop()
  end
  return "<esc>"
end, { expr = true, desc = "Escape and clear search" })

map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next search result" })
map({ "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Previous search result" })
map({ "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous search result" })

map("i", ",", ",<C-g>u")
map("i", ".", ".<C-g>u")
map("i", ";", ";<C-g>u")
map({ "i", "n", "s", "x" }, "<C-s>", "<cmd>write<cr><esc>", { desc = "Save file" })
map("x", "<", "<gv")
map("x", ">", ">gv")

map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New file" })
map({ "n", "x" }, "<leader>cf", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format" })

local function diagnostic_jump(count, severity)
  return function()
    vim.diagnostic.jump({ count = count * vim.v.count1, severity = severity, float = true })
  end
end

map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "]d", diagnostic_jump(1), { desc = "Next diagnostic" })
map("n", "[d", diagnostic_jump(-1), { desc = "Previous diagnostic" })
map("n", "]e", diagnostic_jump(1, vim.diagnostic.severity.ERROR), { desc = "Next error" })
map("n", "[e", diagnostic_jump(-1, vim.diagnostic.severity.ERROR), { desc = "Previous error" })
map("n", "]w", diagnostic_jump(1, vim.diagnostic.severity.WARN), { desc = "Next warning" })
map("n", "[w", diagnostic_jump(-1, vim.diagnostic.severity.WARN), { desc = "Previous warning" })

map("n", "<leader>xq", function()
  local open = vim.fn.getqflist({ winid = 0 }).winid ~= 0
  pcall(open and vim.cmd.cclose or vim.cmd.copen)
end, { desc = "Quickfix list" })
map("n", "<leader>xl", function()
  local open = vim.fn.getloclist(0, { winid = 0 }).winid ~= 0
  pcall(open and vim.cmd.lclose or vim.cmd.lopen)
end, { desc = "Location list" })
map("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

map("n", "<leader>-", "<C-w>s", { remap = true, desc = "Split window below" })
map("n", "<leader>|", "<C-w>v", { remap = true, desc = "Split window right" })
map("n", "<leader>ws", "<C-w>s", { remap = true, desc = "Split window below" })
map("n", "<leader>wv", "<C-w>v", { remap = true, desc = "Split window right" })
map("n", "<leader>wd", "<C-w>c", { remap = true, desc = "Delete window" })
map("n", "<leader>qq", "<cmd>quitall<cr>", { desc = "Quit all" })

map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close other tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous tab" })

-- Mapped here rather than alongside the fugitive keys: the commit float is
-- self-contained, and routing it through a plugin spec would load fugitive.
map("n", "<leader>gc", function()
  require("lib.git_commit").open()
end, { desc = "Create commit" })

map("n", "<leader>fy", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied to clipboard: " .. path)
end, { desc = "Copy file path" })
