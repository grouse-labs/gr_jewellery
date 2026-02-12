local RES_NAME <const> = bridge._RESOURCE
local DEBUG_MODE <const> = bridge._DEBUG
local JEWELLERY_CASES <const> = glib.require(RES_NAME..'.shared.jewellery_cases') --[[@module 'gr_jewellery.shared.jewellery_cases']]
local LOCATIONS <const> = glib.require(RES_NAME..'.shared.store_locations') --[[@module 'gr_jewellery.shared.store_locations']]
local CONFIG <const> = glib.require(RES_NAME..'.server.config') --[[@module 'gr_jewellery.server.config']]
local LOCK_COOLDOWN <const> = CONFIG.cooldowns.locks * 60
local CASE_COOLDOWN <const> = CONFIG.cooldowns.cases * 60
local ALARM_COOLDOWN <const> = CONFIG.cooldowns.alarm * 60
local OPEN_HOUR <const> = CONFIG.hours.open
local CLOSE_HOUR <const> = CONFIG.hours.close
local AUTOLOCK <const> = CONFIG.autolock
local PATROLS_CONFIG <const> = CONFIG.patrols
local REWARDS <const> = CONFIG.rewards
local PATROLS <const> = glib.require(RES_NAME..'.server.patrols') --[[@module 'gr_jewellery.server.patrols']]
local WEATHER_PRESENT <const> = pcall(function() return bridge.weather end)
local Cases = {}
local Stores = {}
local PresenceCache = {}
local Cooldowns = {}
local translate = glib.locale.translate

-------------------------------- FUNCTIONS --------------------------------

---@param location string
---@param _type string
---@param state boolean
---@param and_sec boolean?
local function set_door_state(location, _type, state, and_sec)
  local src = source ~= -1 and source or GetPlayers()[1]
  if not IsSrcAPlayer(src) then return end
  if _type == 'hit' then
    local doors = LOCATIONS[location]?.doors
    if not doors or not doors[1] then error(translate('debug.no_doors', {location = location})) end
    bridge.doorlock.setstate(src, doors[1], not state)
    Stores[location].locked = not state
    if and_sec and doors[2] then
      bridge.doorlock.setstate(src, doors[2], not state)
    end
  elseif _type == 'hacked' then
    for k, v in pairs(LOCATIONS) do
      if v.doors then
        for i = 1, #v.doors do
          local door = v.doors[i]
          if not door then error(translate('debug.no_door_i', {index = i, location = location})) end
          bridge.doorlock.setstate(src, door, not state)
        end
        Stores[k].locked = not state
      end
    end
  end
end

---@return boolean open
local function is_store_open()
  if not WEATHER_PRESENT then return false end
  local hour = bridge.weather.gettime()
  return hour >= OPEN_HOUR and hour < CLOSE_HOUR
end

---@async
local function main_thread()
  if PATROLS_CONFIG.enable then
    for _, v in pairs(PATROLS) do
      exports[PATROLS_CONFIG.name]:createpatrol(v)
    end
  end
  while true do
    Wait(1000)
    for location, _types in pairs(Cooldowns) do
      if _types.locks and _types.locks ~= 0 then
        _types.locks -= 1
        if _types.locks == 0 then
          set_door_state(location, 'hacked', false)
          Stores[location].hit = false
          Stores[location].hacked = false
        end
      elseif AUTOLOCK then
        if not is_store_open() then
          if not Stores[location].locked then
            GlobalState:set(('jewellery:open:%s'):format(location), false, true)
            set_door_state(location, 'hit', false, true)
          end
        elseif Stores[location].locked then
          GlobalState:set(('jewellery:open:%s'):format(location), true, true)
          set_door_state(location, 'hit', true, false)
        end
      end
      for i = 1, #_types.cases do
        local case = _types.cases[i]
        if case then
          _types.cases[i] -= 1
          if _types.cases[i] == 0 then
            Cases[location][i].open = false
            TriggerClientEvent('jewellery:client:SetCaseState', -1, location, i, false)
          end
        end
      end
      if _types.alarm then
        _types.alarm -= 1
        if _types.alarm == 0 then
          GlobalState[('jewellery:alarm:%s'):format(location)] = false
        end
      end
    end
  end
end

---@param resource string
local function init_script(resource)
  if resource ~= RES_NAME then return end
  for location, data in pairs(JEWELLERY_CASES) do
    Cases[location] = {}
    Stores[location] = {
      coords = LOCATIONS[location] and LOCATIONS[location].coords,
      police = LOCATIONS[location] and LOCATIONS[location].police,
      hit = false,
      hacked = false,
      locked = true
    }
    Cooldowns[location] = {locks = false, cases = {}, alarm = false}
    for i = 1, #data do
      local case = data[i]
      Cases[location][i] = {
        coords = case.coords,
        busy = false,
        open = false
      }
      Cooldowns[location].cases[i] = false
    end
    GlobalState:set(('jewellery:open:%s'):format(location), false, true)
    GlobalState:set(('jewellery:alarm:%s'):format(location), false, true)
  end
  SetTimeout(2000, function()
    glib.github.check(resource, 'grouse-labs', 'gr_jewellery')
    local version = GetResourceMetadata(resource, 'version', 0)
    version = version:match('(%d+%.%d+)'):gsub('(%d+)%.(%d+)', 'v^4%1^7.^4%2^7')
    bridge.print(translate('debug.enable', {version = version, state = DEBUG_MODE and '^2Enabled' or '^1Disabled'}))
    main_thread()
  end)
end

---@param resource string
local function deinit_script(resource)
  if resource ~= RES_NAME then return end
  Cases = {}
  Stores = {}
  PresenceCache = {}
  Cooldowns = {}
  for k in pairs(LOCATIONS) do GlobalState:set(('jewellery:alarm:%s'):format(k), false, true) end
end

---@param player string|integer
local function give_case_reward(player)
  local reward = REWARDS[math.random(#REWARDS)]
  local item = reward.item
  local amount = type(reward.amount) == 'table' and math.random(reward.amount.min, reward.amount.max) or reward.amount
  if bridge.core.addplayeritem(player, item, amount) then
    bridge.notify.item(player, item, amount)
  else
    bridge.notify.text(player, translate('error.too_much'), 'error')
  end
end

---@param location string
---@param state boolean
local function set_alarm_state(location, state)
  if not LOCATIONS[location] or GlobalState[('jewellery:alarm:%s'):format(location)] == state then return end
  GlobalState:set(('jewellery:alarm:%s'):format(location), state, true)
  Cooldowns[location].alarm = state and ALARM_COOLDOWN
end

---@param location string
---@param case integer
---@param _type string
---@param state boolean
local function set_case_state(location, case, _type, state)
  local src = source
  if not bridge.core.getplayer(src) then return end
  if not PresenceCache[src] then return end -- Triggered without using target
  if not JEWELLERY_CASES[location][case] then return end
  if #(JEWELLERY_CASES[location][case].coords - GetEntityCoords(GetPlayerPed(src))) > 1.5 then return end
  Cases[location][case][_type] = state
  if _type ~= 'busy' then
    Cooldowns[location].cases[case] = state and CASE_COOLDOWN
    TriggerClientEvent('jewellery:client:SetCaseState', -1, location, case, state)
    if not state then return end
    give_case_reward(src)
    if Stores[location].hacked or GlobalState[('jewellery:alarm:%s'):format(location)] then return end
    set_alarm_state(location, true)
  end
end

---@param location string
local function thermite_effect(location)
  local src = source
  if not bridge.core.getplayer(src) then return end
  if not PresenceCache[src] then return end -- Triggered without using target
  if not LOCATIONS[location] then return end
  if #(LOCATIONS[location].thermite.coords - GetEntityCoords(GetPlayerPed(src))) > 1.5 then return end
  TriggerClientEvent('jewellery:client:SyncThermite', -1, location)
end

---@param location string
---@param _type string
---@param state boolean
local function set_store_state(location, _type, state)
  local src = source
  if not bridge.core.getplayer(src) then return end
  if not PresenceCache[src] then return end -- Triggered without using target
  if not LOCATIONS[location] then return end
  if #(LOCATIONS[location].coords - GetEntityCoords(GetPlayerPed(src))) > 100.0 then return end
  if _type == 'hit' and state then
    local item = LOCATIONS[location].thermite.item
    if not bridge.core.doesplayerhaveitem(src, item) then return end -- Triggered without item, definitely cheating
    SetTimeout(1000, function()
      bridge.core.removeplayeritem(src, item, 1)
      bridge.notify.item(src, item, -1)
      set_alarm_state(location, false)
    end)
  elseif _type == 'hack' and state then
    local item = LOCATIONS[location].hack.item
    if not bridge.core.doesplayerhaveitem(src, item) then return end -- Triggered without item, definitely cheating
    set_alarm_state(location, false)
  end
  Stores[location][_type] = state
  Cooldowns[location].locks = state and LOCK_COOLDOWN
  set_door_state(location, _type, state)
end

---@param player string|integer
---@return table? cases
local function get_case_states(player)
  if not bridge.core.getplayer(player) then return end
  return Cases
end

---@param player string|integer
---@return boolean?
local function is_case_busy(player)
  if not bridge.core.getplayer(player) then return end
  local coords = GetEntityCoords(GetPlayerPed(player))
  for _, data in pairs(Cases) do
    for i = 1, #data do
      local case = data[i]
      if #(case.coords - coords) < 1.0 then
        return case.busy
      end
    end
  end
  return true
end

---@param player string|integer
---@param location string
---@return boolean?
local function get_police_presence(player, location)
  if not bridge.core.getplayer(player) then return end
  local coords = GetEntityCoords(GetPlayerPed(player))
  local store = Stores[location]
  if #(store.coords - coords) > 100.0 then return end
  local players = GetPlayers()
  local leo_jobs = GetTypeJobs('leo')
  local amount = 0
  for i = 1, #players do amount += bridge.core.doesplayerhavegroup(players[i], leo_jobs) and 1 or 0 end
  PresenceCache[player] = amount
  return amount >= store.police
end

---@param player string|integer
---@param location string
---@return boolean?, boolean?
local function is_store_vulnerable(player, location)
  if not bridge.core.getplayer(player) then return end
  if not Stores[location] then return end
  local coords = GetEntityCoords(GetPlayerPed(player))
  local store = Stores[location]
  if #(store.coords - coords) > 100.0 then return end
  return store.hacked, store.hit
end

-------------------------------- EVENTS --------------------------------

AddEventHandler('onResourceStart', init_script)
AddEventHandler('onResourceStop', deinit_script)
RegisterServerEvent('jewellery:server:SetCaseState', set_case_state)
RegisterServerEvent('jewellery:server:SyncThermite', thermite_effect)
RegisterServerEvent('jewellery:server:SetStoreState', set_store_state)

-------------------------------- EXPORTS --------------------------------

exports('setcasestate', set_case_state)
exports('setalarmstate', set_alarm_state)
exports('setstorestate', set_store_state)
exports('getcasestates', get_case_states)
exports('iscasebusy', is_case_busy)
exports('getpolicepresence', get_police_presence)
exports('isstorevulnerable', is_store_vulnerable)
exports('isstoreopen', is_store_open)

-------------------------------- CALLBACKS --------------------------------

bridge.callback.register('jewellery:server:GetCaseStates', get_case_states)
bridge.callback.register('jewellery:server:IsCaseBusy', is_case_busy)
bridge.callback.register('jewellery:server:GetPolicePresence', get_police_presence)
bridge.callback.register('jewellery:server:IsStoreVulnerable', is_store_vulnerable)
bridge.callback.register('jewellery:server:IsStoreOpen', is_store_open)
