local module = ...

require 'claiming.ClaimedArea'
require 'claiming.Spell'
local listmultimap = require "claiming.listmultimap"
local singleton = require "claiming.singleton"

local pkg = {}

spell.data.claiming = {
  claimsByChunk = {}
}

function pkg.getClaimsByChunk()
  local spell = Spells.find({name=module})[1]
  return spell.data.claiming.claimsByChunk
end

function pkg.addClaim(claim)
  local claimsByChunk = pkg.getClaimsByChunk()
  local chunks = claim:getChunks()
  for _, chunk in pairs(chunks) do
    listmultimap.put(claimsByChunk, chunk, claim)
  end
end

function pkg.removeClaim(claim)
  local claimsByChunk = pkg.getClaimsByChunk()
  local chunks = claim:getChunks()
  for _, chunk in pairs(chunks) do
    listmultimap.remove(claimsByChunk, chunk, claim)
  end
end

function pkg.start(width, frequency)
  singleton(module)
  width = width or 1
  frequency = frequency or 20
  Events.on('BlockPlaceEvent', 'BlockBreakEvent'):call(function(event)
    if not pkg.mayBuild(event.player, event.pos) then
      event.canceled = true
    end
  end)
  Events.on('BlockPlaceEvent'):call(function(event)
    local block = spell:getBlock(event.pos) -- Workaround for https://github.com/wizards-of-lua/wizards-of-lua/issues/188
    local ownerId = HeadClaim.getHeadOwnerId(block)
    if ownerId then
      local pos = event.pos
      local claim = HeadClaim.new(pos, width, ownerId)
      pkg.addClaim(claim)
    end
  end)
  while true do
    local players = Entities.find('@a')
    for _, player in pairs(players) do
      pkg.updatePlayer(player)
    end
    sleep(frequency)
  end
end

function pkg.updatePlayer(player)
  if player.dimension ~= 0 then
    if player.gamemode == 'adventure' then
      player.gamemode = 'survival'
    end
    return -- claiming is only supported in the overworld
  end
  local mayBuild = pkg.mayBuild(player)
  if mayBuild and player.gamemode == 'adventure' then
    player.gamemode = 'survival'
  elseif not mayBuild and player.gamemode == 'survival' then
    player.gamemode = 'adventure'
  end
end

function pkg.mayBuild(player, pos)
  pos = pos or player.pos
  local claims = pkg.getApplicableClaims(pos)
  if next(claims) == nil then
    return true
  end
  for _, claim in pairs(claims) do
    if claim:mayBuild(player) then
      return true
    end
  end
  return false
end

function pkg.getApplicableClaims(pos)
  local claimsByChunk = pkg.getClaimsByChunk()
  local chunk = pkg.getChunk(pos)
  local claims = claimsByChunk[chunk] or {}
  pkg.removeInvalidClaims(claims)
  local result = {}
  for _, claim in pairs(claims) do
    if claim:contains(pos) then
      table.insert(result, claim)
    end
  end
  return result
end

function pkg.removeInvalidClaims(claims)
  local invalidClaims = {}
  for _, claim in pairs(claims) do
    if not claim:isValid() then
      table.insert(invalidClaims, claim)
    end
  end
  for _, claim in pairs(invalidClaims) do
    pkg.removeClaim(claim)
  end
end

function pkg.getChunk(pos)
  pos = pos:floor()
  local chunkX = pos.x // 16
  local chunkZ = pos.z // 16
  return chunkX..'/'..chunkZ
end

return pkg
