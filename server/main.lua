local RES_NAME <const> = bridge._RESOURCE
local DEBUG_MODE <const> = bridge._DEBUG
local JEWELLERY_CASES <const> = glib.require(RES_NAME..'.shared.jewellery_cases') --[[@module 'gr_jewellery.shared.jewellery_cases']]
local LOCATIONS <const> = glib.require(RES_NAME..'.shared.store_locations') --[[@module 'gr_jewellery.shared.store_locations']]
local Cases = {}
local Stores = {}
local alarm = false

local TimeOuts = {
  [1] = false,
  [2] = false,
  [3] = false
}

local CachedPoliceAmount = {}
local Flags = {}


-------------------------------- FUNCTIONS --------------------------------

---@param resource string
local function init_script(resource)
  if resource ~= RES_NAME then return end
  for location, data in pairs(JEWELLERY_CASES) do
    Cases[location] = {}
    Stores[location] = {
      coords = LOCATIONS[location] and LOCATIONS[location].coords,
      police = LOCATIONS[location] and LOCATIONS[location].police,
      hit = false,
      hacked = false
    }
    for i = 1, #data do
      local case = data[i]
      Cases[location][i] = {
        coords = case.coords,
        busy = false,
        open = false
      }
    end
  end
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

local function is_store_hacked(player, location)
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

local function randomNum(min, max)
  math.randomseed(os.time())
  local num = math.random() * (max - min) + min
  if num % 1 >= 0.5 and math.ceil(num) <= max then
    return math.ceil(num)
  end
  return math.floor(num)
end

local function exploitBan(id, reason)
  MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)',
    {
      GetPlayerName(id),
      bridge.core.getplayeridentifier(id),
      ('discord:' .. (GetPlayerIdentifierByType(id, 'discord') or 'N/A')),
      GetPlayerIdentifierByType(id, 'ip') or 'N/A',
      reason,
      2147483647,
      'don-jewellery'
    }
  )
  TriggerEvent('qb-log:server:CreateLog', 'jewellery', 'Player Banned', 'red',
  string.format('%s was banned by %s for %s', GetPlayerName(id), 'don-jewellery', reason), true)
  DropPlayer(id, 'You were permanently banned by the server for: Exploiting')
end

-------------------------------- EVENTS --------------------------------

AddEventHandler('onResourceStart', init_script)
AddEventHandler('onResourceStop', deinit_script)
RegisterServerEvent('jewellery:server:SetCaseState', set_case_state)
RegisterServerEvent('jewellery:server:VangelicoAlarm', set_alarm_state)

RegisterServerEvent('don-jewellery:server:RemoveDoorItem', function()
  local src = source
  local Player = bridge.core.getplayer(src)
  local item = Config.DoorItem
  if not Player then return end
  bridge.core.removeplayeritem(src, item, 1)
end)

RegisterServerEvent('don-jewellery:server:SetVitrineState', function(stateType, state, k)
  if stateType == 'isBusy' and type(state) == 'boolean' and Config.Vitrines[k] then
    Config.Vitrines[k][stateType] = state
    TriggerClientEvent('don-jewellery:client:SetVitrineState', -1, stateType, state, k)
  end
end)

RegisterServerEvent('don-jewellery:server:StoreHit', function(storeIndex, bool)
  local src = source
  local Player = bridge.core.getplayer(src)
  if not Player then return end
  TriggerClientEvent('don-jewellery:client:StoreHit', -1, storeIndex, bool)
  if storeIndex == 'all' then Config.Stores[1].hacked = bool end
  for i = 1, #Config.Stores do
    if storeIndex == 'all' then
      Config.Stores[i].hit = bool
    else
      if i == storeIndex then
        Config.Stores[storeIndex].hit = bool
      end
    end
  end
end)

RegisterServerEvent('don-jewellery:server:ToggleDoorlocks', function(store, locked, allStores)
  local src = source
  if not allStores then
    if not Config.Stores[store] then return end
    if Config.DoorLock == 'qb' then
      TriggerClientEvent('qb-doorlock:client:setState', -1, src, Config.Stores[store]['Doors'].main, locked, src, false, false)
    elseif Config.DoorLock == 'ox' then
      local success, door = pcall(function()
        return exports['ox_doorlock']:getDoorFromName('jewellery_stores ' ..Config.Stores[store]['Doors'].main)
      end)
      if success and door then
        TriggerEvent('ox_doorlock:setState', door.id, locked)
      end
    elseif Config.DoorLock == 'cd' then
      TriggerClientEvent('cd_doorlock:SetDoorState_name', -1, locked, Config.Stores[store]['Doors'].main, 'Jewellery Stores')
    end
  else
    for i = 1, #Config.Stores do
      if Config.DoorLock == 'qb' then
        TriggerClientEvent('qb-doorlock:client:setState', -1, src, Config.Stores[i]['Doors'].main, locked, src, false, false)
        TriggerClientEvent('qb-doorlock:client:setState', -1, src, Config.Stores[i]['Doors'].sec, locked, src, false, false)
      elseif Config.DoorLock == 'ox' then
        local success1, main = pcall(function()
          return exports['ox_doorlock']:getDoorFromName('jewellery_stores ' ..Config.Stores[i]['Doors'].main)
        end)
        local success2, sec = pcall(function()
          return exports['ox_doorlock']:getDoorFromName('jewellery_stores ' ..Config.Stores[i]['Doors'].sec)
        end)
        if success1 and main then
          TriggerEvent('ox_doorlock:setState', main.id, locked)
        end
        if success2 and sec then
          TriggerEvent('ox_doorlock:setState', sec.id, locked)
        end
      elseif Config.DoorLock == 'cd' then
        TriggerClientEvent('cd_doorlock:SetDoorState_name', -1, locked, Config.Stores[i]['Doors'].main, 'Jewellery Stores')
        TriggerClientEvent('cd_doorlock:SetDoorState_name', -1, locked, Config.Stores[i]['Doors'].sec, 'Jewellery Stores')
      end
    end
  end
end)

RegisterServerEvent('don-jewellery:server:VitrineReward', function(vitrineIndex)
  local src = source
  local Player = bridge.core.getplayer(src)
  local cheating = false
  if not Config.Vitrines[vitrineIndex] or Config.Vitrines[vitrineIndex].isOpened then 
    exploitBan(src, 'Trying to trigger an exploitable event \"don-jewellery:server:VitrineReward\"') 
    return 
  end
  if not CachedPoliceAmount[src] then DropPlayer(src, 'Exploiting') return end

  local plrPed = GetPlayerPed(src)
  local plrCoords = GetEntityCoords(plrPed)
  local vitrineCoords = Config.Vitrines[vitrineIndex].coords
  if CachedPoliceAmount[src] >= Config.RequiredCops then
    if plrPed then
      local dist = #(plrCoords - vitrineCoords)
      if dist <= 25.0 then
        Config.Vitrines[vitrineIndex].isOpened = true
        Config.Vitrines[vitrineIndex].isBusy = false
        TriggerClientEvent('don-jewellery:client:SetVitrineState', -1, 'isOpened', true, vitrineIndex)
        TriggerClientEvent('don-jewellery:client:SetVitrineState', -1, 'isBusy', false, vitrineIndex)

        local reward = Config.VitrineRewards[randomNum(1, #Config.VitrineRewards)]
        local amount = randomNum(reward['Amounts'].min, reward['Amounts'].max)
        if bridge.core.addplayeritem(src, reward.item, amount) then
          bridge.notify.item(src, reward.item, amount)
        else
          bridge.notify.text(src, Lang:t('error.to_much'), 'error')
        end
      else
        cheating = true
      end
    end
  else
    cheating = true
  end

  if cheating then
    local license = bridge.core.getplayeridentifier(src)
    if Flags[license] then
      Flags[license] = Flags[license] + 1
    else
      Flags[license] = 1
    end
    if Flags[license] >= 3 then
      exploitBan('Getting flagged many times from exploiting the \"don-jewellery:server:VitrineReward\" event')
    else
      DropPlayer(src, 'Exploiting')
    end
  end
end)

RegisterServerEvent('don-jewellery:server:SetTimeout', function(vitrine)
  local store = 0
  if vitrine >= 1 and vitrine <= 20 then
    store = 1
  elseif vitrine >= 21 and vitrine <= 26 then
    store = 2
  elseif vitrine >= 27 and vitrine <= 32 then
    store = 3
  end
  if not TimeOuts[store] then
    TimeOuts[store] = true
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'jewellery', true)
    CreateThread(function()
      Wait(Config.Timeout)
      Config.Stores[1].hacked = false
      for i = 1, #Config.Stores do
        Config.Stores[i].hit = false
      end
      TriggerClientEvent('don-jewellery:client:StoreHit', -1, 'all', false)
      for i = 1, #Config.Vitrines do
        Config.Vitrines[i].isOpened = false
        TriggerClientEvent('don-jewellery:client:SetVitrineState', -1, 'isOpened', false, i)
        TriggerClientEvent('don-jewellery:client:SetAlertState', -1, false)
        TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'jewellery', false)
      end
      TimeOuts[store] = false
    end)
  end
end)

-------------------------------- CALLBACKS --------------------------------

bridge.callback.register('don-jewellery:server:GetCops', function(source)
  local src = source
	local amount = 0
  for _, playerId in ipairs(GetPlayers()) do
    local id = tonumber(playerId)
    if id then
      local job = bridge.core.getplayerjob(id)
      if job and bridge.core.doesplayerhavegroup(id, 'leo') then
        amount = amount + 1
      end
    end
  end
  CachedPoliceAmount[src] = amount
  return amount
end)

bridge.callback.register('don-jewellery:server:GetJewelleryState', function()
  local data = {Locations = Config.Vitrines, Hacks = Config.Stores}
	return data
end)

bridge.callback.register('jewellery:server:GetCaseStates', function(player)
  if not bridge.core.getplayer(player) then return end
  return Cases
end)

bridge.callback.register('jewellery:server:IsCaseBusy', is_case_busy)

bridge.callback.register('jewellery:server:IsStoreVulnerable', is_store_vulnerable)
