local pack = require("lib.pack")

local function resolve_rust_analyzer()
  for _, directory in ipairs(vim.split(vim.env.PATH or "", ":")) do
    if not directory:match("asdf") then
      local candidate = vim.fs.joinpath(directory, "rust-analyzer")
      if vim.uv.fs_stat(candidate) then
        return candidate
      end
    end
  end

  local rustup = vim.fn.system({ "rustup", "which", "rust-analyzer" })
  if vim.v.shell_error == 0 then
    local path = vim.trim(rustup)
    if path ~= "" then
      return path
    end
  end

  return "rust-analyzer"
end

return {
  src = pack.github("mrcjkb/rustaceanvim"),
  -- rustaceanvim reads its options from this global while its plugin script loads.
  init = function()
    vim.g.rustaceanvim = {
      server = {
        cmd = { resolve_rust_analyzer() },
      },
    }
  end,
}
