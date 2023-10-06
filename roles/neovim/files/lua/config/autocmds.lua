local M = {}

local commands = {
  system = {
    {
      -- close some filetypes with <q>
      event = 'FileType',
      pattern = {
        'PlenaryTestPopup',
        'help',
        'lspinfo',
        'man',
        'notify',
        'qf',
        'spectre_panel',
        'startuptime',
        'tsplayground',
        'neotest-output',
        'checkhealth',
        'neotest-summary',
        'neotest-output-panel',
      },
      command = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
      end,
    },
    {
      -- Auto create dir when saving a file, in case some intermediate directory does not exist
      event = 'BufWritePre',
      command = function(event)
        if event.match:match('^%w%w+://') then
          return
        end
        local file = vim.loop.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
      end,
    },
  },
  editor = {
    {
      -- resize splits if window resized
      event = 'VimResized',
      command = function()
        vim.cmd('tabdo wincmd =')
      end,
    },
    {
      -- highlight on yank
      event = 'TextYankPost',
      command = function()
        vim.highlight.on_yank()
      end,
    },
    {
      -- remove trailing whitespace on save
      event = 'BufWritePre',
      pattern = '*',
      command = ':%s/\\s\\+$//e',
    },
    {
      -- Open a file from its last left off position
      event = 'BufReadPost',
      pattern = '*',
      command = function()
        local exclude = { 'gitcommit' }
        local buf = vim.api.nvim_get_current_buf()
        if vim.tbl_contains(exclude, vim.bo[buf].filetype) then
          return
        end
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
          pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
      end,
    },
    {
      -- Check if we need to reload the file when it changed
      event = { 'FocusGained', 'TermClose', 'TermLeave' },
      command = 'checktime',
    },
    {
      -- switches to non-relative numbers on insert
      event = 'InsertEnter',
      pattern = '*',
      command = 'set number norelativenumber',
    },
    {
      -- switches to relative numbers in normal
      event = 'InsertLeave',
      pattern = '*',
      command = 'set number relativenumber',
    },
    {
      -- wrap and check for spell in text filetypes
      event = 'FileType',
      pattern = { 'gitcommit', 'markdown' },
      command = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
      end,
    },
  },
  terminal = {
    {
      -- maps escape in buffer when terminal opens
      event = 'TermOpen',
      pattern = '*',
      command = [[tnoremap <buffer> <Esc> <c-\><c-n>]],
    },
    {
      -- starts in insert mode when terminal opens
      event = 'TermOpen',
      pattern = '*',
      command = 'startinsert',
    },
    {
      -- removes all line numbers when terminal opens
      event = 'TermOpen',
      pattern = '*',
      command = 'setlocal listchars= nonumber norelativenumber',
    },
  },
  ruby = {
    {
      -- sets filetype of jbuilder files
      event = { 'BufNewFile', 'BufRead' },
      pattern = '*.json.jbuilder',
      command = 'set ft=ruby',
    },
  },
}

local function create_group(name)
  vim.api.nvim_create_augroup(name, { clear = true })
end

local function create_command(event, group, pattern, command)
  if type(command) == 'function' then
    vim.api.nvim_create_autocmd(event, { group = group, pattern = pattern, callback = command })
  else
    vim.api.nvim_create_autocmd(event, { pattern = pattern, command = command })
  end
end

function M.setup()
  for group_name, definitions in pairs(commands) do
    local group = create_group(group_name)
    for _, def in ipairs(definitions) do
      create_command(def.event, group, def.pattern, def.command)
    end
  end
end

return M
