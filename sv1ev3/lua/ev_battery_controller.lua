-- Simple battery management system for the SV1 EV3

local M = {}

-- tables holding constant pack parameters and runtime state
local B = {}
local state = {}

-- utility --------------------------------------------------------------------
local function clamp(v, minV, maxV)
  return v < minV and minV or (v > maxV and maxV or v)
end

-- open-circuit voltage approximation, linear with SOC and temperature
local function getOCV(soc)
  soc = clamp(soc, 0, 1)
  local ocv = B.nominal_V * (0.9 + 0.1 * soc)
  return ocv * (1 + B.ocv_temp_coeff * (state.packTemp - B.amb_C))
end

-- very simple lumped thermal model
local function updateThermal(dt, current)
  local R_int = B.R_int * (1 + B.res_growth_coeff * (1 - state.soh))
  local heatGen = current * current * R_int
  local ambient = B.amb_C
  local cooling = B.hA_WpK * (1 - B.thermal_res_coeff)
  local dT = (heatGen - cooling * (state.packTemp - ambient)) / B.heat_cap_JpK
  state.packTemp = clamp(state.packTemp + dT * dt, -50, 120)
end

-- accumulate throughput and reduce state of health
local function updateDegradation(dt, current, packTemp)
  state.throughput = state.throughput + math.abs(current) * dt / 3600 -- Ah
  local tempStress = math.max(0, packTemp - 25) * 0.01
  local wear = math.abs(current) * dt * 1e-7 * (1 + tempStress + B.cap_fade_coeff)
  state.soh = clamp(state.soh - wear, 0, 1)
end

function M.init(jbeamData)
  -- parse jbeam variables and expose them through v.data
  B.pack_kWh          = jbeamData.pack_kWh          or 81.4
  B.nominal_V         = jbeamData.nominal_V         or 370
  B.R_int             = jbeamData.R_int             or 0.010
  B.soc0              = jbeamData.soc0              or 0.80
  B.amb_C             = jbeamData.amb_C             or 25.0
  B.eff_mot           = jbeamData.eff_mot           or 0.92
  B.eff_regen         = jbeamData.eff_regen         or 0.80
  B.heat_cap_JpK      = jbeamData.heat_cap_JpK      or 16000
  B.hA_WpK            = jbeamData.hA_WpK            or 75
  B.cap_fade_coeff    = jbeamData.cap_fade_coeff    or 0.0 -- capacity fade coefficient
  B.res_growth_coeff  = jbeamData.res_growth_coeff  or 0.0 -- internal resistance growth coefficient
  B.ocv_temp_coeff    = jbeamData.ocv_temp_coeff    or 0.0 -- OCV temperature dependence coefficient
  B.thermal_res_coeff = jbeamData.thermal_res_coeff or 0.0 -- additional thermal resistance coefficient

  for k, val in pairs(B) do
    v.data[k] = val
  end

  -- derived constants
  B.capacity_Ah = (B.pack_kWh * 1000) / B.nominal_V
  B.capacity_As = B.capacity_Ah * 3600

  -- initial state
  state.soc = clamp(B.soc0, 0, 1)
  state.packTemp = B.amb_C
  state.throughput = 0
  state.soh = 1
  state.voltage = getOCV(state.soc)

  electrics.values.evbatt_heartbeat = 0
  log('I', 'EVBATT', 'init() ran')
end

function M.updateGFX(dt)
  local e = electrics.values
  e.evbatt_heartbeat = (e.evbatt_heartbeat or 0) + dt

  -- estimate current draw from available electrics values (power in Watts)
  local power = e.motorPower or e.electricsPower or e.power or 0
  local voltage = getOCV(state.soc)
  local current = 0
  if voltage > 0 then
    current = power / voltage
  end

  -- coulomb counting with simple efficiency model
  local effectiveCurrent = current >= 0 and current / B.eff_mot or current * B.eff_regen
  state.soc = clamp(state.soc - effectiveCurrent * dt / B.capacity_As, 0, 1)

  -- terminal voltage with internal resistance growth
  local R_int = B.R_int * (1 + B.res_growth_coeff * (1 - state.soh))
  voltage = getOCV(state.soc) - current * R_int
  voltage = math.max(0, voltage)
  state.voltage = voltage

  -- auxiliary models
  updateThermal(dt, current)
  updateDegradation(dt, current, state.packTemp)

  -- compute pack power (kW)
  local packPower = voltage * current / 1000

  -- publish values
  e.soc = state.soc
  e.batteryVoltage = voltage
  e.batteryCurrent = current
  e.packPower = packPower
  e.packTemp = state.packTemp
  e.soh = state.soh
  e.capFadeCoeff = B.cap_fade_coeff
  e.resGrowthCoeff = B.res_growth_coeff
  e.ocvTempCoeff = B.ocv_temp_coeff
  e.thermalResCoeff = B.thermal_res_coeff
  e.fuel = state.soc
  e.fuel_capacity = B.pack_kWh
  e.fuel_volume = B.pack_kWh * state.soc
end

return M
