-- Define a Halcyon-inspired palette. Use the Sublime colors where possible,
-- and create (or approximate) new ones for fields Tokyonight expects but
-- Halcyon doesn’t strictly define.
local halcyon = {
  -- Primary backgrounds
  bg = '#1d2433', -- Main background used in Sublime
  bg_dark = '#171c28', -- Darker background (e.g. sidebars, title bar)
  bg_highlight = '#2f3b54', -- Used frequently for selection hover (Sublime highlight)

  -- Foregrounds
  fg = '#8695b7', -- Main text color
  fg_dark = '#6f7b95', -- Slightly darker text for less-prominent areas
  fg_gutter = '#3b4261', -- Gutter color (can be fairly dark)

  -- Accent colors from Halcyon
  yellow = '#ffcc66', -- Major accent (matches highlight on hover, etc.)
  yellow_bg = '#2e2a2d',
  -- Halcyon doesn’t explicitly define “orange,” “red,” etc. below, so we generate.
  orange = '#f8b977', -- Derived from the main accent
  red = '#f08370', -- A warmer accent for “red” contexts
  red_bg = '#2d202a',
  magenta = '#c994ff', -- Generated purple-pink accent
  purple = '#9d85cf', -- Another generated variant
  blue = '#8695b7', -- Re-use main text color as a subdued “blue”
  cyan = '#66ccff', -- Bright cyan
  teal = '#66ffcc', -- Another bright variant
  teal_bg = '#1a2b32',

  -- Additional background/dark variants
  dark3 = '#282e42', -- Extra “dark” step if needed
  dark5 = '#2c3244', -- Another “dark” if needed

  -- Extra greens
  green = '#80c880', -- Generated
  green1 = '#73daca', -- From tokyonight or approximate
  green2 = '#5ba094', -- Approx

  -- Some extra “blueish” variants Tokyonight often references
  blue0 = '#3d4f6d',
  blue1 = '#4b6080',
  blue2 = '#517ba8',
  blue5 = '#4b607e',
  blue6 = '#8597b5',
  blue7 = '#404e6d',
  blue_bg = '#192b38',

  -- More magenta / pink
  magenta2 = '#ff66cc',

  -- Another red
  red1 = '#d15460',

  -- GIT colors (add/change/delete). Adjust if desired.
  git = {
    add = '#66ffcc', -- Halcyon teal
    change = '#c994ff', -- Halcyon magenta
    delete = '#f08370', -- Halcyon red
  },
}

return {
  {
    'kwsp/halcyon-neovim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'halcyon'

      -- Telescope
      local prompt = halcyon.bg_highlight
      vim.api.nvim_set_hl(0, 'TelescopeNormal', {
        bg = halcyon.bg_dark,
        fg = halcyon.fg_dark,
      })
      vim.api.nvim_set_hl(0, 'TelescopeBorder', {
        bg = halcyon.bg_dark,
        fg = halcyon.bg_dark,
      })
      vim.api.nvim_set_hl(0, 'TelescopePromptNormal', {
        bg = prompt,
      })
      vim.api.nvim_set_hl(0, 'TelescopePromptBorder', {
        bg = prompt,
        fg = prompt,
      })
      vim.api.nvim_set_hl(0, 'TelescopePromptTitle', {
        bg = prompt,
        fg = halcyon.fg,
      })
      vim.api.nvim_set_hl(0, 'TelescopePreviewTitle', {
        bg = halcyon.bg_dark,
        fg = halcyon.bg_dark,
      })
      vim.api.nvim_set_hl(0, 'TelescopeResultsTitle', {
        bg = halcyon.bg_dark,
        fg = halcyon.bg_dark,
      })

      -- Neovim UI
      -- Window separators
      vim.api.nvim_set_hl(0, 'WinSeparator', {
        fg = halcyon.bg_highlight,
      })
      vim.api.nvim_set_hl(0, 'VertSplit', {
        fg = halcyon.bg_highlight,
      })
      -- Diagnostics
      vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextError', {
        fg = halcyon.red,
        bg = halcyon.red_bg,
      })
      vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextWarn', {
        fg = halcyon.yellow,
        bg = halcyon.yellow_bg,
      })
      vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextInfo', {
        fg = halcyon.blue2,
        bg = halcyon.blue_bg,
      })
      vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextHint', {
        fg = halcyon.teal,
        bg = halcyon.teal_bg,
      })
    end,
  },
}
