-- claiming-heads/datastore.lua
local pkg = {}
local dir = "wol/claiming-heads"
local filename = dir.."/claims.txt"


function pkg.save(data)
  local t1 = Time.realtime
  System.makeDir(dir)
  local file,err = io.open(filename,"w")
  if err then
    error(err)
  end
  local text = str(data)
  file:write(text)
  file:close()
  local t2 = Time.realtime
  --print("save duration", t2-t1)
end

function pkg.load()
  local t1 = Time.realtime
  if not System.isFile(filename) then
    return nil
  end
  local file,err = io.open(filename,"r")
  if err then
    error(err)
  end
  local text = file:read("*a")
  file:close()
  local result = nil
  if text ~= nil then
    local code = "return "..text
    local func = load(code)
    result = func()
  end
  local t2 = Time.realtime
  --print("load duration", t2-t1)
  return result
end

return pkg
