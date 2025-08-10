-- vehicles/sv1ev3_twin/lua/ev_battery_controller.lua
local M = {}

function M.init(jbeamData)
  log('I','EVBATT','init() ran')               -- visible in console
  electrics.values.evbatt_heartbeat = 0        -- numeric counter we can read from Python

  -- read battery parameters provided in JBeam via v.data
  M.capFadeCoeff    = v.data.cap_fade_coeff    or 0.0
  M.resGrowthCoeff  = v.data.res_growth_coeff  or 0.0
  M.ocvTempCoeff    = v.data.ocv_temp_coeff    or 0.0
  M.thermalResCoeff = v.data.thermal_res_coeff or 0.0
end

function M.updateGFX(dt)
  local e = electrics.values
  e.evbatt_heartbeat = (e.evbatt_heartbeat or 0) + dt
  e.soc = 0.77
  e.batteryVoltage = 371
  e.batteryCurrent = 12
  e.packPower = 4.5
  e.packTemp = 26.3 + M.thermalResCoeff
  e.soh = 1 - M.capFadeCoeff
  e.resGrowthCoeff = M.resGrowthCoeff
  e.ocvTempCoeff = M.ocvTempCoeff
  e.fuel = e.soc
  e.fuel_capacity = 81.4
  e.fuel_volume = e.fuel_capacity * e.soc
end

return M
