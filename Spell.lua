-- claiming-heads/Spell.lua

function Spell:getBlock(pos)
  self.pos = pos
  return self.block
end
