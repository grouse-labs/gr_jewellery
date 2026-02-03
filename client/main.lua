local RES_NAME <const> = bridge._RESOURCE
local JEWELLERY_CASES <const> = glib.require(RES_NAME..'.shared.jewellery_cases') --[[@module 'gr_jewellery.shared.jewellery_cases']]
local LOCATIONS <const> = glib.require(RES_NAME..'.shared.store_locations') --[[@module 'gr_jewellery.shared.store_locations']]
local start_case_models = {`des_jewel_cab_start`, `des_jewel_cab2_start`, `des_jewel_cab3_start`, `des_jewel_cab4_start`}
local Zones = {}
local isLoggedIn = false

local firstAlarm, secondAlarm, smashing, locked  = false, false, false, false

-------------------------------- FUNCTIONS --------------------------------

local function loadPtfx(name)
	if HasNamedPtfxAssetLoaded(name) then UseParticleFxAsset(name) return end
  RequestNamedPtfxAsset(name)
  repeat Wait(0) until HasNamedPtfxAssetLoaded(name)
  UseParticleFxAsset(name)
end

local function loadAnimDict(dict)
  if HasAnimDictLoaded(dict) then return end
  RequestAnimDict(dict)
  repeat Wait(0) until HasAnimDictLoaded(dict)
end

local function randomNum(min, max)
  math.randomseed(GetGameTimer())
  local num = math.random() * (max - min) + min
  if num % 1 >= 0.5 and math.ceil(num) <= max then
    return math.ceil(num)
  end
  return math.floor(num)
end

local function isStoreHit(vitrine, isStore)
  local hit = false
  if not vitrine then goto all end
  if isStore then goto store end
  if vitrine >= 1 and vitrine <= 20 then
    store = 1
  elseif vitrine >= 21 and vitrine <= 26 then
    store = 2
  elseif vitrine >= 27 and vitrine <= 32 then
    store = 3
  end
  if Config.Stores[store].hit then
    return true
  else
    return false
  end
  ::all::
  for i = 1, #Config.Stores do
    local v = Config.Stores[i]
    if v.hit then 
      hit = true 
    end
  end
  if hit then return true else return false end
  ::store::
  if Config.Stores[vitrine].hit then return true end
  return false
end

local function isStoreHacked()
  if Config.Stores[1].hacked then
    return true
  end
  return false 
end

local function createBlips()
  if not Config.OneStore then
    for k, v in pairs(Config.Stores) do
      local Dealer = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
      SetBlipSprite (Dealer, 617)
      SetBlipDisplay(Dealer, 4)
      SetBlipScale  (Dealer, 0.7)
      SetBlipAsShortRange(Dealer, true)
      SetBlipColour(Dealer, 3)
      AddTextEntry(v.label, v.label)
      BeginTextCommandSetBlipName(v.label)
      EndTextCommandSetBlipName(Dealer)
    end
  else
    local Dealer = AddBlipForCoord(Config.Stores[1].coords.x, Config.Stores[1].coords.y, Config.Stores[1].coords.z)
    SetBlipSprite (Dealer, 617)
    SetBlipDisplay(Dealer, 4)
    SetBlipScale  (Dealer, 0.7)
    SetBlipAsShortRange(Dealer, true)
    SetBlipColour(Dealer, 3)
    AddTextEntry(Config.Stores[1].label, Config.Stores[1].label)
    BeginTextCommandSetBlipName(Config.Stores[1].label)
    EndTextCommandSetBlipName(Dealer)
  end
end

local function removeBlips()
  local blip = GetFirstBlipInfoId(617)
  repeat RemoveBlip(blip); blip = GetNextBlipInfoId(617) until not DoesBlipExist(blip)
end

local function checkTime(start, finish)
  finish = finish - 1
  local hour = GetClockHours()
  local minute = GetClockMinutes()
  local isTime = false
  if start > finish then
    if hour == start then
      isTime = true
    elseif hour == 0 then
      isTime = true
    elseif hour <= finish then
      isTime = true
    else
      isTime = false
    end
  else
    if start <= hour and finish >= hour then
      isTime = true
    else
      isTime = false
    end
  end
  return isTime
end

local function validWeapon()
  local ped = PlayerPedId()
  local pedWeapon = GetSelectedPedWeapon(ped)
  for k, _ in pairs(Config.WhitelistedWeapons) do
    if pedWeapon == k then
      return true
    end
  end
  return false
end

local function isWearingHandshoes()
  local ped = PlayerPedId()
  local armIndex = GetPedDrawableVariation(ped, 3)
  local model = GetEntityModel(ped)
  local retval = true
  if model == `mp_m_freemode_01` then
    if Config.MaleNoHandshoes[armIndex] ~= nil and Config.MaleNoHandshoes[armIndex] then
      retval = false
    end
  else
    if Config.FemaleNoHandshoes[armIndex] ~= nil and Config.FemaleNoHandshoes[armIndex] then
      retval = false
    end
  end
  return retval
end

local function getCamID(k)
  local camID = 0
  if k <= 6 then
    camID = 31
  elseif k == 7 or k >= 18 and k <= 20 then
    camID = 32
  elseif k >= 12 and k <= 17 then
    camID = 33
  elseif k >= 8 and k <= 11 then
    camID = 34
  elseif k >= 21 and k <= 26 then
    camID = 35
  elseif k >= 27 and k <= 32 then
    camID = 36
  end
  return camID
end

local function alertsCD(alertType)
  local data = exports['cd_dispatch']:GetPlayerInfo()
  if alertType == 'robbery' then
    TriggerServerEvent('cd_dispatch:AddNotification', {
      job_table = {'police', }, 
      coords = data.coords,
      title = '10-65 - Jewelery Store Robbery',
      message = 'A '..data.sex..' robbing a Vangelico\'s at '..data.street, 
      flash = 0,
      unique_id = data.unique_id,
      sound = 1,
      blip = {
        sprite = 586, 
        scale = 1.2, 
        colour = 3,
        flashes = true, 
        text = '999 - Jewelery Store Robbery',
        time = 5,
        radius = 0
      }
    })
  elseif alertType == 'suspicous' then
    TriggerServerEvent('cd_dispatch:AddNotification', {
      job_table = {'police', }, 
      coords = data.coords,
      title = '10-67 - Suspicious Activity',
      message = 'Someone has reported a '..data.sex.. ' at '..data.street , 
      flash = 0,
      unique_id = data.unique_id,
      sound = 1,
      blip = {
        sprite = 586, 
        scale = 1.2, 
        colour = 3,
        flashes = true, 
        text = '999 - Suspicious Activity',
        time = 5,
        radius = 0
      }
    })
  elseif alertType == 'explosion' then
    TriggerServerEvent('cd_dispatch:AddNotification', {
      job_table = {'police', }, 
      coords = data.coords,
      title = '10-80 - Explosion',
      message = 'An explosion has been reported at '..data.street, 
      flash = 0,
      unique_id = data.unique_id,
      sound = 1,
      blip = {
        sprite = 586, 
        scale = 1.2, 
        colour = 3,
        flashes = true, 
        text = '999 - Jewelery Store Robbery',
        time = 5,
        radius = 5
      }
    })
  end
end

local function checkSkill(hack)
  local retval = false
  local skill = exports[Config.Skills.system]:GetCurrentSkill(Config.Skills[hack].skill)
  local currXP = skill['Current']
  local reqXP = Config.Skills[hack]['Limits'].xp
  if currXP >= reqXP then
    retval = true
  end
  return retval
end

local function addSkillToPlayer(hack)
  local reward = Config.Skills[hack]['Rewards'].xp
  local multi = Config.Skills[hack]['Rewards'].multi
  local skill = exports[Config.Skills.system]:GetCurrentSkill(Config.Skills[hack].skill)
  local currXP = skill['Current']
  if currXP <= 0 then currXP = 1 end
  local xp = math.floor(reward * multi * (currXP * 0.001))
  if xp < reward then xp = reward end
  exports[Config.Skills.system]:UpdateSkill(Config.Skills[hack].skill, xp)
end

---@param location string
---@param index integer
---@param state boolean
local function set_case_state(location, index, state)
  if not JEWELLERY_CASES[location][index] then return end
  local case = JEWELLERY_CASES[location][index]
  local coords = case.coords
  local start_prop = case.start_prop
  local end_prop = case.end_prop
  if not state then
    RemoveModelSwap(coords.x, coords.y, coords.z, 0.1, start_prop, end_prop, true)
  else
    CreateModelSwap(coords.x, coords.y, coords.z, 0.1, start_prop, end_prop, true)
    RecordBrokenGlass(coords.x, coords.y, coords.z, 0.75)
  end
end

---@param cases {[string]: {coords: vector3, busy: boolean, open: boolean}[]}
local function set_cases(cases)
  ClearAllBrokenGlass()
  for location, data in pairs(cases) do
    for i = 1, #data do
      local case = data[i]
      local open = case.open
      if not open then
        set_case_state(location, i, false)
      else
        set_case_state(location, i, true)
      end
    end
  end
end

---@param resource string?
local function init_script(resource)
  if resource and type(resource) == 'string' and resource ~= RES_NAME then return end
  isLoggedIn = LocalPlayer.state.isLoggedIn or IsPlayerPlaying(PlayerId())
  bridge.callback.trigger('jewellery:server:GetCaseStates', 1000, set_cases)
end

---@param resource string?
local function deinit_script(resource)
  if resource and type(resource) == 'string' and resource ~= RES_NAME then return end
  RemoveAnimDict('missheist_jewel')
  RemoveAnimDict('anim@heists@ornate_bank@thermal_charge')
  RemoveAnimDict('amb@world_human_seat_wall_tablet@female@base')
  RemoveNamedPtfxAsset('scr_jewelheist')
  RemoveNamedPtfxAsset('scr_ornate_heist')
  StopAlarm('JEWEL_STORE_HEIST_ALARMS', true)
  bridge.target.removemodel(start_case_models)
  for i = 1, #Zones do
    bridge.target.removezone(Zones[i])
  end
  isLoggedIn = false
end

-------------------------------- HANDLERS --------------------------------

if bridge.core.getname() == 'qbx_core' then
  AddEventHandler(bridge.core.getevent('load'), init_script)
else
  RegisterNetEvent(bridge.core.getevent('load'), init_script)
end
AddEventHandler('onResourceStart', init_script)
AddEventHandler('onResourceStop', deinit_script)

RegisterNetEvent('jewellery:client:SetCaseState', set_case_state)

-- AddEventHandler(bridge.core.getevent('load'), function()
-- 	bridge.callback.trigger('don-jewellery:server:GetJewelleryState', false, function(result)
-- 		Config.Vitrines = result.Locations
--     Config.Stores = result.Hacks
-- 	end)
--   local blip = GetFirstBlipInfoId(617)
--   if not DoesBlipExist(blip) then
--     createBlips()
--   end
-- end)

AddEventHandler(bridge.core.getevent('unload'), function()
  for i = 1, #Config.Vitrines do
    if Config.Vitrines[i].isBusy then
      TriggerServerEvent('don-jewellery:server:SetVitrineState', false, i)
    end
  end
  removeBlips()
end)

-- AddEventHandler('onResourceStart', function(resource)
--   if resource ~= GetCurrentResourceName() then return end
--   for i = 1, #Config.Vitrines do
--     print('tellin server to set state', i)
--     if Config.Vitrines[i].isBusy then
--       TriggerServerEvent('don-jewellery:server:SetVitrineState', false, i)
--     end
--   end
--   TriggerServerEvent('don-jewellery:server:StoreHit', 'all', false)
--   createBlips()
-- end)

-- AddEventHandler('onResourceStop', function(resource)
--   if resource ~= GetCurrentResourceName() then return end
--   for i = 1, #Config.Vitrines do
--     if Config.Vitrines[i].isBusy then
--       TriggerServerEvent('don-jewellery:server:SetVitrineState', false, i)
--     end
--   end
--   TriggerServerEvent('don-jewellery:server:StoreHit', 'all', false)
--   removeBlips()
-- end)

AddEventHandler('don-jewellery:client:SmashCase', function(case)
  bridge.callback.trigger('don-jewellery:server:GetCops', false, function(cops)
    if not checkTime(Config.VangelicoHours.range.open, Config.VangelicoHours.range.close) then
      if not Config.Vitrines[case].isOpened then
        if Config.Skills.enabled then
          if not checkSkill('Vitrine') then
            bridge.notify.text(Lang:t('error.skill_fail', {value = Config.Skills['Vitrine'].skill}), 'error')
            return
          end
        end
        if cops >= Config.RequiredCops then
          if isStoreHit(case, false) or isStoreHacked() then
            local animDict = 'missheist_jewel'
            local animName = 'smash_case'
            local ped = PlayerPedId()
            local plyCoords = GetOffsetFromEntityInWorldCoords(ped, 0, 0.6, 0)
            local pedWeapon = GetSelectedPedWeapon(ped)
            if randomNum(1, 100) <= 80 and not isWearingHandshoes() then
              TriggerServerEvent('evidence:server:CreateFingerDrop', plyCoords)
            elseif randomNum(1, 100) <= 5 and isWearingHandshoes() then
              TriggerServerEvent('evidence:server:CreateFingerDrop', plyCoords)
              bridge.notify.text(Lang:t('error.fingerprints'), 'error')
            end
            smashing = true
            if Config.Skills.enabled then addSkillToPlayer('Vitrine') end
            loadAnimDict(animDict)
            TriggerServerEvent('don-jewellery:server:SetVitrineState', 'isBusy', true, case)
            
            if lib.progressBar({
              duration = Config.WhitelistedWeapons[pedWeapon].timeOut,
              label = Lang:t('info.smashing_progress'),
              useWhileDead = false,
              canCancel = true,
              disable = {
                move = true,
                car = true,
                combat = true,
              },
            }) then
              TriggerServerEvent('don-jewellery:server:VitrineReward', case)
              TriggerServerEvent('don-jewellery:server:SetTimeout', case)
              if not secondAlarm and not isStoreHacked() then 
                if Config.Dispatch == 'qb' then
                  TriggerServerEvent('police:server:policeAlert', 'Robbery in progress')
                elseif Config.Dispatch == 'ps' then
                  exports['ps-dispatch']:VangelicoRobbery(getCamID(case))
                elseif Config.Dispatch == 'cd' then
                  alertsCD('robbery')
                end
                secondAlarm = true
                firstAlarm = false
              end
              smashing = false
              TaskPlayAnim(ped, animDict, 'exit', 3.0, 3.0, -1, 2, 0, 0, 0, 0)
            else
              TriggerServerEvent('don-jewellery:server:SetVitrineState', 'isBusy', false, case)
              smashing = false
              TaskPlayAnim(ped, animDict, 'exit', 3.0, 3.0, -1, 2, 0, 0, 0, 0)
            end

            CreateThread(function()
              while smashing do
                loadAnimDict(animDict)
                TaskPlayAnim(ped, animDict, animName, 8.0, 8.0, -1, 31, 0.0, false, false, false)
                Wait(500)
                TriggerServerEvent('InteractSound_SV:PlayOnSource', 'breaking_vitrine_glass', 0.25)
                loadPtfx('scr_jewelheist')
                StartParticleFxLoopedAtCoord('scr_jewel_cab_smash', plyCoords.x, plyCoords.y, plyCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                Wait(5500)
              end
            end)
          else
            --bridge.notify.text(Lang:t('error.security_active'), 'error')
          end
        else
          bridge.notify.text(Lang:t('error.minimum_police', {value = Config.RequiredCops}), 'error')
        end
      else
        bridge.notify.text(Lang:t('error.vitrine_hit'), 'error')
      end
    else
      bridge.notify.text(Lang:t('error.stores_open'), 'error')
    end
  end)
end)

AddEventHandler('don-jewellery:client:Thermite', function(store)
  local AlertChance = randomNum(1, 100)
  if checkTime(Config.VangelicoHours.alertmorn.start, Config.VangelicoHours.alertmorn.fin) or checkTime(Config.VangelicoHours.alertnight.start, Config.VangelicoHours.alertnight.fin) then
    AlertChance = randomNum(1, 50)
  else
    AlertChance = AlertChance
  end

  if AlertChance <= 10 then
    if Config.Dispatch == 'qb' then
      TriggerServerEvent('police:server:policeAlert', 'Suspicious Activity')
    elseif Config.Dispatch == 'ps' then
      exports['ps-dispatch']:SuspiciousActivity()
    elseif Config.Dispatch == 'cd' then
      alertsCD('suspicious')
    end
    firstAlarm = true
  end

  bridge.callback.trigger('don-jewellery:server:GetCops', false, function(cops)
    if not checkTime(Config.VangelicoHours.range.open, Config.VangelicoHours.range.close) then
      if Config.Skills.enabled then 
        if not checkSkill('Thermite') then
          bridge.notify.text(Lang:t('error.skill_fail', {value = Config.Skills['Thermite'].skill}), 'error')
          return
        end
      end
      if cops >= Config.RequiredCops then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local printChance = randomNum(1, 100)
        local dist = #(coords - Config.Stores[store]['Thermite'].coords)
        if dist <= 1.5 then
          if exports.ox_inventory:Search('count', Config.DoorItem) >= 1 then
            if printChance <= 80 and not isWearingHandshoes() then
              TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
            elseif printChance <= 5 and isWearingHandshoes() then
              TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
              bridge.notify.text(Lang:t('error.fingerprints'), 'error')
            end
            SetEntityHeading(ped, Config.Stores[store]['Thermite'].h)
            local success = exports['glitch-minigames']:StartMemoryGame(Config.ThermiteSettings.gridsize, Config.ThermiteSettings.squareCount, Config.ThermiteSettings.rounds, Config.ThermiteSettings.showtime, Config.ThermiteSettings.incorrectBlocks)
            if success then
                TriggerServerEvent('don-jewellery:server:StoreHit', store, true)    
                bridge.notify.text(Lang:t('success.thermite'), 'success')
                local loc = Config.Stores[store]['Thermite'].anim
                local rot = GetEntityRotation(ped)
                local bagscene = NetworkCreateSynchronisedScene(loc.x, loc.y, loc.z, rot.x, rot.y, rot.z, 2, false, false, 1065353216, 0, 1.3)
                local bag = CreateObject(`hei_p_m_bag_var22_arm_s`, loc.x, loc.y, loc.z,  true,  true, false)
                SetEntityCollision(bag, false, true)
                NetworkAddPedToSynchronisedScene(ped, bagscene, 'anim@heists@ornate_bank@thermal_charge', 'thermal_charge', 1.5, -4.0, 1, 16, 1148846080, 0)
                NetworkAddEntityToSynchronisedScene(bag, bagscene, 'anim@heists@ornate_bank@thermal_charge', 'bag_thermal_charge', 4.0, -8.0, 1)
                NetworkStartSynchronisedScene(bagscene)
                Wait(1500)
                coords = GetEntityCoords(ped)
                local thermal_charge = CreateObject(`hei_prop_heist_thermite`, coords.x, coords.y, coords.z + 0.2,  true,  true, true)
            
                SetEntityCollision(thermal_charge, false, true)
                AttachEntityToEntity(thermal_charge, ped, GetPedBoneIndex(ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)
                Wait(4000)
                TriggerServerEvent('don-jewellery:server:RemoveDoorItem')
            
                DetachEntity(thermal_charge, 1, 1)
                FreezeEntityPosition(thermal_charge, true)
                Wait(100)
                DeleteObject(bag)
                ClearPedTasks(ped)
            
                Wait(100)
                if Config.Skills.enabled then addSkillToPlayer('Thermite') end
                loadPtfx('scr_ornate_heist')
                local termcoords = GetEntityCoords(thermal_charge)
                local effect = StartParticleFxLoopedAtCoord('scr_heist_ornate_thermal_burn', termcoords.x, termcoords.y + 1.0, termcoords.z, 0, 0, 0, 0x3F800000, 0, 0, 0, 0)
                Wait(3000)
                StopParticleFxLooped(effect, 0)
                DeleteObject(thermal_charge)
                TriggerEvent('don-jewellery:client:HackSuccess', store)
                if not firstAlarm and AlertChance <= 25 then
                  if Config.Dispatch == 'qb' then
                    TriggerServerEvent('police:server:policeAlert', 'Explosion Reported')
                  elseif Config.Dispatch == 'ps' then
                    exports["ps-dispatch"]:Explosion()
                  elseif Config.Dispatch == 'cd' then
                    alertsCD('explosion')
                  end
                  firstAlarm = true
                end
            else
              bridge.notify.text(Lang:t('error.fail_therm'), 'error')
            end
          else
            bridge.notify.text(Lang:t('error.wrong_item'), 'error')
          end
        else
          bridge.notify.text(Lang:t('error.too_far'), 'error')
        end
      else
        bridge.notify.text(Lang:t('error.minimum_police', {value = Config.RequiredCops}), 'error')
      end
    else
      bridge.notify.text(Lang:t('error.stores_open'), 'error')
    end
  end)
end)

AddEventHandler('don-jewellery:client:HackSecurity', function()
  bridge.callback.trigger('don-jewellery:server:GetCops', false, function(cops)
    if not checkTime(Config.VangelicoHours.range.open, Config.VangelicoHours.range.close) then
      if Config.Skills.enabled then
        if not checkSkill('Hack') then
          bridge.notify.text(Lang:t('error.skill_fail', {value = Config.Skills['Hack'].skill}), 'error')
          return
        end
      end
      if cops >= Config.RequiredCops then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - Config.Stores[1]['Hack'].coords)
        if dist <= 1.5 then
          if exports.ox_inventory:Search('count', Config.HackItem) >= 1 then
            local animDict = 'amb@world_human_seat_wall_tablet@female@base'
            local anim = 'base'
            local hacking = true
            local tab = CreateObject(`prop_cs_tablet`, 0, 0, 0, true, true, true)
            AttachEntityToEntity(tab, ped, GetPedBoneIndex(ped, 57005), 0.17, 0.10, -0.13, 20.0, 180.0, 180.0, true, true, false, true, 1, true)
            bridge.notify.text(Lang:t('info.hacking_attempt'), 'primary', 2500)
            CreateThread(function()
              while hacking do
                Wait(0)
                loadAnimDict(animDict)
                if not IsEntityPlayingAnim(ped, animDict, anim, 3) then
                  TaskPlayAnim(ped, animDict, anim, 8.0, -8.0, -1, 50, 0, false, false, false)
                end
              end
            end)
            -- if randomNum(1, 100) <= 80 and not isWearingHandshoes() then
            --     TriggerServerEvent("evidence:server:CreateFingerDrop", targetPosition)
            -- elseif randomNum(1, 100) <= 5 and isWearingHandshoes() then
            --     TriggerServerEvent("evidence:server:CreateFingerDrop", targetPosition)
            -- end
            Wait(2500)
            local success = exports['glitch-minigames']:StartPipePressureGame(Config.VarHackSettings.gridsize, Config.VarHackSettings.time)
            if success then
                if Config.Skills.enabled then addSkillToPlayer('Hack') end
                hacking = false
                TriggerServerEvent('don-jewellery:server:StoreHit', 'all', true)
                Wait(250)
                StopAnimTask(ped, animDict, anim, 8.0)
                DeleteEntity(tab)
                TriggerEvent('don-jewellery:client:HackSuccess')
            else
              hacking = false
              bridge.notify.text(Lang:t('error.fail_hack'), 'error')
              StopAnimTask(ped, animDict, anim, 8.0)
              DeleteEntity(tab)
              FreezeEntityPosition(ped, false)
            end
          else
            bridge.notify.text(Lang:t('error.wrong_item'), 'error')
          end
        else
          bridge.notify.text(Lang:t('error.too_far'), 'error')
        end
      else
        bridge.notify.text(Lang:t('error.minimum_police', {value = Config.RequiredCops}), 'error')
      end
    else
      bridge.notify.text(Lang:t('error.stores_open'), 'error')
    end
  end)
end)

AddEventHandler('don-jewellery:client:HackSuccess', function(store)
  if isStoreHit(store, true) or isStoreHacked() then
    if isStoreHit(store, true)  and not isStoreHacked() then
      if not Config.OneStore then
        bridge.notify.text(Lang:t('success.store_hit_threestore'), 'success')
        if Config.AutoLock then
          TriggerServerEvent('don-jewellery:server:ToggleDoorlocks', store, false, false)
          locked = false
          Wait(Config.Cooldown)
        end
      else
        local warningTimer = 1 * (60 * 2000)
        local warningTime = warningTimer / (60 * 2000)
        local cooldownTime = Config.Cooldown / (60 * 2000)
        bridge.notify.text(Lang:t('success.store_hit_onestore', {value = math.floor(cooldownTime)}), 'success')
        if Config.AutoLock then TriggerServerEvent('don-jewellery:server:ToggleDoorlocks', store, false, false) end
        locked = false
        Wait(Config.Cooldown - warningTimer)
        bridge.notify.text(Lang:t('info.one_store_warning', {value = math.floor(warningTime)}), 'primary')
        Wait(warningTimer)
      end
      if Config.AutoLock and not checkTime(Config.VangelicoHours.range.open, Config.VangelicoHours.range.close) then
        TriggerServerEvent('don-jewellery:server:ToggleDoorlocks', store, true, false)
        locked = true
      end
      TriggerServerEvent('don-jewellery:server:StoreHit', store, false)
    else
      if not Config.OneStore then 
        bridge.notify.text(Lang:t('success.hacked_threestore'), 'success')
        if Config.AutoLock then TriggerServerEvent('don-jewellery:server:ToggleDoorlocks', nil, false, true) end
        locked = false
        Wait(Config.Cooldown)
        if Config.AutoLock and not checkTime(Config.VangelicoHours.range.open, Config.VangelicoHours.range.close) then
          locked = true
          TriggerServerEvent('don-jewellery:server:ToggleDoorlocks', nil, true, true)
        end
        TriggerServerEvent('don-jewellery:server:StoreHit', 'all', false)
      else
        bridge.notify.text(Lang:t('success.hacked_onestore'), 'success')
      end
    end
    firstAlarm = false
    secondAlarm = false
  end
end)

-------------------------------- EVENTS --------------------------------

RegisterNetEvent('don-jewellery:client:SetVitrineState', function(stateType, state, k)
  Config.Vitrines[k][stateType] = state
  if stateType == 'isBusy' and state == true then
    CreateModelSwap(Config.Vitrines[k].coords, 0.1, Config.Vitrines[k].propStart, Config.Vitrines[k].propEnd, false)
  end

  if stateType == 'isOpened' and state == false then
    RemoveModelSwap(Config.Vitrines[k].coords, 0.1, Config.Vitrines[k].propStart, Config.Vitrines[k].propEnd, false)
  end
end)

RegisterNetEvent('don-jewellery:client:StoreHit', function(storeIndex, isHit)
  if not storeIndex or not isHit then return end
  if storeIndex == 'all' then Config.Stores[1].hacked = isHit end
  for k, _ in pairs(Config.Stores) do
    if storeIndex == 'all' then
      Config.Stores[k].hit = isHit
    else
      if k == storeIndex then
        Config.Stores[storeIndex].hit = isHit
      end
    end
  end
end)

---@param coords vector3
---@return string?, integer?, integer?
local function get_closest_case(coords)
  local closest_ent
  local closest_coord
  local dist = math.huge
  for i = 1, #start_case_models do
    local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 1.0, start_case_models[i], false, true, false)
    if entity ~= 0 then
      local fnd_coords = GetEntityCoords(entity)
      local fnd_dist = #(coords - fnd_coords)

      if fnd_dist < dist then
        closest_coord = fnd_coords
        closest_ent = entity
        dist = fnd_dist
      end
    end
  end
  for location, cases in pairs(JEWELLERY_CASES) do
    for i = 1, #cases do
      local case = cases[i]
      if #(case.coords - closest_coord) <= 1.0 then return location, i, closest_ent end
    end
  end
end

local function smash_case(location, case, entity)
  if not location or not case or not entity or not JEWELLERY_CASES[location][case] then -- exploit detected?
    return
  end
  local dict = 'missheist_jewel'
  if not glib.stream.animdict(dict) then return end
  TriggerServerEvent('jewellery:server:SetCaseState', location, case, 'busy', true)
  local anim = 'smash_case'
  local ped = PlayerPedId()
  local case_data = JEWELLERY_CASES[location][case]
  local coords = case_data.coords
  local offset = GetAnimInitialOffsetPosition(dict, anim, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 2)
  local heading = case_data.heading
  offset = GetOffsetFromCoordAndHeadingInWorldCoords(offset.x, offset.y, offset.z, heading, 0.0, -0.25, 0.0)
  local duration = GetAnimDuration(dict, anim)
  local sequence = OpenSequenceTask()
  ---@diagnostic disable-next-line: param-type-mismatch
  TaskFollowNavMeshToCoord(0, offset.x, offset.y, offset.z, 1.0, 2500, 0.1, 512, heading)
  TaskPlayAnimAdvanced(0, dict, anim, offset.x, offset.y, offset.z, 0.0, 0.0, heading, 1.0, 1.0, duration, 1090527232 --[[+ 4194304 Adds Collision on Impact]], 0.0)
  CloseSequenceTask(sequence)
  TaskPerformSequence(ped, sequence)
  ClearSequenceTask(sequence)
  CreateThread(function()
    local ptfx = 'scr_jewelheist'
    while GetEntityAnimCurrentTime(ped, dict, anim) <= 0.04 do
      Wait(0)
    end
    TriggerServerEvent('jewellery:server:SetCaseState', location, case, 'open', true)
    ---@diagnostic disable-next-line: param-type-mismatch
    glib.audio.playsoundatcoords(true, nil, 'Glass_Smash', offset, 0, 0, false)
    if not glib.stream.ptfx(ptfx) then return end
    UseParticleFxAsset(ptfx)
    StartParticleFxNonLoopedOnEntity('scr_jewel_cab_smash', GetCurrentPedWeaponEntityIndex(ped), 0.0, 0.0, -0.1, 0.0, 0.0, 0.0, 1.0, false, false, false)
    bridge.callback.trigger('jewellery:server:IsStoreVulnerable', false, function(hacked, hit)
      if not hacked and not GlobalState['jewellery:alarm'] then
        -- Add time if statement to do alarms and dispatch
        if location == 'main' then
          PrepareAlarm('JEWEL_STORE_HEIST_ALARMS')
          StartAlarm('JEWEL_STORE_HEIST_ALARMS', false)
          TriggerServerEvent('jewellery:server:VangelicoAlarm', location, true)
        end
        local chance = math.random(100)
        if hit and chance >= 70 then return end
        -- Alert Police Dispatch
      end
    end, location)
    RemoveAnimDict(dict)
    RemoveNamedPtfxAsset(ptfx)
  end)
end

local function use_thermite(location, coords, heading)
  local chance = math.random(100)
  if chance <= 10 then
    -- Alert Police Dispatch: Suspcious Activity
  end

  local dict = 'anim@heists@ornate_bank@thermal_charge'
  if not glib.stream.animdict(dict) then return end
  local ped_anim = 'thermal_charge'
  local bag_anim = 'bag_thermal_charge'
  local ped = PlayerPedId()
  local thermite = CreateObject(`hei_prop_heist_thermite`, coords.x, coords.y, coords.z + 0.2,  true,  true, false)
  SetEntityCollision(thermite, false, true)
  AttachEntityToEntity(thermite, ped, GetPedBoneIndex(ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)

  local scene = glib.netscene({
    scene = {coords = coords, rotation = vector3(0.0, 0.0, heading), hold = true},
    peds = {
      {
        dict = dict,
        anim = ped_anim,
        entity = ped,
        -- blend_in = 1.5,
        -- blend_out = -4.0,
        scene_flags = 19480,
        ragdoll_flags = 16
      }
    },
    objs = {
      {
        dict = dict,
        anim = bag_anim,
        model = `hei_p_m_bag_var22_arm_s`,
        -- blend_in = 4.0,
        -- blend_out = -8.0,
        scene_flags = 1
      }
    }
  })
  local ptfx = 'scr_ornate_heist'
  local ptfx_handle = 0
  local abort = false
  scene:start(function(phase)
    if phase >= 0.4 and IsEntityAttached(thermite) then
      DetachEntity(thermite, true, true)
      FreezeEntityPosition(thermite, true)
      if not exports['glitch-minigames']:StartMemoryGame(
        Config.ThermiteSettings.gridsize,
        Config.ThermiteSettings.squareCount,
        Config.ThermiteSettings.rounds,
        Config.ThermiteSettings.showtime,
        Config.ThermiteSettings.incorrectBlocks
      ) then scene:clear(false, true); abort = true return end
      Wait(500)
      if not glib.stream.ptfx(ptfx) then return end
      UseParticleFxAsset(ptfx)
      ptfx_handle = StartParticleFxLoopedAtCoord('scr_heist_ornate_thermal_burn', coords.x, coords.y + 1.0, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    end
  end)
  if not abort then
    bridge.callback.trigger('jewellery:server:IsStoreVulnerable', false, function(hacked, hit)
      if not hacked then
        -- Add time if statement to do alarms and dispatch
        chance = math.random(100)
        if chance < 85 then
          -- Alert Police Dispatch: Explosion
        end
      end
      if hit then return end
      -- Set Store as Hit
    end, location)
    Wait(3000)
    scene:clear(false, true)
    StopParticleFxLooped(ptfx_handle, false)
    RemoveNamedPtfxAsset(ptfx)
  end
  DeleteObject(thermite)
  RemoveAnimDict(dict)
end

local function hack_security(location)
  local dict = 'amb@world_human_seat_wall_tablet@female@base'
  if not glib.stream.animdict(dict) then return end
  local ped = PlayerPedId()
  local tablet = CreateObject(`prop_cs_tablet`, 0, 0, 0, true, true, false)

  AttachEntityToEntity(tablet, ped, GetPedBoneIndex(ped, 57005), 0.17, 0.10, -0.13, 20.0, 180.0, 180.0, true, true, false, true, 1, true)
  TaskPlayAnim(ped, dict, 'base', 8.0, -8.0, -1, 50, 1.0, false, false, false)
  Wait(1000)

  if not exports['glitch-minigames']:StartPipePressureGame(Config.VarHackSettings.gridsize, Config.VarHackSettings.time) then
    bridge.notify.text(Lang:t('error.fail_hack'), 'error')
  else
    bridge.callback.trigger('jewellery:server:IsStoreVulnerable', false, function(hacked, hit)
      if hacked then return end
      -- Set Store as Hacked
    end, location)
  end
  StopAnimTask(ped, dict, 'base', 8.0)
  DeleteObject(tablet)
  RemoveAnimDict(dict)
end

-------------------------------- TARGET --------------------------------

bridge.target.addmodel(start_case_models, {
  {
    name = 'jewel_heist',
    icon = 'fa fa-hand',
    label = Lang:t('general.target_label'),
    item = {'weapon_assaultrifle'},
    canInteract = function()
      return isLoggedIn and not bridge.callback.await('jewellery:server:IsCaseBusy', false)
    end,
    onSelect = function()
      local location, case, entity = get_closest_case(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.25, 0.0))
      if not bridge.callback.await('jewellery:server:GetPolicePresence', false, location) then return end

      smash_case(location, case, entity)
    end,
    distance = 1.0
  }
})

for k, v in pairs(LOCATIONS) do
  local thermite = v.thermite
  Zones[#Zones + 1] = bridge.target.addboxzone({
    center = thermite.coords,
    size = thermite.size,
    heading = thermite.heading,
    debug = false
  }, {
    {
      name = 'jewelthermite'..k,
      icon = 'fas fa-bug',
      label = 'Blow Fuse Box',
      item = 'thermite',
      canInteract = function()
        local _, hit = bridge.callback.await('jewellery:server:IsStoreVulnerable', false, k)
        return isLoggedIn and not hit
      end,
      onSelect = function()
        if not bridge.callback.await('jewellery:server:GetPolicePresence', false, k) then return end

        use_thermite(k, thermite.coords, thermite.heading)
      end,
      distance = 1.0
    }
  })
  local hack = v.hack
  if hack then
    Zones[#Zones + 1] = bridge.target.addboxzone({
      center = hack.coords,
      size = hack.size,
      heading = hack.heading,
      debug = false
    }, {
      {
        name = 'jewelpc1',
        icon = 'fas fa-bug',
        label = 'Hack Security System',
        item = 'phone',
        canInteract = function()
          local hacked = bridge.callback.await('jewellery:server:IsStoreVulnerable', false, k)
          return isLoggedIn and not hacked
        end,
        onSelect = function()
          if not bridge.callback.await('jewellery:server:GetPolicePresence', false, k) then return end

          hack_security(k)
        end,
        distance = 1.0,
      }
    })
  end
end

-------------------------------- THREADS --------------------------------

CreateThread(function()
  local loopDone = false
  while Config.AutoLock do
    Wait(1000)
    if LocalPlayer.state.isLoggedIn then
      if not checkTime(Config.VangelicoHours.range.open, Config.VangelicoHours.range.close) then
        if (not isStoreHit(nil, false) and not isStoreHacked()) and not locked then
          Wait(1000)
          TriggerServerEvent('don-jewellery:server:ToggleDoorlocks', nil, true, true)
          locked = true
          loopDone = false
        end
      else
        if not loopDone then
          Wait(1000)
          TriggerServerEvent('don-jewellery:server:ToggleDoorlocks', nil, false, true)
          loopDone = true
        end
      end
    end
  end
end)
