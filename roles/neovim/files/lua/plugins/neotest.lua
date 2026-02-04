return {
  { "nvim-neotest/neotest-jest" },
  {
    "nvim-neotest/neotest",
    config = function()
      require("neotest").setup({
        adapters = {
          require("rustaceanvim.neotest"),
          require("neotest-jest")({
            jestConfigFile = function(file)
              if file:find("/packages/") then
                local match = file:match("(.*/packages/[^/]+/)")
                if match then
                  return match .. "jest.config.js"
                end
              end
              return vim.fn.getcwd() .. "/jest.config.js"
            end,
            cwd = function(file)
              if file:find("/packages/") then
                local match = file:match("(.*/packages/[^/]+/)")
                if match then
                  return match
                end
              end
              return vim.fn.getcwd()
            end,
          }),
        },
      })
    end,
  },
}
