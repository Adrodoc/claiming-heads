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

-- The Cities
spell:execute([[
  /lua local CITIES_DATA_STORE_POS = Vec3(751, 75, 355)
  require('claiming.cities').start(CITIES_DATA_STORE_POS)
]])

-- The Claiming Spell
spell:execute([[
  /lua local CLAIMING_DATA_STORE_POS = Vec3(751, 77, 355)
  local cities = require("claiming.cities").get()
  local funcCanClaimPos = function(pos)
    return cities:isInsideCityCenter(pos)
  end
  require('claiming.claiming').start(
    CLAIMING_DATA_STORE_POS,
    {width=21,frequency=20},
    funcCanClaimPos
  )
]])

-- The Spawn Run
spell:execute("/lua require('claiming.spawnrun').start()")

