<<<<<<< HEAD
local M = {}

M.is_dark_mode = function()
    local handle = io.popen('defaults read -globalDomain AppleInterfaceStyle')
    if handle == nil then
        return false -- Fallback to light mode if popen fails
    end
    local result = handle:read("*a")
    handle:close()
    if result == nil then
        return false -- Fallback to light mode if read fails
    end
    return result:match("Dark") ~= nil
end

if M.is_dark_mode() then
    M.colors = require("colors_dark")
else
    M.colors = require("colors_light")
=======
local is_dark_mode = function()
  local handle = io.popen('defaults read -globalDomain AppleInterfaceStyle')
  if handle == nil then
    return false     -- Fallback to light mode if popen fails
  end
  local result = handle:read("*a")
  handle:close()
  if result == nil then
    return false     -- Fallback to light mode if read fails
  end
  return result:match("Dark") ~= nil
end

if is_dark_mode() then
  return require("colors_dark")
else
  return require("colors_light")
>>>>>>> 239ca03 (wip)
end

return M
