-- claiming-heads/startup.lua

local pkg = {}
local initialize
local DEFAULTS = {
  claimingWidth = 21              ,
  claimingFrequency = 20          ,
  restictCreativePlayer = false   ,
  funcCanClaimPos = function(pos) return true end
}

function pkg.start(options)
  options = initialize(options, DEFAULTS)
  require('claiming-heads.claiming').start(
    {width=options.claimingWidth,frequency=options.claimingFrequency, creativeBuildAllowed=not options.restictCreativePlayer},
    options.funcCanClaimPos
  )
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