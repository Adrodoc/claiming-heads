# Claiming Heads Spell Pack
The Claiming Heads Spell Pack is a [Wizards of Lua](http://www.wizards-of-lua.net) add-on that adds claiming support to Minecraft worlds.

The intention of this spell pack is to support server owners who want to host "mostly vanilla" survival servers
but also want to restrict griefing. This spell pack provides a spell that protects certain areas - called claims -
so that only the players who own this area are allowed to build there. This is done by changing the game mode of
any unauthorized player from "survial" to "adventure" (and by canceling every block place and break event) when he or she enters a protected area owned by another player.
An area can be claimed by placing a "claiming head" in the middle of it. Multi-owner claims are supported. Claiming heads can be created by command.

You can give the Claiming Heads mod a try at our alpha server: ```mc.wizards-of-lua.net:30200```

## How to Install?
This spell pack is dependent on [Minecraft Forge](http://files.minecraftforge.net/maven/net/minecraftforge/forge/index_1.12.2.html)
and the [Wizards of Lua Modification](https://minecraft.curseforge.com/projects/wizards-of-lua/files), version 2.5.0 or later.

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

4. **Restart the Server**

## Playing Instructions
### How to Claim an Area?
A player can claim any area simply by placing a "claiming head" (this is a player skull) into the center of that area.
By removing this head the area becomes unprotected again.

### How to Claim an Area for Multiple Owners?
This is really easy. Just take both heads into your inventory, then claim an area with your own head first, and finally place the other head somewhere above or below of yours.

### How to Get a Claiming Head?
#### By Vanilla Command
Just execute the following Minecraft command:
```
/give PLAYER skull 1 3 {SkullOwner:"PLAYER"}
```
Please replace both occurrences of *PLAYER* with the actual player's name.
#### By Spell Pack Command
```
/give-head <player> [<head's owner>]
```
Examples:
```
/give-head adrodoc
```
gives adrodoc his own head.
```
/give-head adrodoc mickkay
```
gives adrodoc mickkay's head.
```
/give-head adrodoc @a
```
gives adrodoc the heads of all players logged in.
```
/give-head @a
```
gives all players their own head.
```
/give-head @a adrodoc
```
gives all players adrodoc's head.
```
/give-head @a @a
```
gives all players the heads of all players logged in.
```
/give-head @p
```
gives the closest player his or her own head.


### How to Show the Borders of Claimed Areas?
#### By Spell Pack Command
```
/show-claim
```
shows the border of the (closest) claimed area you are currently inside for some seconds.

## Advanced Configuration

To configure this spell pack please [edit the file](http://www.wizards-of-lua.net/tutorials/importing_lua_files/) called `startup.lua`
(which should be inside the `config/wizards-of-lua/libs/shared` directory of your Minecraft server).
This can be done with ```/wol shared-file edit startup.lua```.

### How to Increase Claim Sizes?
Just add the following lines to `startup.lua`.

```lua
Events.on("claiming-heads.StartupEvent"):call(function(event)
  local data = event.data
  data.claimingWidth = 28
end)
```
This defines the size of new claimed areas. Actually the value 28 is the distance of the claim's center to its borders.

Here is a list of all properties that can be configured:

* **claimingWidth**: (Numeric) This defines the size of newly claimed areas. It's the distance measured in meters from the center to the northern, southern, western, and eastern border of the area. Please note that this only affects new claims.
* **restictCreativePlayer**: (boolean) This defines whether creative players are prevented from building in claimed areas. Valid values are *true* and *false*.
* **claimingFrequency**: (numeric) This defines the number of game ticks that the Claiming Heads spell waits between two consecutive  checks of the player positions. Default is 20.
* **enableCommands**: (boolean) This defines whether the built-in commands ```/give-head``` and ```/show-claim``` should be registered. Default is true.

### How to Restrict Claims to Villages?
If you want to restrict new claims to be allowed only inside populated villages (where villagers are living), you
can intercept the "ClaimEvent" and cancel it, if it happend outside of a village.

Just add the following lines to `startup.lua`.

```lua
Events.on("claiming-heads.ClaimEvent"):call(function(event)
  local pos = event.data.pos
  local isCloseToVillage = spell.world:getNearestVillage(pos, 10)
  event.data.canceled = not isCloseToVillage
end)
```

### How to Allow or Deny Certain Positions?
You can override the decision whether a player can build at a given position by intercepting the "MayBuildEvent".

For example, the following code allows that a player can destroy a block even when it's part of a foreign claim when he is holding an item tagged with "CanDestroy" for
that specific block.

Just add the following lines to `startup.lua`.

```lua
Events.on("claiming-heads.MayBuildEvent"):call(function(event)
  local item = event.data.player.mainhand
  if item then
    local nbt = item.nbt
    if nbt and nbt.tag and nbt.tag.CanDestroy then
      for _,name in pairs(nbt.tag.CanDestroy) do
        if name == event.data.block.name then
          event.data.result = true
          break
        end
      end
    end
  end
end)

```
