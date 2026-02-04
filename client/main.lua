local RES_NAME <const> = bridge._RESOURCE
local JEWELLERY_CASES <const> = glib.require(RES_NAME..'.shared.jewellery_cases') --[[@module 'gr_jewellery.shared.jewellery_cases']]
local LOCATIONS <const> = glib.require(RES_NAME..'.shared.store_locations') --[[@module 'gr_jewellery.shared.store_locations']]
local CONFIG <const> = glib.require(RES_NAME..'.client.config') --[[@module 'gr_jewellery.client.config']]
local THERMITE <const> = CONFIG.minigames.thermite
local HACK <const> = CONFIG.minigames.hack
local WEAPONS <const> = CONFIG.weapons
local start_case_models = {
  `des_jewel_cab_start`,
  `des_jewel_cab2_start`,
  `des_jewel_cab3_start`,
  `des_jewel_cab4_start`
}
local Zones = {}
local isLoggedIn = false
local translate = glib.locale.translate

--------------------- FUNCTIONS ---------------------

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

-- Legacy Code if I want to add this functionality back in future 😅
-- local function getCamID(k)
--   local camID = 0
--   if k <= 6 then
--     camID = 31
--   elseif k == 7 or k >= 18 and k <= 20 then
--     camID = 32
--   elseif k >= 12 and k <= 17 then
--     camID = 33
--   elseif k >= 8 and k <= 11 then
--     camID = 34
--   elseif k >= 21 and k <= 26 then
--     camID = 35
--   elseif k >= 27 and k <= 32 then
--     camID = 36
--   end
--   return camID
-- end

-- local function checkSkill(hack)
--   local retval = false
--   local skill = exports[Config.Skills.system]:GetCurrentSkill(Config.Skills[hack].skill)
--   local currXP = skill['Current']
--   local reqXP = Config.Skills[hack]['Limits'].xp
--   if currXP >= reqXP then
--     retval = true
--   end
--   return retval
-- end

-- local function addSkillToPlayer(hack)
--   local reward = Config.Skills[hack]['Rewards'].xp
--   local multi = Config.Skills[hack]['Rewards'].multi
--   local skill = exports[Config.Skills.system]:GetCurrentSkill(Config.Skills[hack].skill)
--   local currXP = skill['Current']
--   if currXP <= 0 then currXP = 1 end
--   local xp = math.floor(reward * multi * (currXP * 0.001))
--   if xp < reward then xp = reward end
--   exports[Config.Skills.system]:UpdateSkill(Config.Skills[hack].skill, xp)
-- end

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
    CreateModelSwap(coords.x, coords.y, coords.z, 0.1, end_prop, start_prop, false)
    RemoveModelSwap(coords.x, coords.y, coords.z, 0.1, start_prop, end_prop, false)
  else
    CreateModelSwap(coords.x, coords.y, coords.z, 0.1, start_prop, end_prop, false)
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
  if GlobalState['jewellery:alarm'] then
    PrepareAlarm('JEWEL_STORE_HEIST_ALARMS')
    repeat
      Wait(0)
    until PrepareAlarm('JEWEL_STORE_HEIST_ALARMS')
    StartAlarm('JEWEL_STORE_HEIST_ALARMS', true)
  end
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

---@param ped integer?
---@return boolean
local function is_brandishing_weapon(ped)
  ped = ped or PlayerPedId()
  local weapon = GetSelectedPedWeapon(ped)
  for i = 1, #WEAPONS do
    if weapon == joaat(WEAPONS[i]) then
      return true
    end
  end
  return false
end

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

---@param location string?
---@param case integer?
---@param entity integer?
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
    bridge.callback.trigger('jewellery:server:IsStoreVulnerable', 100, function(hacked, hit)
      if not hacked and not GlobalState['jewellery:alarm'] then
        local chance = math.random(100)
        if chance < (not bridge.callback.await('jewellery:server:IsStoreOpen') and 70 or 100) then
          -- Alert Police Dispatch
          if location == 'main' then
            TriggerServerEvent('jewellery:server:VangelicoAlarm', location, true)
          end
          -- if Config.Dispatch == 'qb' then
          --   TriggerServerEvent('police:server:policeAlert', 'Robbery in progress')
          -- elseif Config.Dispatch == 'ps' then
          --   exports['ps-dispatch']:VangelicoRobbery(getCamID(case))
          -- elseif Config.Dispatch == 'cd' then
          --   alertsCD('robbery')
          -- end
        end
      end
    end, location)
    RemoveAnimDict(dict)
    RemoveNamedPtfxAsset(ptfx)
    if not core.isplayergloved() then
      TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
    end
  end)
end

---@param location string
---@param coords vector3
---@param heading number
local function use_thermite(location, coords, heading)
  local chance = math.random(100)
  if chance <= 10 then
    -- Alert Police Dispatch: Suspcious Activity
    -- if Config.Dispatch == 'qb' then
    --   TriggerServerEvent('police:server:policeAlert', 'Suspicious Activity')
    -- elseif Config.Dispatch == 'ps' then
    --   exports['ps-dispatch']:SuspiciousActivity()
    -- elseif Config.Dispatch == 'cd' then
    --   alertsCD('suspicious')
    -- end
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
        scene_flags = 19480,
        ragdoll_flags = 16
      }
    },
    objs = {
      {
        dict = dict,
        anim = bag_anim,
        model = `hei_p_m_bag_var22_arm_s`,
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
        THERMITE.size,
        THERMITE.squares,
        THERMITE.rounds,
        THERMITE.time,
        THERMITE.attempts
      ) then
        Wait(500)
        scene:clear(false, true)
        abort = true
        bridge.notify.text(Lang:t('error.fail_therm'), 'error')
        return
      end
      Wait(500)
      if not glib.stream.ptfx(ptfx) then return end
      UseParticleFxAsset(ptfx)
      ptfx_handle = StartParticleFxLoopedAtCoord('scr_heist_ornate_thermal_burn', coords.x, coords.y + 1.0, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    end
  end)
  if not abort then
    bridge.notify.text(translate('success.thermite'), 'success')
    bridge.callback.trigger('jewellery:server:IsStoreVulnerable', false, function(hacked, hit)
      if not hacked then
        chance = math.random(100)
        if chance < (not bridge.callback.await('jewellery:server:IsStoreOpen') and 85 or 100) then
          -- Alert Police Dispatch: Explosion
          -- if Config.Dispatch == 'qb' then
          --   TriggerServerEvent('police:server:policeAlert', 'Explosion Reported')
          -- elseif Config.Dispatch == 'ps' then
          --   exports["ps-dispatch"]:Explosion()
          -- elseif Config.Dispatch == 'cd' then
          --   alertsCD('explosion')
          -- end
        end
      end
      if hit then return end
      TriggerServerEvent('jewellery:server:SetStoreState', location, 'hit', true)
    end, location)
    Wait(5000)
    scene:clear(false, true)
    StopParticleFxLooped(ptfx_handle, false)
    RemoveNamedPtfxAsset(ptfx)
  end
  DeleteObject(thermite)
  RemoveAnimDict(dict)
end

---@param location string
local function hack_security(location)
  local dict = 'amb@world_human_seat_wall_tablet@female@base'
  if not glib.stream.animdict(dict) then return end
  local ped = PlayerPedId()
  local tablet = CreateObject(`prop_cs_tablet`, 0, 0, 0, true, true, false)
  local leo = bridge.core.doesplayerhavegroup('leo')

  bridge.notify.text(translate('info.hacking_attempt'), 'primary', 2000)
  AttachEntityToEntity(tablet, ped, GetPedBoneIndex(ped, 57005), 0.17, 0.10, -0.13, 20.0, 180.0, 180.0, true, true, false, true, 1, true)
  TaskPlayAnim(ped, dict, 'base', 8.0, -8.0, -1, 50, 1.0, false, false, false)
  Wait(2000)

  if not leo and not exports['glitch-minigames']:StartPipePressureGame(HACK.size, HACK.time) then
    bridge.notify.text(translate('error.fail_hack'), 'error')
  else
    bridge.callback.trigger('jewellery:server:IsStoreVulnerable', false, function()
      if not leo then
        bridge.notify.text(translate('success.hacked'), 'success')
        TriggerServerEvent('jewellery:server:SetStoreState', location, 'hacked', true)
      end
      if GlobalState['jewellery:alarm'] then TriggerServerEvent('jewellery:server:VangelicoAlarm', location, false) end
    end, location)
  end
  StopAnimTask(ped, dict, 'base', 8.0)
  DeleteObject(tablet)
  RemoveAnimDict(dict)
end

--------------------- HANDLERS ---------------------

AddEventHandler('onResourceStart', init_script)
AddEventHandler('onResourceStop', deinit_script)
AddStateBagChangeHandler('jewellery:alarm', 'global', function(_, _, state)
  if state then
    PrepareAlarm('JEWEL_STORE_HEIST_ALARMS')
    repeat
      Wait(0)
    until PrepareAlarm('JEWEL_STORE_HEIST_ALARMS')
    StartAlarm('JEWEL_STORE_HEIST_ALARMS', false)
  else
    StopAlarm('JEWEL_STORE_HEIST_ALARMS', true)
  end
end)

--------------------- EVENTS ---------------------

if bridge.core.getname() == 'qbx_core' then
  AddEventHandler(bridge.core.getevent('load'), init_script)
else
  RegisterNetEvent(bridge.core.getevent('load'), init_script)
end

RegisterNetEvent(bridge.core.getevent('unload'), deinit_script)
RegisterNetEvent('jewellery:client:SetCaseState', set_case_state)

-------------------------------- TARGET --------------------------------

bridge.target.addmodel(start_case_models, {
  {
    name = 'jewel_heist',
    icon = 'fa fa-hand',
    label = translate('general.target_label'),
    item = WEAPONS,
    canInteract = function()
      return isLoggedIn and not bridge.callback.await('jewellery:server:IsCaseBusy', false) and is_brandishing_weapon()
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
      label = translate('general.thermite_label'),
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
        label = translate('general.hack_label'),
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
