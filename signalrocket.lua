-- claiming/signalrocket.lua

local pkg = {}

function pkg.give(amount, player)
  amount = amount or 1
  player = player or spell.owner
  local giveCmd = string.format([[
    /give %s minecraft:fireworks %s 0 {
      Fireworks:{
        Flight:2 ,Explosions:[{
          Type:6 ,Colors:[7995154,16252672,15615],FadeColors:[16777215]
        }]
      },
      ench:[{id:999,lvl:1}],
      display:{
        Name:"Zone Runners Signal Rocket"
      }
    }
  ]], player.name, amount)
  spell:execute(giveCmd)
end

function pkg.summon(lifetime)
  lifetime = lifetime or 25
  local summonCmd = string.format([[
    /summon minecraft:fireworks_rocket ~ ~ ~ {
      LifeTime:%s,FireworksItem:{
        id:"minecraft:fireworks",Count:1b,tag:{
          Fireworks:{
            Flight:2 ,Explosions:[{
              Type:6 ,Colors:[7995154,16252672,15615],FadeColors:[16777215]
            }]
          }
        }
      }
    }
  ]], lifetime)
  spell:execute(summonCmd)
end

return pkg

