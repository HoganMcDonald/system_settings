-- Define a Halcyon-inspired palette. Use the Sublime colors where possible,
-- and create (or approximate) new ones for fields Tokyonight expects but
-- Halcyon doesn’t strictly define.
local halcyon = {
  -- Primary backgrounds
  bg          = '#1d2433',  -- Main background used in Sublime
  bg_dark     = '#171c28',  -- Darker background (e.g. sidebars, title bar)
  bg_highlight= '#2f3b54',  -- Used frequently for selection hover (Sublime highlight)

  -- Foregrounds
  fg          = '#8695b7',  -- Main text color
  fg_dark     = '#6f7b95',  -- Slightly darker text for less-prominent areas
  fg_gutter   = '#3b4261',  -- Gutter color (can be fairly dark)

  -- Accent colors from Halcyon
  yellow      = '#ffcc66',  -- Major accent (matches highlight on hover, etc.)
  -- Halcyon doesn’t explicitly define “orange,” “red,” etc. below, so we generate.
  orange      = '#f8b977',  -- Derived from the main accent
  red         = '#f08370',  -- A warmer accent for “red” contexts
  magenta     = '#c994ff',  -- Generated purple-pink accent
  purple      = '#9d85cf',  -- Another generated variant
  blue        = '#8695b7',  -- Re-use main text color as a subdued “blue”
  cyan        = '#66ccff',  -- Bright cyan
  teal        = '#66ffcc',  -- Another bright variant

  -- Additional background/dark variants
  dark3       = '#282e42',  -- Extra “dark” step if needed
  dark5       = '#2c3244',  -- Another “dark” if needed

  -- Extra greens
  green       = '#80c880',  -- Generated
  green1      = '#73daca',  -- From tokyonight or approximate
  green2      = '#5ba094',  -- Approx

  -- Some extra “blueish” variants Tokyonight often references
  blue0       = '#3d4f6d',
  blue1       = '#4b6080',
  blue2       = '#517ba8',
  blue5       = '#4b607e',
  blue6       = '#8597b5',
  blue7       = '#404e6d',

  -- More magenta / pink
  magenta2    = '#ff66cc',

  -- Another red
  red1        = '#d15460',

  -- GIT colors (add/change/delete). Adjust if desired.
  git = {
    add    = '#449dab', -- Halcyon-ish teal
    change = '#4b6080', -- Re-used “blueish” tone
    delete = '#914c54', -- Borrowed from the original Tokyonight
  },
}

return {
  {
    'kwsp/halcyon-neovim',
    lazy = false,
    priority = 1000,
    config = function(_, opts)
      vim.cmd.colorscheme('halcyon')

      -- Set up custom Telescope highlights
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
    end,
  },
}
