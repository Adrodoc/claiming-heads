-- claiming/spawnrun.lua

-- Signs:
-- /lua require([[claiming.spawnrun]]).start()
-- /lua require([[claiming.spawnrun]]).giveStartItem()
-- /lua require([[claiming.spawnrun]]).giveSign()
-- /lua p=Entities.find([[@p]])[1]; require([[claiming.spawnrun]]).finishPlayer(p)
-- /lua p=Entities.find([[@p]])[1]; require([[claiming.spawnrun]]).cancelPlayer(p); 


-- Store this module's full qualified name
local module = ...
local signalrocket = require "claiming.signalrocket"
local cities = require("claiming.cities").get()

local pkg = {}
-- Forward declarations of local functions:
local handlePlayer
local giveCompass
local randomZonePos
local startStats
local finishStats
local giveCertificate
local isZonePlayer
local unsetZonePlayer
local removeTags
local getTagValue
local strStarts
local setSpawnPoint
local teleport
local singleton
local giveHead
local log

-- 
function pkg.start()
  
  Events.on("LivingDeathEvent"):call(
    function(event)
      if event.name == "LivingDeathEvent" and type(event.entity)=="Player" then
        local player = event.entity
        if isZonePlayer(player) then
          pkg.cancelPlayer(player)
          local center = cities:getCapitolCenter()
          setSpawnPoint(player, center)
          --teleport(player, center)
        end
      end
    end
  )
  
  local queue = Events.collect("PlayerLoggedInEvent","PlayerLoggedOutEvent")
  local players = Entities.find("@a")
  
  while true do
    local event = queue:next(20)
    if event then
      if event.name == "PlayerLoggedInEvent" then
        table.insert(players, event.player)
      end
      if event.name == "PlayerLoggedOutEvent" then
        for i,p in pairs(players) do
          if p == event.player then
            table.remove(players, i)
            break
          end
        end
      end
    else
      for i,p in pairs(players) do
        handlePlayer(p)
      end
    end
  end
  
end

function handlePlayer(player)
  if isZonePlayer(player) then
    if cities:isInsideCapitolCenter(player.pos) then
      pkg.finishPlayer(player)
    end
  end
end

function pkg.giveStartItem()
  local p = Entities.find("@p")[1]
  
  local center = cities:getCapitolCenter()
  local radius = cities:getCapitolSize()
  if not center or not radius then
    log("Can't give start item since there is no capitol")
  end
  
  local zonePos = randomZonePos(center, radius):floor()
  local swingArmAction = string.format([[
    /lua require('%s').startPlayer(spell.owner, Vec3(%s,%s,%s), Vec3(%s,%s,%s))
  ]], module, zonePos.x, zonePos.y, zonePos.z, center.x, center.y, center.z)
  
  giveCompass(swingArmAction)
end

function pkg.startPlayer(player, startPos, targetPos)
  --log("teleporting %s to %s", player.name, startPos)
  if not player then
    error("Missing player")
  end
  if not startPos then
    error("Missing startPos")
  end
  if not targetPos then
    error("Missing targetPos")
  end
  spell:execute([[
    /playsound minecraft:item.firecharge.use master @p[r==10] ~ ~ ~ 1
  ]])
  spell:execute([[
    /clear %s
  ]], player.name)
  spell:execute([[
    /effect %s jump_boost 11 255 true
  ]], player.name)

  spell:execute([[
    /effect %s minecraft:blindness 3 1 true
  ]], player.name)
  sleep(1)
  startPos = startPos + Vec3(0,256,0)
  player.pos = startPos
  player:addTag("zonerunner")
  
  startStats( player, targetPos)
  
  sleep(20)
  
  signalrocket.give(3, player)
  
  spell:execute([[
    /give %s clock
  ]], player.name)
  
  spell:execute([[
    /give %s compass 1 0
  ]], player.name)
  
end

function pkg.finishPlayer( player)
  if isZonePlayer(player) then
    spell:execute("/msg %s Congratulations!", player.name)
    giveHead(player)
    player:removeTag("zonerunner")
    finishStats( player)
    pkg.launchFireworks( player.pos)
  end
end

function pkg.launchFireworks(pos)
  if not pos then
    error("missing pos")
  end
  for i=1,50 do
    spell.rotationYaw = math.random(-180,180)
    spell.pos = pos + spell.lookVec * 5
    signalrocket.summon(math.random(10,40))
    sleep(math.random(0,10))
  end
end

function pkg.cancelPlayer( player)
  if isZonePlayer(player) then
    spell:execute("/msg %s Your Zone Run has been Canceled!", player.name)
    player:removeTag("zonerunner")
  end
end

function giveCompass(swingArmAction)
  local cmd = [[
    /give @p compass 8 0 {
      ench:[{id:999,lvl:1}],
      display:{
        Name:"Zone Runner's Compass",
        Lore:["Swing this compass into the air to start the Zone Run.", "Follow the needle to get your claiming skull as reward."]
      },
      OnSwingArmEvent:"%s"
    }
  ]]
  spell:execute(cmd, swingArmAction)
end

function randomZonePos( center, r)
  local a = math.random() * 2 * math.pi
  local z = math.sin(a) * r
  local x = math.cos(a) * r
  return Vec3(center.x + x + 0.5, 0, center.z + z + 0.5)
end

-- Adds the zonerunner statistics to the given player for a run to the given target position.
function startStats( player, targetPos)
  removeTags(player, "zonerunner:started")
  removeTags(player, "zonerunner:dist")
  
  local startTime = Time.realtime
  local tagTime = "zonerunner:started="..startTime
  player:addTag(tagTime)
  
  local dist = (targetPos - player.pos):magnitude()
  local tagDist = "zonerunner:dist="..dist
  player:addTag(tagDist)
end

-- Closes the zonerunner statistics for the given player and creates a certificate for the player.
function finishStats( player)
  local endTime = Time.realtime
  local tagTime = getTagValue( player, "zonerunner:started")
  local startTime = tonumber(tagTime)
  local duration = endTime - startTime
  
  local tagDist = getTagValue( player, "zonerunner:dist")
  local dist = tonumber(tagDist)
  
  --giveCertificate( player, duration, dist)
end

function giveCertificate( player, duration, distance)
  local seconds = duration / 1000
  local avg = distance / seconds
  local message = string.format("%s's\nCertificate\n\nScore:\n  %.2f m\n      in\n  %.2f seconds\n->\n  %.2f m/s", player.name, distance, seconds, avg)
  
  local pages = string.format([[{"text":"%s"}]], message)
  local book = Items.get("written_book")
  book:putNbt({
    tag={author="xxx", title="Certificate", pages={pages}}
  })
  
  player:dropItem(book)
  
  log(message)
end

-- Returns true if the given player is tagged as zonerunner
function isZonePlayer(player)
  local tags = player.tags
  for _,tag in pairs(tags) do
    if tag == "zonerunner" then
      return true
    end
  end
  return false
end


-- Removes all tags from the given player that start with the given prefix
function removeTags( player, prefix)
  local tags = player.tags
  for _,tag in pairs(tags) do
    if strStarts(tag,prefix) then
      player:removeTag(tag)
    end
  end
end

-- Searches the given player's tags for tags starting with the given prefix 
-- and if found it parses the tag and returns the part after the "=" sign.
function getTagValue( player, key)
  for _,tag in pairs(player.tags) do
    if strStarts(tag,key) then
      local idx = string.find( tag, "=")
      local result = string.sub(tag, idx+1)
      return result
    end
  end
  return nil
end

function teleport(player, pos)
  spell:execute([[
    /tp %s %s %s %s
  ]], player.name, pos.x, pos.y, pos.z)
end

function setSpawnPoint(player, pos)
  spell:execute([[
    /spawnpoint %s %s %s %s
  ]], player.name, pos.x, pos.y, pos.z)
end

-- Returns true if the given string starts with the given prefix
function strStarts( str, prefix)
  local len = string.len(prefix)
  local sub = string.sub(str,1,len)
  return sub == prefix
end

function singleton()
  spell:execute([[/wol spell break byName %s]], module)
  spell.name = module
end

function giveHead(player)
  spell:execute('/give %s skull 1 3 {SkullOwner:"%s"}', player.name, player.name);
end


-- Logs the given message into the chat
function log(message, ...)
  local n = select('#', ...)
  if n>0 then
    message = string.format(message, ...)
  end
  spell:execute("say %s", message)
end

function pkg.giveSign()
  spell:execute([[
    /give @p sign 1 0 {
      BlockEntityTag: {
          Text1: "{\"text\":\"Click here\",\"underlined\":true,\"clickEvent\":{\"action\":\"run_command\",\"value\":\"/lua require('%s').giveStartItem()\"}}",
          Text2: "{\"text\":\"to create a\"}",
          Text3: "{\"text\":\"Spawn Run\"}",
          Text4: "{\"text\":\"compass\"}"
      },
      display: {
          Name: "Custom Sign"
      }
    }
  ]], module)
end

return pkg
