local autocmd = require("lib.autocmd")

local function augroup(name)
  return vim.api.nvim_create_augroup("Nvim_" .. name, { clear = true })
end

autocmd.create({
  event = {
    autocmd.event("BufEnter"),
    autocmd.event("CursorHold"),
    autocmd.event("FocusGained"),
    autocmd.event("TermClose"),
    autocmd.event("TermLeave"),
  },
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd.checktime()
    end
  end,
})

autocmd.create({
  event = autocmd.event("TextYankPost"),
  group = augroup("highlight_yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

autocmd.create({
  event = autocmd.event("VimResized"),
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

autocmd.create({
  event = autocmd.event("BufReadPost"),
  group = augroup("last_location"),
  callback = function(args)
    if vim.bo[args.buf].filetype == "gitcommit" or vim.b[args.buf].nvim_last_location then
      return
    end

    vim.b[args.buf].nvim_last_location = true
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

autocmd.create({
  event = autocmd.event("FileType"),
  group = augroup("close_with_q"),
  pattern = { "checkhealth", "help", "lspinfo", "qf" },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true, desc = "Quit buffer" })
  end,
})

autocmd.create({
  event = autocmd.event("FileType"),
  group = augroup("man_unlisted"),
  pattern = "man",
  callback = function(args)
    vim.bo[args.buf].buflisted = false
  end,
})

autocmd.create({
  event = autocmd.event("FileType"),
  group = augroup("wrap_spell"),
  pattern = { "gitcommit", "markdown", "plaintex", "text", "typst" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.wrap = true
  end,
})

autocmd.create({
  event = autocmd.event("FileType"),
  group = augroup("json_conceal"),
  pattern = { "json", "json5", "jsonc" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

autocmd.create({
  event = autocmd.event("BufWritePre"),
  group = augroup("create_parent_directory"),
  callback = function(args)
    if args.match:match("^%w%w+:[\\/][\\/]") then
      return
    end

    local file = vim.uv.fs_realpath(args.match) or args.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
