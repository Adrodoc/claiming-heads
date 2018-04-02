function singleton(name)
  spell:execute('wol spell break byName '..name)
  spell.name = name
end
