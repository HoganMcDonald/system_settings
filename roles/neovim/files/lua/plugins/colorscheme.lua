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
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    opts = {
      on_colors = function(c)
        -- Override Tokyonight’s palette with our Halcyon-inspired table.
        -- Any fields not overridden will fall back to Tokyonight defaults.
        c.bg = halcyon.bg
        c.bg_dark = halcyon.bg_dark
        c.bg_highlight = halcyon.bg_highlight
        c.fg = halcyon.fg
        c.fg_dark = halcyon.fg_dark
        c.fg_gutter = halcyon.fg_gutter
        c.comment = '#a2aabc' -- If you want Halcyon’s arrow color as "comment"

        -- Accent
        c.yellow = halcyon.yellow
        c.orange = halcyon.orange
        c.red = halcyon.red
        c.magenta = halcyon.magenta
        c.purple = halcyon.purple
        c.blue = halcyon.blue
        c.cyan = halcyon.cyan
        c.teal = halcyon.teal

        -- Dark “levels”
        c.dark3 = halcyon.dark3
        c.dark5 = halcyon.dark5

        -- More greens, if you want them
        c.green = halcyon.green
        c.green1 = halcyon.green1
        c.green2 = halcyon.green2

        -- More blues
        c.blue0 = halcyon.blue0
        c.blue1 = halcyon.blue1
        c.blue2 = halcyon.blue2
        c.blue5 = halcyon.blue5
        c.blue6 = halcyon.blue6
        c.blue7 = halcyon.blue7

        -- Additional magenta / red
        c.magenta2 = halcyon.magenta2
        c.red1 = halcyon.red1

        -- Git
        c.git = halcyon.git
      end,
      on_highlights = function(hl, c)
        -- (Optional) Example of customizing highlight groups
        -- for Telescope, etc. Keep or remove to your liking.
        local prompt = '#2d3149'
        hl.TelescopeNormal = {
          bg = c.bg_dark,
          fg = c.fg_dark,
        }
        hl.TelescopeBorder = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
        hl.TelescopePromptNormal = {
          bg = prompt,
        }
        hl.TelescopePromptBorder = {
          bg = prompt,
          fg = prompt,
        }
        hl.TelescopePromptTitle = {
          bg = prompt,
          fg = c.fg,
        }
        hl.TelescopePreviewTitle = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
        hl.TelescopeResultsTitle = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
      end,
    },
    config = function(_, opts)
      require('tokyonight').setup(opts)
      vim.cmd.colorscheme('tokyonight')
    end,
  },
}
