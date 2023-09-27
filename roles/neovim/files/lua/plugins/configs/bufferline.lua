-----------------------------------------------------------
-- Tab line configuration file
-----------------------------------------------------------

-- Plugin: bufferline
-- https://github.com/akinsho/bufferline.nvim

local present, bufferline = pcall(require, 'bufferline')

if not present then
  return
end

local api = vim.api
local lsp = vim.lsp
local colors = require('core.colors').get()

bufferline.setup({
  options = {
    offsets = { { filetype = 'NvimTree', text = '', padding = 1 } },
    buffer_close_icon = '',
    modified_icon = '',
    close_icon = '',
    numbers = 'none',
    show_close_icon = false,
    left_trunc_marker = '',
    right_trunc_marker = '',
    max_name_length = 16,
    max_prefix_length = 13,
    tab_size = 20,
    show_tab_indicators = true,
    enforce_regular_tabs = false,
    view = 'multiwindow',
    show_buffer_close_icons = true,
    -- separator_style = { "", "" },
    separator_style = 'thin',
    indicator = {
      icon = ' ',
      style = 'icon',
    },
    always_show_bufferline = true,
    diagnostics = false,
    custom_filter = function(buf_number)
      -- Func to filter out our managed/persistent split terms
      local present_type, type = pcall(function()
        return api.nvim_buf_get_var(buf_number, 'term_type')
      end)

      if present_type then
        if type == 'vert' then
          return false
        elseif type == 'hori' then
          return false
        end
        return true
      end

      return true
    end,
  },
  highlights = {
    background = {
      fg = colors.off_white,
      bg = colors.highlight,
    },
    fill = {
      fg = colors.off_white,
      bg = colors.highlight,
    },

    -- Buffers
    buffer_selected = {
      fg = colors.white,
      bg = colors.bg,
      bold = true
    },
    buffer_visible = {
      fg = colors.off_white,
      bg = colors.highlight,
    },

    -- Diagnostics
    error = {
      fg = colors.red,
      bg = colors.red,
    },
    error_diagnostic = {
      fg = colors.red,
      bg = colors.red,
    },

    -- Close buttons
    close_button = {
      fg = colors.off_white,
      bg = colors.highlight,
    },
    close_button_visible = {
      fg = colors.off_white,
      bg = colors.highlight,
    },
    close_button_selected = {
      fg = colors.white,
      bg = colors.bg,
    },

    -- indicator
    indicator_visible = {
      fg = colors.highlight,
      bg = colors.highlight,
    },
    indicator_selected = {
      fg = colors.bg,
      bg = colors.bg,
    },

    -- Modified
    modified = {
      fg = colors.lavender,
      bg = colors.highlight,
    },
    modified_visible = {
      fg = colors.lavender,
      bg = colors.highlight,
    },
    modified_selected = {
      fg = colors.lavender,
      bg = colors.bg,
    },

    -- Separators
    separator = {
      fg = colors.black,
      bg = colors.highlight,
    },
    separator_visible = {
      fg = colors.black,
      bg = colors.highlight,
    },
    separator_selected = {
      fg = colors.black,
      bg = colors.bg,
    },

    -- Tabs
    tab = {
      fg = colors.off_white,
      bg = colors.highlight,
    },
    tab_selected = {
      fg = colors.white,
      bg = colors.bg,
    },
    tab_close = {
      fg = colors.white,
      bg = colors.bg,
    },

    -- pick indicators
    pick = {
      fg = colors.orange,
      bg = colors.highlight,
    },
    pick_visible = {
      fg = colors.orange,
      bg = colors.highlight,
    },
    pick_selected = {
      fg = colors.orange,
      bg = colors.bg,
    },

    -- duplicate
    duplicate = {
      fg = colors.off_white,
      bg = colors.highlight,
      italic = true
    },
    duplicate_visible = {
      fg = colors.off_white,
      bg = colors.highlight,
      italic = true
    },
    duplicate_selected = {
      fg = colors.white,
      bg = colors.bg,
      italic = true
    },
  },
})
