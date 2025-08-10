-- vehicles/sv1ev3_twin/lua/ev_battery_controller.lua
local M = {}

function M.init(jbeamData)
  log('I','EVBATT','init() ran')               -- visible in console
  electrics.values.evbatt_heartbeat = 0        -- numeric counter we can read from Python
end

function M.updateGFX(dt)
  local e = electrics.values
  e.evbatt_heartbeat = (e.evbatt_heartbeat or 0) + dt
  e.soc = 0.77
  e.batteryVoltage = 371
  e.batteryCurrent = 12
  e.packPower = 4.5
  e.packTemp = 26.3
  e.soh = 0.99
  e.fuel = e.soc
  e.fuel_capacity = 81.4
  e.fuel_volume = e.fuel_capacity * e.soc
end

return M
