local pkg = {}

function pkg.put(multimap, key, value)
  local list = multimap[key] or {}
  table.insert(list, value)
  multimap[key] = list
end

local function getFirstIndex(t, value)
  for i, v in pairs(t) do
    if value == v then
      return i
    end
  end
end

local function removeValue(t, value)
  local index = getFirstIndex(t, value)
  if index ~= nil then
    return table.remove(t, index)
  end
end

function pkg.remove(multimap, key, value)
  local list = multimap[key]
  if list ~= nil then
    removeValue(list, value)
    if next(list) == nil then
      multimap[key] = nil
    end
  end
end

return pkg
