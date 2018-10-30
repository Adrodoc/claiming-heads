-- claiming-heads/show-claim.lua
-- /lua require('claiming-heads.show-claim').enable(true)

local pkg = {}
local module = ...
local CMD = 'show-claim'
local showError
local tell

function pkg.enable(value)
  value = value or true
  if value then
    Commands.register(CMD,string.format([[
      require('%s').showClaim(...)
    ]], module), "/showClaim", 1)
  else
    pcall(function() 
      Commands.deregister(CMD)
    end)
  end
end

function pkg.showClaim()
  local player = spell.owner
  local claims = require('claiming-heads.claiming').getApplicableClaims(player.pos)
  local closest = nil
  for _,claim in pairs(claims) do
    local dist = (claim.pos - player.pos):sqrMagnitude()
    if not closest or dist < closest.dist then
      closest = { claim=claim, dist=dist}
    end
  end
  if closest then
    local visualizer = require('claiming-heads.claimvisualizer')
    visualizer.showBorders(player.name, closest.claim.pos, closest.claim.width)
  end
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

