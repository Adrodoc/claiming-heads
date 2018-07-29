-- claiming-heads/singleton.lua 
return function(name)
  spell:execute('wol spell break byName '..name)
  spell.name = name
end
