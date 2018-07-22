--[[ claiming/startup.lua

Name:           Claiming
Version:        1.0.0
Homepage:       https://github.com/wizards-of-lua/claiming
Authors:        Adrodoc, mickkay
Copyright:      2018, The Wizards of Lua
License:        GPL 3.0
Dependencies:   wol-1.12.2-2.0.2


You can use this startup script to activate the Claiming spell pack on your server.
If you want it to run with the defalt settings, just execute it from your server's
startup script like this:

  require('claiming.startup').startup()

The Claiming Spell Pack stores map-specific data into command blocks at 
certain locations. 
You can define where these command blocks are located by overriding the respectiv
default settings.  
For example, to set CITIES_DATA_STORE_POS to Vec3(1,2,3), you need to call the startup
function like this:

  require('claiming.startup').startup({
    CITIES_DATA_STORE_POS = Vec3(1,2,3)
  })

]]--
local pkg = {}

local DEFAULTS = {
  CITIES_DATA_STORE_POS = Vec3(0,0,0)    ,
  CLAIMING_DATA_STORE_POS = Vec3(0,2,0)  ,
  CLAIMING_WIDTH = 21                    ,
  CLAIMING_FREQUENCY = 20                ,
  CLAIMING_CREATVE_BUILD_ALLOWED = true
}

local toLua
local initialize

function pkg.startup(options)
  options = initialize(options, DEFAULTS)
  
  -- The Cities
  spell:execute([[
    /lua require('claiming.cities').start(%s)
  ]], toLua(options.CITIES_DATA_STORE_POS))
  
  -- The Claiming Spell
  spell:execute([[
    /lua local cities = require("claiming.cities").get()
    local funcCanClaimPos = function(pos)
      return cities:isInsideCityCenter(pos)
    end
    require('claiming.claiming').start(
      %s,
      {width=%s,frequency=%s, creativeBuildAllowed=%s},
      funcCanClaimPos
    )
  ]], toLua(options.CLAIMING_DATA_STORE_POS), options.CLAIMING_WIDTH, options.CLAIMING_FREQUENCY, options.CLAIMING_CREATVE_BUILD_ALLOWED)
  
  -- The Spawn Run
  spell:execute("/lua require('claiming.spawnrun').start()")

end

function toLua(vec)
  return string.format("Vec3(%s,%s,%s)", vec.x,vec.y,vec.z)
end

function initialize(target, defaults)
  target = target or {}
  for k,v in pairs(defaults) do
    if not target[k] then
      target[k] = v
    end
  end
  return target
end

return pkg

