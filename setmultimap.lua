-- claiming/setmultimap.lua

local pkg = {}

function pkg.put(multimap, key, value, hashfunction)
  hashfunction = hashfunction or str
  local set = multimap[key] or {}
  local hash = hashfunction(value)
  set[hash] = value
  multimap[key] = set
end

function pkg.remove(multimap, key, value)
  hashfunction = hashfunction or str
  local set = multimap[key]
  if set ~= nil then
    local hash = hashfunction(value)
    set[hash] = nil
    if next(set) == nil then
      multimap[key] = nil
    end
  end
end

return pkg
