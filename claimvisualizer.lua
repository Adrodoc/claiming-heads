-- claiming/claimvisualizer.lua

-- /lua require('claiming.claimvisualizer').showBorders(playername, center, width)
-- /lua cs=require('claiming.claiming').getApplicableClaims(spell.owner.pos) for _,c in pairs(cs) do require('claiming.claimvisualizer').showBorders(spell.owner.name, c.pos, c.width) end

local module = ...

local pkg = {}

local line
local rect
local log

function pkg.showBorders(playername, center, width)
  if not playername then
    error("missing playername")
  end
  local player = Entities.find("@a[name="..playername.."]")[1]
  if not player then
    error("player with name %s not found", playername)
  end
  if not center then
    error("missing center")
  end
  if not width then
    error("missing width")
  end
  
  local a = center + Vec3(width,0,width)
  local b = center + Vec3(-width,0,-width)

  local y=math.floor(player.pos.y)
  for k=1,1 do
    for i=-1,4 do 
      rect(a,b,y+i, player)
      if k>1 then
        sleep(20)
      end
    end
  end
end

function line(a, b, player)
  local delta = (b-a)
  local dist = delta:magnitude()
  local step = delta*(1/dist)
  spell.pos = a
  for i=0,dist do
    spell:execute([[
      /particle barrier ~0.5 ~-0.5 ~0.5 0 0 0 1 1 force %s
    ]], player.name)
    spell.pos = spell.pos + step
  end
end

function rect(a,b,y, player)
  local a1 = Vec3(a.x,y,a.z)
  local a2 = Vec3(b.x,y,a.z)
  local a3 = Vec3(b.x,y,b.z)
  local a4 = Vec3(a.x,y,b.z)
  line(a1,a2, player)
  line(a2,a3, player)
  line(a3,a4, player)
  line(a4,a1, player)
end

-- Logs the given message into the chat
function log(message, ...)
  local n = select('#', ...)
  if n>0 then
    message = string.format(message, ...)
  end
  spell:execute("say %s", message)
end

return pkg