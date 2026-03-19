--- Shared utility functions for the SketchyBar library

local M = {}

--- Shallow-copy a config table, one level deep for nested tables
--- @param t table The table to copy
--- @return table A shallow copy
function M.shallow_copy(t)
  local copy = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      local inner = {}
      for k2, v2 in pairs(v) do inner[k2] = v2 end
      copy[k] = inner
    else
      copy[k] = v
    end
  end
  return copy
end

return M
