-- claiming-heads/singleton.lua

return function(name)
  spell:execute([[wol spell break byName "%s"]],name)
  spell.name = name
end
