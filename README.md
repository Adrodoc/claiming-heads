# Claiming Heads Spell Pack
The Claiming Heads Spell Pack is a [Wizards of Lua](http://www.wizards-of-lua.net) Add-on that adds claiming support to Minecraft worlds.

The intention of this spell pack is to support server owners who want to host "mostly vanilla" survival servers
but also want to restrict griefing. This spell pack provides a spell that protects certain areas - called claims -
so that only the players who own this area are allowed to build there. This is done by changing the game mode of
any unauthorized player from "survial" to "adventure" when he or she enters a protected area.
An area can be claimed by placing a "claiming head" in the middle of it. Claiming heads can be created by command.

## Playing Instructions
### How to Claim a Private Area?
Any player can claim an area simply by placing a "claiming head" (this is a player skull) into the world.

### How to Get a Claiming Head?
#### By Command
Just execute the following Minecraft command:
```
/give PLAYER skull 1 3 {SkullOwner:"PLAYER"}
```
Please replace *PLAYER* with the player's name.
#### By Spell
```lua
/lua name="PLAYER"; spell:execute([[/give %s skull 1 3 {SkullOwner:"%s"}]], name, name)
```
Please replace *PLAYER* with the player's name.

## How to Install?
This spell pack is dependent on [Minecraft Forge](http://files.minecraftforge.net/maven/net/minecraftforge/forge/index_1.12.2.html) 
and the [Wizards of Lua Modification](https://minecraft.curseforge.com/projects/wizards-of-lua/files).

These are the steps to install and run the Claiming Heads on your Minecraft Server:

1. **Install Minecraft Forge**

     Well, you should already know how to do that.
2. **Install Wizards of Lua**

     Download the JAR file containing the latest Version of 
     [Wizards of Lua Modification](https://minecraft.curseforge.com/projects/wizards-of-lua/files) and place it
     into the "mods" directory of your Minecraft server.
     
3. **Install Claiming Heads Spell Pack**

    Download the JAR file containing the latest Version of 
    [The Claiming Heads Spell Pack](https://minecraft.curseforge.com/projects/claiming-heads-spell-pack/files) and place it
    into the "mods" directory of your Minecraft server.
    
4. **Activate the Claiming Heads Spell on Server Startup**

    Create a file called "startup.lua" and place it into the "config/wizards-of-lua/libs/shared" directory of your Minecraft server.
    Insert the following lines into it:
    ```lua
    spell:execute([[ /lua require("claiming-heads.startup").start({
      datastore=Vec3(0,0,0), claimingWidth=21, restictCreativePlayer=false
    }) ]])
    ```
    
5. **Start the Server**

