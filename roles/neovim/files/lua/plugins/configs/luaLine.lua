-----------------------------------------------------------
-- Statusline configuration file
-----------------------------------------------------------

-- Plugin: lualine
-- https://github.com/neovim/nvim-lspconfig

local present, lualine = pcall(require, 'lualine')

if not present then
  return
end

local fn = vim.fn
local api = vim.api
local lsp = vim.lsp
local colors = require('core.colors').get()

local conditions = {
  buffer_not_empty = function()
    return fn.empty(fn.expand('%:t')) ~= 1
  end,
  hide_in_width = function()
    return fn.winwidth(0) > 80
  end,
  check_git_workspace = function()
    local filepath = fn.expand('%:p:h')
    local gitdir = fn.finddir('.git', filepath .. ';')
    return gitdir and #gitdir > 0 and #gitdir < #filepath
  end,
}

-- Config
local config = {
  options = {
    globalstatus = true,
    -- Disable sections and component separators
    component_separators = '',
    section_separators = '',
    theme = {
      -- We are going to use lualine_c an lualine_x as left and
      -- right section. Both are highlighted by c theme .  So we
      -- are just setting default looks o statusline
      normal = { c = { fg = colors.off_white, bg = colors.highlight } },
      inactive = { c = { fg = colors.off_white, bg = colors.highlight } },
    },
  },
  sections = {
    -- these are to remove the defaults
    lualine_a = {},
    lualine_b = {},
    lualine_y = {},
    lualine_z = {},
    -- These will be filled later
    lualine_c = {},
    lualine_x = {},
  },
  inactive_sections = {
    -- these are to remove the defaults
    lualine_a = {},
    lualine_b = {},
    lualine_y = {},
    lualine_z = {},
    lualine_c = {},
    lualine_x = {},
  },
}

-- Inserts a component in lualine_c at left section
local function ins_left(component)
  table.insert(config.sections.lualine_c, component)
end

-- Inserts a component in lualine_x ot right section
local function ins_right(component)
  table.insert(config.sections.lualine_x, component)
end

ins_left({
  function()
    return '▊'
  end,
  color = { fg = colors.blue }, -- Sets highlighting of component
  padding = { left = 0, right = 1 }, -- We don't need space before this
})

ins_left({
  -- mode component
  function()
    -- auto change color according to neovims mode
    local mode_color = {
      n = colors.red,
      i = colors.green,
      v = colors.blue,
      [''] = colors.blue,
      V = colors.blue,
      c = colors.lavender,
      no = colors.red,
      s = colors.orange,
      S = colors.orange,
      ic = colors.yellow,
      R = colors.lavender,
      Rv = colors.lavender,
      cv = colors.red,
      ce = colors.red,
      r = colors.gold,
      rm = colors.gold,
      ['r?'] = colors.gold,
      ['!'] = colors.red,
      t = colors.red,
    }
    api.nvim_command('hi! LualineMode guifg=' .. mode_color[fn.mode()] .. ' guibg=' .. colors.highlight)
    return ''
  end,
  color = 'LualineMode',
  padding = { right = 1 },
})

ins_left({
  -- filesize component
  'filesize',
  cond = conditions.buffer_not_empty,
})

ins_left({
  'filename',
  cond = conditions.buffer_not_empty,
  color = { fg = colors.gold, gui = 'bold' },
})

ins_left({ 'location' })

ins_left({ 'progress', color = { fg = colors.off_white, gui = 'bold' } })

ins_left({
  'diagnostics',
  sources = { 'nvim_diagnostic' },
  symbols = { error = ' ', warn = ' ', info = ' ' },
  diagnostics_color = {
    color_error = { fg = colors.red },
    color_warn = { fg = colors.yellow },
    color_info = { fg = colors.blue },
  },
})

ins_left({
  -- Lsp server name .
  function()
    local msg = ''
    local buf_ft = api.nvim_buf_get_option(0, 'filetype')
    local clients = lsp.get_active_clients()
    if next(clients) == nil then
      return msg
    end
    for _, client in ipairs(clients) do
      local filetypes = client.config.filetypes
      if filetypes and fn.index(filetypes, buf_ft) ~= -1 then
        return client.name
      end
    end
    return msg
  end,
  icon = '',
  color = { fg = colors.white, gui = 'bold' },
})

-- Insert mid section. You can make any number of sections in neovim :)
-- for lualine it's any number greater then 2
--[[ ins_left({
  function()
    return '%='
  end,
}) ]]

-- Add components to right sections
ins_right({
  'o:encoding', -- option component same as &encoding in viml
  fmt = string.upper, -- I'm not sure why it's upper case either ;)
  cond = conditions.hide_in_width,
  color = { fg = colors.off_white },
})

ins_right({
  'fileformat',
  fmt = string.upper,
  icons_enabled = false, -- I think icons are cool but Eviline doesn't have them. sigh
  color = { fg = colors.off_white },
})

ins_right({
  'branch',
  icon = '',
  color = { fg = colors.lavender, gui = 'bold' },
})

ins_right({
  'diff',
  -- Is it me or the symbol for modified us really weird
  symbols = { added = ' ', modified = '柳 ', removed = ' ' },
  diff_color = {
    added = { fg = colors.green },
    modified = { fg = colors.blue },
    removed = { fg = colors.red },
  },
  cond = conditions.hide_in_width,
})

ins_right({
  function()
    return '▊'
  end,
  color = { fg = colors.blue },
  padding = { left = 1 },
})

-- Now don't forget to initialize lualine
lualine.setup(config)
