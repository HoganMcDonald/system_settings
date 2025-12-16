-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Enable format on save by default (toggle with <leader>uf)
vim.g.autoformat = true

-- Ensure enough room for UI elements (dropbar + noice)
vim.opt.cmdheight = 1 -- Command line height
vim.opt.winminheight = 1 -- Minimum window height

-- Reduce timeout for key sequences (fixes Alt key delay on macOS)
vim.opt.timeoutlen = 300 -- Time to wait for a mapped sequence (default: 1000)
vim.opt.ttimeoutlen = 10 -- Time to wait for key code sequence (for terminal codes like Alt keys)

-- Enable line wrapping
vim.opt.wrap = true -- Wrap long lines
vim.opt.linebreak = true -- Break lines at word boundaries
vim.opt.breakindent = true -- Maintain indent when wrapping

-- Use virtual lines for diagnostics on current line, virtual text elsewhere
vim.diagnostic.config({
  virtual_text = true,
  virtual_lines = { current_line = true },
  underline = true,
  update_in_insert = false,
})

-- Disable virtual text when on a line with diagnostics (show only virtual lines)
local og_virt_text
local og_virt_line
vim.api.nvim_create_autocmd({ "CursorMoved", "DiagnosticChanged" }, {
  group = vim.api.nvim_create_augroup("diagnostic_only_virtlines", {}),
  callback = function()
    if og_virt_line == nil then
      og_virt_line = vim.diagnostic.config().virtual_lines
    end

    if not (og_virt_line and og_virt_line.current_line) then
      if og_virt_text then
        vim.diagnostic.config({ virtual_text = og_virt_text })
        og_virt_text = nil
      end
      return
    end

    if og_virt_text == nil then
      og_virt_text = vim.diagnostic.config().virtual_text
    end

    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

    if vim.tbl_isempty(vim.diagnostic.get(0, { lnum = lnum })) then
      vim.diagnostic.config({ virtual_text = og_virt_text })
    else
      vim.diagnostic.config({ virtual_text = false })
    end
  end,
})

-- Immediately redraw diagnostics on mode change
vim.api.nvim_create_autocmd("ModeChanged", {
  group = vim.api.nvim_create_augroup("diagnostic_redraw", {}),
  callback = function()
    pcall(vim.diagnostic.show)
  end,
})
