-- claiming-heads/startup.lua

--[[

Events.on("claiming-heads.StartupEvent"):call(function(event)
  local data = event.data
  data.claimingWidth = 28
end)

Events.on("claiming-heads.ClaimEvent"):call(function(event)
  local pos = event.data.pos
  
  -- local isCloseToVillage = spell.world:getNearestVillage(pos, 10)
  --event.data.canceled = not isCloseToVillage
  
  --event.canceled = not isCloseToVillage -- TODO fix this in WoL
  event.data.canceled = false
end)

]]--


local module = ...
local start
local initialize
local DEFAULTS = {
  claimingWidth = 21            ,
  claimingFrequency = 20        ,
  restictCreativePlayer = false ,
  enableCommands = true
}
local STARTUP_EVENT = 'claiming-heads.StartupEvent'

function initialize(target, defaults)
  target = target or {}
  for k,v in pairs(defaults) do
    if not target[k] then
      target[k] = v
    end
  end
  return target
end

local options = DEFAULTS
Events.fire(STARTUP_EVENT,options)

require('claiming-heads.give-head').enable(options.enableCommands)
require('claiming-heads.show-claim').enable(options.enableCommands)
  
require('claiming-heads.claiming').start(
  { width                = options.claimingWidth,
    frequency            = options.claimingFrequency,
    creativeBuildAllowed = not options.restictCreativePlayer
  }
)

