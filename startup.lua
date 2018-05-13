--[[ claiming/startup.lua

Name:           Claiming
Version:        1.0.0
Homepage:       https://github.com/wizards-of-lua/claiming
Authors:        Adrodoc, mickkay
Copyright:      2018, The Wizards of Lua
License:        GPL 3.0
Dependencies:   wol-1.12.2-2.0.2


You can use this startup script to activate the Claiming spell pack on your server.
Just execute it from your server's startup script, for example like this:

  spell:execute("/lua require('claiming.startup')")


The Claiming Spell Pack stores map-specific data into command blocks at 
certain locations. 
You can define where these command blocks are located by setting the 
respective variables CITIES_DATA_STORE_POS and CLAIMING_DATA_STORE_POS below.

]]--

function toLua(vec)
  return string.format("Vec3(%s,%s,%s)", vec.x,vec.y,vec.z)
end

local CITIES_DATA_STORE_POS = CITIES_DATA_STORE_POS or Vec3(751, 75, 355)
local CLAIMING_DATA_STORE_POS = CLAIMING_DATA_STORE_POS or Vec3(751, 77, 355)
local CLAIMING_WIDTH = 21
local CLAIMING_FREQUENCY = 20

-- The Cities
spell:execute([[
  /lua require('claiming.cities').start(%s)
]], toLua(CITIES_DATA_STORE_POS))

-- The Claiming Spell
spell:execute([[
  /lua local cities = require("claiming.cities").get()
  local funcCanClaimPos = function(pos)
    return cities:isInsideCityCenter(pos)
  end
  require('claiming.claiming').start(
    %s,
    {width=%s,frequency=%s},
    funcCanClaimPos
  )
]], toLua(CLAIMING_DATA_STORE_POS), CLAIMING_WIDTH, CLAIMING_FREQUENCY)

-- The Spawn Run
spell:execute("/lua require('claiming.spawnrun').start()")


