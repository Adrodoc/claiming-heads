# Claiming Heads Spell Pack
The Claiming Heads Spell Pack is a [Wizards of Lua](http://www.wizards-of-lua.net) add-on that adds claiming support to Minecraft worlds.

The intention of this spell pack is to support server owners who want to host "mostly vanilla" survival servers
but also want to restrict griefing. This spell pack provides a spell that protects certain areas - called claims -
so that only the players who own this area are allowed to build there. This is done by changing the game mode of
any unauthorized player from "survial" to "adventure" (and by canceling every block place and break event) when he or she enters a protected area owned by another player.
An area can be claimed by placing a "claiming head" in the middle of it. Multi-owner claims are supported. Claiming heads can be created by command.

## How to Install?
This spell pack is dependent on [Minecraft Forge](http://files.minecraftforge.net/maven/net/minecraftforge/forge/index_1.12.2.html) 
and the [Wizards of Lua Modification](https://minecraft.curseforge.com/projects/wizards-of-lua/files).

These are the steps to install and run the Claiming Heads on your Minecraft Server:

1. **Install Minecraft Forge**

     Well, you should already know how to do that.
2. **Install Wizards of Lua**

     Download the JAR file containing the latest Version of 
     [Wizards of Lua Modification](https://minecraft.curseforge.com/projects/wizards-of-lua/files) and place it
     into the `mods` directory of your Minecraft server.
     
3. **Install Claiming Heads Spell Pack**

    Download the JAR file containing the latest Version of 
    [The Claiming Heads Spell Pack](https://minecraft.curseforge.com/projects/claiming-heads-spell-pack/files) and place it
    into the `mods` directory of your Minecraft server.
    
4. **Activate the Claiming Heads Spell on Server Startup**

    Create a file called `startup.lua` and place it into the `config/wizards-of-lua/libs/shared` directory of your Minecraft server.
    Insert the following lines into it:
    ```lua
    spell:execute([[ /lua require("claiming-heads.startup").start({
      datastore=Vec3(0,0,0), claimingWidth=21, restictCreativePlayer=false
    }) ]])
    ```
    The following options are supported:
    * **datastore**: (Vec3) This is the position of the command block that is used as a storage device. The Claiming Heads spell will store the claiming locations, sizes, and owners there.
    * **claimingWidth**: (Numeric) This defines the size of newly claimed areas. It's the distance measured in meters from the center to the northern, southern, western, and eastern border of the area. Please note that this only affects new claims. 
    * **restictCreativePlayer**: (boolean) This defines whether creative players are prevented from building in claimed areas. Valid values are *true* and *false*.
    * **claimingFrequency**: (numeric) This defines the number of game ticks that the Claiming Heads spell waits between two consecutive  checks of the player positions.
    * **funcCanClaimPos**: (function) This defines a predicate function on a given position (Vec3) that should return a boolean value that decides whether anybody can claim that position in principle.
    
    
5. **Restart the Server**


## Playing Instructions
### How to Claim an Area?
A player can claim any area simply by placing a "claiming head" (this is a player skull) into the center of that area.
By removing this head the area becomes unprotected again.

### How to Claim an Area for Multiple Owners?
This is really easy. Just take both heads into your inventory, then claim an area with your own head first, and finally place the other head somewhere above or below of yours.

### How to Get a Claiming Head?
#### By Command
Just execute the following Minecraft command:
```
/give PLAYER skull 1 3 {SkullOwner:"PLAYER"}
```
Please replace both occurrences of *PLAYER* with the actual player's name.
#### By Spell
```lua
/lua name=spell.owner.name; spell:execute([[/give %s skull 1 3 {SkullOwner:"%s"}]], name, name)
```
#### By Command Block
For example, to create a "claiming head dispenser" just insert the following line into a command block and attach a button to it.
```lua
/lua p=Entities.find("@p")[1]; spell:execute([[/give %s skull 1 3 {SkullOwner:"%s"}]], p.name, p.name)
```

## Advanced Configuration

### How to Show Claimed Areas?
Below is a handy function that shows the borders of the closest claimed area you are inside of.

To add this function to your server, please create a file called `shared-profile.lua` and place it into the `config/wizards-of-lua/libs/shared` directory of your Minecraft server. Then insert the following lines into it:

```lua
function showClaims()
  local player = spell.owner
  local claims = require('claiming-heads.claiming').getApplicableClaims(player.pos)
  local closest = nil
  for _,claim in pairs(claims) do
    local dist = (claim.pos - player.pos):sqrMagnitude()
    if not closest or dist < closest.dist then
      closest = { claim=claim, dist=dist}
    end
  end
  if closest then
    local visualizer = require('claiming-heads.claimvisualizer')
    visualizer.showBorders(player.name, closest.claim.pos, closest.claim.width)
  end
end
```

To cast a spell with this function, just open the chat line (by typing 'T') and send the following command:
```lua
/lua showClaims()
```
