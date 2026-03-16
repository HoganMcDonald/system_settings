local function resolve_rust_analyzer()
  local paths = vim.split(vim.env.PATH or "", ":")
  for _, dir in ipairs(paths) do
    if not dir:match("asdf") then
      local candidate = dir .. "/rust-analyzer"
      if vim.uv.fs_stat(candidate) then
        return candidate
      end
    end
  end

  local rustup = vim.fn.system("rustup which rust-analyzer 2>/dev/null")
  if vim.v.shell_error == 0 then
    local path = vim.trim(rustup)
    if path ~= "" then
      return path
    end
  end

  return "rust-analyzer"
end

return {
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        cmd = { resolve_rust_analyzer() },
      },
    },
  },
}
