-- claiming/cities.lua

-- require('mickkay.cities').get():createCity(pos)
local module = ...
require "mickkay.wol.Spell"
local datastore = require "claiming.datastore"

-- Constants:
local CITIES_CMD = module..".command"

local centerRing = {}
local noDiamondRing = {
  diamond_sword=1, diamond_axe=1, diamond_pickaxe=1, diamond_shovel=1
}
local noIronRing = {
  iron_sword=1, iron_axe=1, iron_pickaxe=1, iron_shovel=1
}
local noStoneRing = {
  stone_sword=1, stone_axe=1, stone_pickaxe=1, stone_shovel=1
}
local noWoodRing = {
  wooden_sword=1, wooden_axe=1, wooden_pickaxe=1, wooden_shovel=1
}
local rings = {
  centerRing,
  noDiamondRing,
  noIronRing,
  noStoneRing,
  noWoodRing
}
local cmdFatigue = '/effect %s minecraft:mining_fatigue 4 2'
local cmdWeakness = '/effect %s minecraft:weakness 4 4'

-- Forward declarations of local functions:
local isInsideCenter
local updatePlayers
local updatePlayer
local isForbidden
local findSmallestCityRingIndex
local singleton
local log

declare("Cities")

function Cities.new(o)
  o = o or {}
  setmetatable(o, Cities)
  return o
end

function Cities:getDataPos()
  return self.dataPos
end

function Cities:getData()
  return self.data
end

function Cities:setData(aData)
  self.data = aData
end

-- Saves this spell's data into its dedicated command block
function Cities:saveData()
  datastore.save( self:getDataPos(), self:getData())
end

-- Loads this spell's data from its dedicated command block
function Cities:loadData()
  local data = datastore.load( self:getDataPos()) or {}
  for _,city in pairs(data) do
    city.center = Vec3.new(city.center)
  end
  log("loadData data=%s",str(data))
  self:setData(data)
end

-- Creates a new city at the given pos
function Cities:createCity( aPos)
  aPos = aPos:floor()
  -- log("Should create new city at %s", aPos)
  local data = self:getData()
  local key = aPos:tostring()
  if data[key] then
    log("Can't create city! There is already a city at %s.", aPos)
    return
  end
  local city = {
    center = aPos,
    ringWidth = 10
  }
  data[key] = city
  self:setData(data)
  self:saveData()
end

-- Deletes the city at the given pos
function Cities:deleteCity( aPos)
  aPos = aPos:floor()
  -- log("Should delete city at %s", aPos)
  local data = self:getData()
  local key = aPos:tostring()
  if not data[key] then
    log("Can't delete city! There is no city at %s.", aPos)
    return
  end
  data[key] = nil
  self:setData(data)
  self:saveData()
end

-- Returns true if there is a city at the given pos
function Cities:isCity( aPos)
  aPos = aPos:floor()
  local data = self:getData()
  local key = aPos:tostring()
  if data[key] then
    return true
  else
    return false
  end
end

-- Resizes the ring width of the city at the given pos to the given size
function Cities:resizeCity( aPos, size)
  aPos = aPos:floor()
  -- log("Should resize city rings at %s to %s", aPos, size)
  local data = self:getData()
  local key = aPos:tostring()
  if not data[key] then
    log("Can't resize city! There is no city at %s.", aPos)
    return
  end
  local city = data[key]
  city.ringWidth = size
  self:setData(data)
  self:saveData()
end

-- Makes the city at the given position to the world's capitol.
function Cities:setCapitol( aPos)
  aPos = aPos:floor()
  -- log("Should make city at %s to capitol", aPos)
  local data = self:getData()
  local key = aPos:tostring()
  if not data[key] then
    log("Can't make city to capitol! There is no city at %s.", aPos)
    return
  end
  local newCapitol = data[key]
  newCapitol.isCapitol = true
  for _,city in pairs(data) do
    if city ~= newCapitol then
      city.isCapitol = false
    end
  end
  self:setData(data)
  self:saveData()
end

function Cities:isInsideCapitolCenter( pos)
  local capitol = self:getCapitol()
  return capitol and isInsideCenter( capitol, pos)
end

function Cities:isInsideCityCenter( pos)
  for _,city in pairs(self:getData()) do
    if isInsideCenter( city, pos) then
      return true
    end
  end
  return false
end

function Cities:getCapitolSize()
  for _,city in pairs(self:getData()) do
    if city.isCapitol then
      return city.ringWidth * #rings
    end
  end
  return nil
end

function Cities:getCapitolCenter()
  local capitol = self:getCapitol()
  if capitol then
    return capitol.center
  else
    return nil
  end
end

function Cities:getCapitol()
  for _,city in pairs(self:getData()) do
    if city.isCapitol then
      return city
    end
  end
  return nil
end


-- package declaration

local pkg = {}

function pkg.get()
  local result = Spells.find({name=module})[1]
  if not result then
    error("Spell %s not found! You need to cast this spell before looking for it.", module)
  end
  return result.data.cities
end

-- Starts the main cities spell and loads the spells data from the dedicated 
-- command block at the specified location
function pkg.start( aDataPos)
  if not aDataPos then
    error("Missing required argument: dataPos")
  end
  spell:singleton(module)
  log("Starting %s", module)
  
  spell.data.cities = Cities.new({dataPos=aDataPos})
  spell.data.cities:loadData()
  
  while true do
    updatePlayers()
    sleep(10)
  end
end

-- Updates all players effects depending on their location relative to 
-- the city centers.
function updatePlayers()
  local players = Entities.find("@a")
  for _,player in pairs(players) do
    updatePlayer( player)
  end
end

-- Updates the given player's effects depending on his/her location relative to 
-- the city centers.
function updatePlayer( player)
  if player.dimension ~= 0 then
    return -- cities are only supported in the overworld
  end
  local ringIndex = findSmallestCityRingIndex( player)
  if isForbidden(player.mainhand, ringIndex) or isForbidden(player.offhand, ringIndex) then
    --log(player.name, ringIndex, "forbidden item!")
    spell:execute(cmdFatigue, player.name)
    spell:execute(cmdWeakness, player.name)
  end
end

-- Returns true if the given item is forbidden in a ring with the given index
function isForbidden(item, ringIndex)
  if item then
    for i=1,ringIndex do
      local ring = rings[i]
      if ring[item.id] then
        return true
      end
    end
  end
  return false
end

-- Compares the indices of all rings the given player is inside and returns
-- the smallest one
function findSmallestCityRingIndex( player)
  local result = #rings 
  local cities = spell.data.cities
  for _,city in pairs(cities:getData()) do
    local offset = city.center - player.pos
    offset.y = 0
    local dist = offset:magnitude()
    local ringIndex = math.min(#rings, math.ceil( dist / city.ringWidth))
    result = math.min( result, ringIndex)
  end
  return result
end

-- Logs the given message into the chat
function log(message, ...)
  local n = select('#', ...)
  if n>0 then
    message = string.format(message, ...)
  end
  spell:execute("say %s", message)
end

function isInsideCenter( city, pos)
  local offset = city.center - pos
  offset.y = 0
  local dist = offset:magnitude()
  return dist <= city.ringWidth;
end

function singleton()
  spell:execute([[/wol spell break byName %s]], module)
  spell.name = module
end


return pkg

