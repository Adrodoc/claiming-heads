-- claiming-heads/datastore.lua

local pkg = {}

function pkg.save(pos, data)
  local oldPos = spell.pos
  local text = str(data)
  spell.pos = pos
  spell.block = Blocks.get("command_block"):withNbt({Command=text})
  spell.pos = oldPos
end

function pkg.load(pos)
  local oldPos = spell.pos
  spell.pos = pos
  local block = spell.block
  if block.nbt and block.nbt.Command then
    local text = block.nbt.Command
    if text ~= nil then
      local code = "return "..text
      local func = load(code)
      local result = func()
      return result
    end
  end
  return nil
end

return pkg