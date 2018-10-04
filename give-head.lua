-- claiming-heads/give-head.lua
-- /lua require('claiming-heads.give-head').enable(true)

local pkg = {}
local module = ...
local CMD = 'give-head'
local showError
local getPlayers
local namesOf
local tell

function pkg.enable(value)
  value = value or true
  if value then
    Commands.register(CMD,string.format([[
      require('%s').giveHead(...)
    ]], module))
  else
    pcall(function() 
      Commands.deregister(CMD)
    end)
  end
end

function pkg.giveHead(toSelector, headSelector)
  if not toSelector then
    showError("Usage: /give-head <player> [<head's owner>]", to)
    return
  end
  local toPlayers = getPlayers(toSelector)
  local heads = nil
  if headSelector then
    heads = getPlayers(headSelector)
  end
  for _,p in pairs(toPlayers) do
    if heads then
      for _,h in pairs(heads) do
        spell:execute([[/give %s skull 1 3 {SkullOwner:"%s"}]], p, h)
      end
    else
      spell:execute([[/give %s skull 1 3 {SkullOwner:"%s"}]], p, p)
    end
  end
end

function getPlayers(selector)
  local prefix = string.sub(selector, 1, 1)
  if prefix=="@" then
    return namesOf(Entities.find(selector))
  end
  local players = Entities.find(string.format("@a[name=%s]",selector))
  if #players == 0 then
    return {selector}
  else
    return namesOf(players)
  end
end

function namesOf(players)
  local result = {}
  for _,p in pairs(players) do
    if type(p) == "Player" then
      table.insert(result, p.name)
    end
  end
  return result
end

function showError(message, ...)
  local n = select('#', ...)
  if n>0 then
    message = string.format(message, ...)
  end
  tell(spell.owner.name, message, 'red')
end

function tell(to, message, color)
  color = color or 'white'
  spell:execute([[
    /tellraw %s [{"text":"%s","color":"%s"}]
  ]], to, message, color)
end

return pkg

