-- claiming/cities.lua

-- /lua require('claiming.cities').get():createCity(pos)
-- /lua local v=require('claiming.cities').get():isInWilderness(spell.pos); print(v)
local module = ...
local datastore = require "claiming.datastore"
local singleton = require "claiming.singleton"

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

-- Creates a new city at the given position with the given ringWidth
-- Throws an error if there is already a city at the given position.
function Cities:createCity( aPos, ringWidth)
  aPos = aPos:floor()
  ringWidth = ringWidth or 400
  -- log("Should create new city at %s", aPos)
  local data = self:getData()
  local key = aPos:tostring()
  if data[key] then
    log("Can't create city! There is already a city at %s.", aPos)
    return
  end
  local city = {
    center = aPos,
    ringWidth = ringWidth
  }
  data[key] = city
  self:setData(data)
  self:saveData()
end

-- Creates a new capital at the given position with the given ringWidth.
-- Throws an error if there is already a capital in this world.
function Cities:createCapital( aPos, ringWidth)
  -- log("Should create new capital at %s", aPos)
  -- check if there is already a capital somewhere
  local data = self:getData()
  for _,city in pairs(data) do
    if city.isCapital then
      error("Can't create new capital! There is already a capital at %s.", city.center)
    end
  end
  self:createCity(aPos, ringWith)
  self:setCapital(aPos)
end

-- Deletes the city at the given position
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

-- Returns true if there is a city at the given position
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

-- Resizes the ring width of the city at the given position to the given ringWidth
function Cities:resizeCity( aPos, ringWidth)
  aPos = aPos:floor()
  -- log("Should resize city rings at %s to %s", aPos, ringWidth)
  local data = self:getData()
  local key = aPos:tostring()
  if not data[key] then
    log("Can't resize city! There is no city at %s.", aPos)
    return
  end
  local city = data[key]
  city.ringWidth = ringWidth
  self:setData(data)
  self:saveData()
end

-- Makes the city at the given position to the world's capital.
function Cities:setCapital( aPos)
  aPos = aPos:floor()
  -- log("Should make city at %s to capital", aPos)
  local data = self:getData()
  local key = aPos:tostring()
  if not data[key] then
    log("Can't make city to capital! There is no city at %s.", aPos)
    return
  end
  local newCapital = data[key]
  newCapital.isCapital = true
  for _,city in pairs(data) do
    if city ~= newCapital then
      city.isCapital = false
    end
  end
  self:setData(data)
  self:saveData()
end

function Cities:isInsideCapitalCenter( pos)
  local capital = self:getCapital()
  return capital and isInsideCenter( capital, pos)
end

function Cities:isInsideCityCenter( pos)
  for _,city in pairs(self:getData()) do
    if isInsideCenter( city, pos) then
      return true
    end
  end
  return false
end

function Cities:getCapitalSize()
  for _,city in pairs(self:getData()) do
    if city.isCapital then
      return city.ringWidth * #rings
    end
  end
  return nil
end

function Cities:getCapitalCenter()
  local capital = self:getCapital()
  if capital then
    return capital.center
  else
    return nil
  end
end

function Cities:getCapital()
  for _,city in pairs(self:getData()) do
    if city.isCapital then
      return city
    end
  end
  return nil
end

function Cities:isInWilderness( pos)
  local index = findSmallestCityRingIndex( pos, self)
  return (index == #rings)
end

-- package declaration

local pkg = {}

function pkg.get()
  local result
  local count = 0
  while not result and count<20 do
    sleep(1)
    count = count + 1
    result = Spells.find({name=module})[1]
  end
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
  singleton(module)
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
  local ringIndex = findSmallestCityRingIndex( player.pos, spell.data.cities)
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

-- Finds the smallest index of all rings that the given pos is inside of.
function findSmallestCityRingIndex( pos, cities)
  local result = #rings 
  for _,city in pairs(cities:getData()) do
    local offset = city.center - pos
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

return pkg

