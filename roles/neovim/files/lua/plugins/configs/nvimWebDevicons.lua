-----------------------------------------------------------
-- Dev icons configuration file
-----------------------------------------------------------

-- Plugin: nvim-web-devicons
-- https://github.com/kyazdani42/nvim-web-devicons

local present, icons = pcall(require, 'nvim-web-devicons')
if not present then
  return
end

local colors = require('core.colors').get()

icons.setup({
  override = {
    c = {
      icon = '',
      color = colors.blue,
      name = 'c',
    },
    css = {
      icon = '',
      color = colors.blue,
      name = 'css',
    },
    deb = {
      icon = '',
      color = colors.green,
      name = 'deb',
    },
    Dockerfile = {
      icon = '',
      color = colors.green,
      name = 'Dockerfile',
    },
    html = {
      icon = '',
      color = colors.orange,
      name = 'html',
    },
    jpeg = {
      icon = '',
      color = colors.lavender,
      name = 'jpeg',
    },
    jpg = {
      icon = '',
      color = colors.lavender,
      name = 'jpg',
    },
    js = {
      icon = '',
      color = colors.gold,
      name = 'js',
    },
    kt = {
      icon = '󱈙',
      color = colors.orange,
      name = 'kt',
    },
    lock = {
      icon = '',
      color = colors.red,
      name = 'lock',
    },
    lua = {
      icon = '',
      color = colors.blue,
      name = 'lua',
    },
    mp3 = {
      icon = '',
      color = colors.white,
      name = 'mp3',
    },
    mp4 = {
      icon = '',
      color = colors.white,
      name = 'mp4',
    },
    out = {
      icon = '',
      color = colors.white,
      name = 'out',
    },
    png = {
      icon = '',
      color = colors.lavender,
      name = 'png',
    },
    py = {
      icon = '',
      color = colors.blue,
      name = 'py',
    },
    ['robots.txt'] = {
      icon = 'ﮧ',
      color = colors.red,
      name = 'robots',
    },
    toml = {
      icon = '',
      color = colors.blue,
      name = 'toml',
    },
    ts = {
      icon = 'ﯤ',
      color = colors.green,
      name = 'ts',
    },
    ttf = {
      icon = '',
      color = colors.white,
      name = 'TrueTypeFont',
    },
    rb = {
      icon = '',
      color = colors.red,
      name = 'rb',
    },
    rpm = {
      icon = '',
      color = colors.orange,
      name = 'rpm',
    },
    vue = {
      icon = '﵂',
      color = colors.green,
      name = 'vue',
    },
    woff = {
      icon = '',
      color = colors.white,
      name = 'WebOpenFontFormat',
    },
    woff2 = {
      icon = '',
      color = colors.white,
      name = 'WebOpenFontFormat2',
    },
    xz = {
      icon = '',
      color = colors.gold,
      name = 'xz',
    },
    zip = {
      icon = '',
      color = colors.gold,
      name = 'zip',
    },
  },
})
