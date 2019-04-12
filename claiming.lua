-- claiming-heads/claiming.lua

local pkg = {}
local module = ...
local CLAIM_EVENT = "claiming-heads.ClaimEvent"
local MAY_BUILD_EVENT = "claiming-heads.MayBuildEvent"
local ADVENTURE_MODE_SET_BY_CLAIMING_MOD = "claiming-heads.gamemode-set-by-claiming-mod"

require 'claiming-heads.ClaimedArea'
require 'claiming-heads.Spell'
local datastore = require "claiming-heads.datastore"
local listmultimap = require "claiming-heads.listmultimap"
local singleton = require "claiming-heads.singleton"
local canClaimPos
local log

-- Starts the claiming spell with the given options (with the attributes width, frequency, and creativeBuildAllowed).
function pkg.start(options)
  options = options or {}
  local width = options.width or 16
  local frequency = options.frequency or 20
  local creativeBuildAllowed = options.creativeBuildAllowed or false
  singleton(module)
  spell.data.claiming = {
    claims = {},
    claimsByChunk = {}
  }
  pkg.loadData()
  pkg.setCreativeBuildAllowed(creativeBuildAllowed)

  Events.on('BlockPlaceEvent', 'BlockBreakEvent'):call(function(event)
    if event.player.dimension ~= 0 then
      -- claiming is only supported in the overworld
      return
    end
    if event.player.gamemode == "creative" and pkg.isCreativeBuildAllowed() then
      return
    end
    if not pkg.mayBuild(event.player, event.pos) then
      event.canceled = true
      spell:execute('tellraw '..event.player.name..' {"text":"This area is claimed by someone else","color":"gold"}')
    end
  end)
  Events.on('BlockPlaceEvent'):call(function(event)
    if event.player.dimension ~= 0 then
      -- claiming is only supported in the overworld
      return
    end
    local checkClaim = not (event.player.gamemode == "creative" and pkg.isCreativeBuildAllowed())
    local block = spell:getBlock(event.pos) -- Workaround for https://github.com/wizards-of-lua/wizards-of-lua/issues/188
    local ownerId = HeadClaim.getHeadOwnerId(block)
    if ownerId then
      local pos = event.pos
      local claim = HeadClaim.new(pos, width, ownerId)
      local foreignClaim = pkg.getOverlappingForeignClaim(claim, event.player.uuid)
      if checkClaim and foreignClaim then
        event.canceled = true
        spell:execute('tellraw '..event.player.name..' {"text":"This claim would overlap with another claim","color":"gold"}')
        return
      end
      if checkClaim and not canClaimPos(pos) then
        event.canceled = true
        spell:execute('tellraw '..event.player.name..' {"text":"You are not allowed to claim here","color":"gold"}')
        return
      end
      pkg.addClaim(claim)
    end
  end)

  local queue = Events.collect('BlockBreakEvent')
  while true do
    local event = queue:next(0)
    if event then
      -- Check if we have to remove an invalid claim
      pkg.removeInvalidClaimsAtPos(event.pos)
    end

    local players = Entities.find('@a')
    for _, player in pairs(players) do
      pkg.updatePlayer(player)
    end
    sleep(frequency)
  end
end

--[[
Returns the first claim that overlaps with the specified claim where the claimer is not allowed to build in at all (not even partially)
]]
function pkg.getOverlappingForeignClaim(claim, claimer)
  return pkg.getOverlappingClaim(claim, function(claim)
    return not pkg.getOverlappingOwnedClaim(claim, claimer)
  end)
end

--[[
Returns the first claim that overlaps with the specified claim where the claimer is allowed to build
]]
function pkg.getOverlappingOwnedClaim(claim, claimer)
  return pkg.getOverlappingClaim(claim, function(claim)
    return claim:mayBuild(claimer)
  end)
end

--[[
Returns the first claim that overlaps with the specified claim for which the claimPredicate returns true
]]
function pkg.getOverlappingClaim(claim, claimPredicate)
  local claimsByChunk = pkg.getClaimsByChunk()
  local chunks = claim:getChunks()
  for _, chunk in pairs(chunks) do
    local claims = claimsByChunk[chunk] or {}
    for _, otherClaim in pairs(claims) do
      if otherClaim:isOverlapping(claim) and claimPredicate(otherClaim) then
        return otherClaim
      end
    end
  end
  return nil
end

local claimingSpell
function pkg.getClaimingSpell()
  if claimingSpell == nil then
    claimingSpell = Spells.find({name=module})[1]
  end
  return claimingSpell
end

local loadDataPending
function pkg.loadData()
  loadDataPending = true
  local data = datastore.load() or {}
  for _, serializedClaim in pairs(data) do
    local claim = HeadClaim.deserialize(serializedClaim)
    pkg.addClaim(claim)
  end
  loadDataPending = false
end

function pkg.saveData()
  if loadDataPending then
    return
  end
  local data = {}
  local claims = pkg.getClaims()
  for claim, _ in pairs(claims) do
    local serializedClaim = claim:serialize()
    table.insert(data, serializedClaim)
  end
  datastore.save(data)
end

function pkg.getClaims()
  local spell = pkg.getClaimingSpell()
  return spell.data.claiming.claims
end

function pkg.getClaimsByChunk()
  local spell = pkg.getClaimingSpell()
  return spell.data.claiming.claimsByChunk
end

function pkg.isCreativeBuildAllowed()
  local spell = pkg.getClaimingSpell()
  return spell.data.claiming.creativeBuildAllowed
end

function pkg.setCreativeBuildAllowed(value)
  local spell = pkg.getClaimingSpell()
  spell.data.claiming.creativeBuildAllowed = value
end

function pkg.addClaim(claim)
  local claims = pkg.getClaims()
  claims[claim] = true
  local claimsByChunk = pkg.getClaimsByChunk()
  local chunks = claim:getChunks()
  for _, chunk in pairs(chunks) do
    listmultimap.put(claimsByChunk, chunk, claim)
  end
  pkg.saveData()
end

function pkg.removeClaim(claim)
  local claims = pkg.getClaims()
  claims[claim] = nil
  local claimsByChunk = pkg.getClaimsByChunk()
  local chunks = claim:getChunks()
  for _, chunk in pairs(chunks) do
    listmultimap.remove(claimsByChunk, chunk, claim)
  end
  pkg.saveData()
end

function pkg.updatePlayer(player)
  if player.gamemode == "creative" then
    return
  end
  if player.dimension ~= 0 then
    if player.gamemode == 'adventure' and player:removeTag(ADVENTURE_MODE_SET_BY_CLAIMING_MOD) then
      player.gamemode = 'survival'
    end
    return -- claiming is only supported in the overworld
  end
  local mayBuild = pkg.mayBuild(player)
  if mayBuild and player.gamemode == 'adventure' and player:removeTag(ADVENTURE_MODE_SET_BY_CLAIMING_MOD) then
    player.gamemode = 'survival'
  elseif not mayBuild and player.gamemode == 'survival' then
    player.gamemode = 'adventure'
    player:addTag(ADVENTURE_MODE_SET_BY_CLAIMING_MOD)
  end
end

function pkg.mayBuild(player, pos)
  pos = pos or player.pos

  local result = false
  local claims = pkg.getApplicableClaims(pos)
  if next(claims) == nil then
    result = true
  else
    for _, claim in pairs(claims) do
      if claim:mayBuild(player) then
        result = true
        break
      end
    end
  end
  spell.pos = pos
  local block = spell.block
  local data = {pos = pos, player = player, result = result, block = block}
  Events.fire(MAY_BUILD_EVENT,data)
  return data.result
end

function pkg.removeInvalidClaimsAtPos(pos)
  local claimsByChunk = pkg.getClaimsByChunk()
  local chunk = pkg.getChunk(pos)
  local claims = claimsByChunk[chunk] or {}
  pkg.removeInvalidClaims(claims)
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

function pkg.getChunk(pos)
  pos = pos:floor()
  local chunkX = pos.x // 16
  local chunkZ = pos.z // 16
  return chunkX..'/'..chunkZ
end

function pkg.removeInvalidClaims(claims)
  local allClaims = pkg.getClaims()
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

function canClaimPos(pos)
  local data = {canceled=false,pos=pos}
  Events.fire(CLAIM_EVENT, data)
  return not data.canceled
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
