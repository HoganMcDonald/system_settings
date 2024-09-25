return {
  settings = {
    solargraph = {
      root_dir = require('lspconfig').util.root_pattern('Gemfile', '.git')() or vim.fn.getcwd(),
      useBundler = true,
      cmd = {
        'asdf',
        'exec',
        'solargraph',
        'stdio',
      },
      flags = {
        debounce_text_changes = 150,
      },
    },
  },
}
