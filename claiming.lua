-- claiming/claiming.lua

-- /lua require('claiming.claiming').start(Vec3(340,83,-834), {width=21,frequency=20})
-- /lua require('claiming.claiming').get()
-- /lua v=require('claiming.claiming').get(); print(inspect(v,{depth=1}))
-- /lua player=spell.owner; require('claiming.claiming').get():getNearestClaim(player);

local module = ...

local setmultimap = require "claiming.setmultimap"
local datastore = require "claiming.datastore"

local pkg = {}


local singleton
local getChunksIntersecting
local updatePlayer
local removeBrokenHeads
local onRightClickBlockEvent
local getBlock
local isPlayerHead
local isHeadOfOwner
local isOverlapping
local destroy

declare("Claims")

function Claims.new(o)
  o = o or {}
  setmetatable(o, Claims)
  return o
end

function Claims:saveData()
  datastore.save(self.storePos, self.heads)
end


function Claims:loadData()
  local data = datastore.load(self.storePos) or {}
  self.heads = {}
  for i,headPos in pairs(data) do
    table.insert(self.heads,Vec3.new(headPos))
  end
  -- Mapping of chunk vector to all head positions with areas that intersect the chunk
  self.headsByChunk = {}
  for i,head in pairs(self.heads) do
    local chunks = getChunksIntersecting(head,self.width)
    for j,chunk in pairs(chunks) do
      setmultimap.put(self.headsByChunk, chunk, head)
    end
  end
end

-- returns the center of the nearest claim relative to the given area
function Claims:getNearestClaim(player)
  local pos = player.pos
  local chunkX = pos.x // 16
  local chunkZ = pos.z // 16
  local chunk = chunkX..'/'..chunkZ
  local heads = self.headsByChunk[chunk]
  local width = self.width
  local resultDistance
  local result
  if heads then
    for i,head in pairs(heads) do
      if head.x - width < pos.x
      and head.z - width < pos.z
      and head.x + width + 1 > pos.x
      and head.z + width + 1 > pos.z
      then
        local distance = (pos - head):magnitude()
        if not resultDistance or resultDistance > distance then
          resultDistance = distance
          result = head
        end
      end
    end
  end
  return result
end

function Claims:getWidth()
  return self.width
end

function pkg.get()
  local result = Spells.find({name=module})[1]
  return result.data.claims
end

function pkg.start(storePos, options, funcCanClaimPos) 
  storePos = storePos or spell.pos
  singleton()
  options = options or {}
  local width = options.width or 16
  local frequency = options.frequency or 1
  
  spell.data.claims = Claims.new({storePos=storePos, heads = {}, headsByChunk = {}, width=width})
  spell.data.claims:loadData()
  
  local queue = Events.collect("RightClickBlockEvent")
  local lastCycle = Time.gametime
  local timeout = frequency
  while true do
    local dirty = false
    local event = queue:next(timeout)
    local timeSlept = Time.gametime - lastCycle
    timeout = math.min(timeout, frequency-timeSlept)
    if timeout < 1 then
      timeout = frequency
    end
    if event then
      dirty = onRightClickBlockEvent(event, funcCanClaimPos)
    else
      local players = Entities.find("@a")
      for i,player in pairs(players) do
        updatePlayer(player)
      end
      dirty = removeBrokenHeads()
    end
    if dirty then
      spell.data.claims:saveData()
    end
  end
end
Help.on(pkg.start) [[
Allows players to 'claim' an area by placing their own head in the center of it. An area is protected by setting other players that enter the area into adventure mode. Areas can be shared between multiple players by placing multiple heads on top of each other (same x and z coordinate). If two areas overlap each other, the intersection is protected from both players.

Options:
  - width: How many blocks around the skull are protected. Default is 16 which results in 33x33 areas.
  
  - frequency: Every 'frequency' ticks the gamemodes of players are updated and all skulls are checked to make sure they are still there.
]]

function pkg.stop() 
  spell:singleton(module)
end
Help.on(pkg.stop) [[
Disables 'claiming' of areas. Existing areas are kept persistent.
]]


function updatePlayer(player)
  if player.dimension ~= 0 then
    if player.gamemode == "adventure" then
      player.gamemode = "survival"
    end
    return -- claiming is only supported in the overworld
  end
  local pos = player.pos
  local chunkX = pos.x // 16
  local chunkZ = pos.z // 16
  local chunk = chunkX..'/'..chunkZ
  local heads = spell.data.claims.headsByChunk[chunk]
  
  local ownHeadsXZ = {}
  local foreignHeadsXZ = {}
  local width = spell.data.claims.width
  if heads then
    for i,head in pairs(heads) do
      if head.x - width < pos.x
      and head.z - width < pos.z
      and head.x + width + 1 > pos.x
      and head.z + width + 1 > pos.z
      then
        local xz = head.x.."/"..head.z
        local block = getBlock(head)
        if isPlayerHead(block) then
          if isHeadOfOwner(block, player.name) then
            ownHeadsXZ[xz] = true
          else
            foreignHeadsXZ[xz] = true
          end
        end
      end
    end
  end
  for xz,_ in pairs(ownHeadsXZ) do
    foreignHeadsXZ[xz] = nil
  end
  local mayBuild = next(foreignHeadsXZ) == nil
  if not mayBuild and player.gamemode == "survival" then
    player.gamemode = "adventure"
  elseif mayBuild and player.gamemode == "adventure" then
    player.gamemode = "survival"
  end
end


function removeBrokenHeads()
  local dirty = false
  local heads = spell.data.claims.heads
  local headsByChunk = spell.data.claims.headsByChunk
  local width = spell.data.claims.width
  for i=#heads,1,-1 do
    local head = heads[i]
    if head then -- paranoia null check
      local block = getBlock(head)
      if not isPlayerHead(block) then
        table.remove(heads, i)
        
        local chunks = getChunksIntersecting(head,width)
        for i,chunk in pairs(chunks) do
          setmultimap.remove(headsByChunk, chunk, head)
        end
        dirty = true
      end
    end
  end
  return dirty
end

function isHeadOfOwner(block, owner)
  return isPlayerHead(block) and block.nbt.Owner.Name == owner
end

function getBlock(pos)
  spell.pos = pos
  return spell.block
end

function isPlayerHead(block)
  return block.name == "skull" and block.nbt.Owner and block.nbt.Owner.Name
end


function onRightClickBlockEvent(event, funcCanClaimPos)
  if event.player.dimension ~= 0 then
    return false -- claiming is only supported in the overworld
  end
  spell.pos = event.pos
  spell:move(event.face)
  local block = spell.block
  if not isPlayerHead(block) then
    return false -- not dirty
  end
  local head = spell.pos
  if event.player.gamemode ~= "creative" and funcCanClaimPos(head) then
    -- undo setting the head
    destroy(head)
    return false -- not dirty
  end
  
  -- prevent overlapping areas
  if isOverlapping(head) then
    spell:execute('tellraw %s {"text":"This would overlap with a different claimed area","color":"dark_purple"}', event.player.name)
    -- undo setting the head
    destroy(head)
    return false -- not dirty
  end
  
  -- new head is accepted
  local heads = spell.data.claims.heads
  local headsByChunk = spell.data.claims.headsByChunk
  local width = spell.data.claims.width
  table.insert(heads, head)
  local chunks = getChunksIntersecting(head,width)
  for i,chunk in pairs(chunks) do
    setmultimap.put(headsByChunk, chunk, head)
  end
  return true -- dirty
end

function isOverlapping(head)
  local block = getBlock(head)
  local owner = block.nbt.Owner.Name
  
  local ownerHeadsXZ = {}
  local foreignHeadsXZ = {}
  
  local headsByChunk = spell.data.claims.headsByChunk
  local width = spell.data.claims.width
  local chunks = getChunksIntersecting(head,width)
  for i,chunk in pairs(chunks) do
    local nearbyHeads = headsByChunk[chunk]
    if nearbyHeads then
      for j,nearbyHead in pairs(nearbyHeads) do
        if  nearbyHead.x + width*2 >= head.x
        and head.x + width*2 >= nearbyHead.x
        and nearbyHead.z + width*2 >= head.z
        and head.z + width*2 >= nearbyHead.z
        then
          local xz = nearbyHead.x.."/"..nearbyHead.z
          local nearbyBlock = getBlock(nearbyHead)
          if isPlayerHead(nearbyBlock) then
            if isHeadOfOwner(nearbyBlock, owner) then
              ownerHeadsXZ[xz] = true
            else
              foreignHeadsXZ[xz] = true
            end
          end
        end
      end
    end
  end
  if foreignHeadsXZ[head.x.."/"..head.z] then
    return false -- placing a head ontop of another head is always allowed
  end
  for xz,_ in pairs(ownerHeadsXZ) do
    foreignHeadsXZ[xz] = nil
  end
  return next(foreignHeadsXZ) ~= nil
end

function destroy(pos)
  spell:execute("setblock "..pos.x.." "..pos.y.." "..pos.z.." air 0 destroy")
end

function getChunksIntersecting(pos, width)
  local minChunkX = (pos.x - width) // 16
  local maxChunkX = (pos.x + width + 1) // 16
  local minChunkZ = (pos.z - width) // 16
  local maxChunkZ = (pos.z + width + 1) // 16
  local result = {}
  for chunkX=minChunkX,maxChunkX,1 do
    for chunkZ=minChunkZ,maxChunkZ,1 do
      table.insert(result, chunkX..'/'..chunkZ)
    end
  end
  return result
end

function singleton()
  spell:execute([[/wol spell break byName %s]], module)
  spell.name = module
end

return pkg