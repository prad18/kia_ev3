-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}

local function init()
  electrics.values.auto_p = 0
  electrics.values.auto_d = 0
  electrics.values.auto_n = 0
  electrics.values.auto_d = 0
end

local function reset()
  init()
end

local function updateGFX(dt)
  local gearIndex = electrics.values.gearIndex or 0
  local gear_A = electrics.values.gear_A or 0
  --Rev
  electrics.values.auto_p = gear_A < 0.2 and 1 or 0
  --Reverse CVT
  electrics.values.auto_r = (gear_A >= 0.2 and gear_A < 0.4) and 1 or 0
  --Neutral CVT
  electrics.values.auto_n = (gear_A >= 0.4 and gear_A < 0.7) and 1 or 0
  --Drive CVT
  electrics.values.auto_d = gear_A >= 0.7 and 1 or 0
end

-- public interface
M.onInit = init
M.onReset = reset
M.updateGFX = updateGFX

return M
