local M = {}

---@class NvimBrand<T, B>
---@field _brand B
---@field _value T

---Create functions for wrapping and unwrapping a branded value.
---@generic T, B: string
---@param brand_name B
---@param is_t fun(value: T): boolean
---@return fun(value: T): NvimBrand<T, B> brand
---@return fun(value: NvimBrand<T, B>): T unwrap
function M.create_brand(brand_name, is_t)
  assert(type(brand_name) == "string" and brand_name ~= "", "brand_name must be a non-empty string")
  assert(type(is_t) == "function", "is_t must be a function")

  local function brand(value)
    assert(is_t(value), "cannot brand value: invalid type")

    return {
      _brand = brand_name,
      _value = value,
    }
  end

  local function unwrap(value)
    assert(type(value) == "table", "cannot unwrap value: expected a table with keys _brand and _value")
    assert(value._brand == brand_name, "cannot unwrap value: invalid brand")
    assert(is_t(value._value), "cannot unwrap value: invalid branded value")

    return value._value
  end

  return brand, unwrap
end

return M
