declare('ClaimedArea')

function ClaimedArea:isValid()
  return true
end

function ClaimedArea:mayBuild(player)
  return false
end

function ClaimedArea:getChunks()
  return {}
end

function ClaimedArea:contains(pos)
  return false
end

declare('ClaimedRectangle', ClaimedArea)

function ClaimedRectangle.new(pos, width, ownerId)
  local result = {
    ownerId = ownerId,
    pos = pos:floor(),
    width = width
  }
  setmetatable(result, ClaimedRectangle)
  return result
end

function ClaimedRectangle:mayBuild(player)
  return self.ownerId == player.uuid
end

function ClaimedRectangle:getChunks()
  local pos = self.pos
  local width = self.width
  local minChunkX = (pos.x - width) // 16
  local maxChunkX = (pos.x + width) // 16
  local minChunkZ = (pos.z - width) // 16
  local maxChunkZ = (pos.z + width) // 16
  local result = {}
  for chunkX=minChunkX,maxChunkX,1 do
    for chunkZ=minChunkZ,maxChunkZ,1 do
      table.insert(result, chunkX..'/'..chunkZ)
    end
  end
  return result
end

function ClaimedRectangle:contains(pos)
  local sPos = self.pos
  local width = self.width
  return sPos.x - width <= pos.x
     and sPos.z - width <= pos.z
     and sPos.x + width + 1 > pos.x
     and sPos.z + width + 1 > pos.z
end

declare('HeadClaim', ClaimedRectangle)

function HeadClaim.new(pos, width, ownerId)
  local result = ClaimedRectangle.new(pos, width, ownerId)
  setmetatable(result, HeadClaim)
  return result
end

local function isHead(block)
  return block.name == 'skull' and block.nbt and block.nbt.Owner and block.nbt.Owner.Name and block.nbt.Owner.Id
end

function HeadClaim.getHeadOwnerId(block)
  if isHead(block) then
    return block.nbt.Owner.Id
  end
end

function HeadClaim:isValid()
  local block = spell:getBlock(self.pos)
  return HeadClaim.getHeadOwnerId(block) == self.ownerId
end
