local RES_NAME <const> = bridge._RESOURCE
local DEBUG <const> = bridge._DEBUG
local JEWELLERY_CASES <const> = glib.require(RES_NAME..'.shared.jewellery_cases') --[[@module 'gr_jewellery.shared.jewellery_cases']]
local LOCATIONS <const> = glib.require(RES_NAME..'.shared.store_locations') --[[@module 'gr_jewellery.shared.store_locations']]
local CONFIG <const> = glib.require(RES_NAME..'.client.config') --[[@module 'gr_jewellery.client.config']]
local THERMITE <const> = CONFIG.minigames.thermite
local HACK <const> = CONFIG.minigames.hack
local DISPATCH <const> = CONFIG.dispatch
local WEAPONS <const> = CONFIG.weapons
local start_case_models = {
  `des_jewel_cab_start`,
  `des_jewel_cab2_start`,
  `des_jewel_cab3_start`,
  `des_jewel_cab4_start`
}
local Alarms = {}
local Blips = {}
local isLoggedIn = false
local translate = glib.locale.translate
local unpack = table.unpack

--------------------- FUNCTIONS ---------------------

-- Worried if this can be exploited by a client triggering it with random location/index/state values.<br>
-- I have server checks in place for the important stuff like police dispatch and rewards so should be fine?<br>
-- Possibly move to statebags if issues arise.
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
    if start_prop and end_prop then
      CreateModelSwap(coords.x, coords.y, coords.z, 0.1, end_prop, start_prop, false)
      RemoveModelSwap(coords.x, coords.y, coords.z, 0.1, start_prop, end_prop, false)
    end
  else
    local ptfx = 'scr_jewelheist'
    if start_prop and end_prop then CreateModelSwap(coords.x, coords.y, coords.z, 0.1, start_prop, end_prop, false) end
    RecordBrokenGlass(coords.x, coords.y, coords.z, 1.0)
    ---@diagnostic disable-next-line: param-type-mismatch
    glib.audio.playsoundatcoords(true, nil, 'Glass_Smash', coords, 0, 0, false)
    if not glib.stream.ptfx(ptfx) then return end
    UseParticleFxAsset(ptfx)
    StartParticleFxNonLoopedAtCoord('scr_jewel_cab_smash', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
    RemoveNamedPtfxAsset(ptfx)
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

---@param location string
local function thermite_effect(location)
  if not LOCATIONS[location].thermite then return end
  local coords = LOCATIONS[location].thermite.coords
  local ptfx = 'scr_ornate_heist'
  local ptfx_handle = 0
  if not glib.stream.ptfx(ptfx) then return end
  UseParticleFxAsset(ptfx)
  ptfx_handle = StartParticleFxLoopedAtCoord('scr_heist_ornate_thermal_burn', coords.x, coords.y + 1.0, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
  Wait(5000)
  StopParticleFxLooped(ptfx_handle, false)
  RemoveNamedPtfxAsset(ptfx)
end

---@param location string
local function store_close_warning(location)
  if not LOCATIONS[location] then return end
  local id = LOCATIONS[location].interior_id
  if GetInteriorFromEntity(PlayerPedId()) ~= id then return end
  bridge.notify.text(translate('info.close_warning'), 'primary')
end

---@async
---@param location string
---@param index integer
local function draw_light(location, index)
  if not Alarms[location][index] then return end
  CreateThread(function()
    local config = LOCATIONS[location].alarms
    if not config then return end
    local coords = config.coords
    coords = type(coords) == 'table' and coords or {coords}
    ---@diagnostic disable-next-line: cast-local-type
    coords = coords[index]
    while Alarms[location][index] do
      Wait(500)
      DrawLightWithRangeAndShadow(coords.x, coords.y, coords.z - 0.85, 255, 0, 0, 5.0, 10.0, 1.0)
      if not Alarms or not Alarms[location] then break end
    end
  end)
end

---@param location string
local function play_jewel_alarm(location)
  local config = LOCATIONS[location].alarms
  if not config then return end
  local coords = config.coords
  local sound = config.sound
  local range = config.range
  coords = type(coords) == 'table' and coords or {coords}
  Alarms[location] = {}
  for i = 1, #coords do
    Alarms[location][i] = glib.audio.playsoundatcoords(true, sound.bank, sound.name, coords[i]--[[@as vector3]], sound.ref, range, false, true)
    SetTimeout(100, function() draw_light(location, i) end)
  end
  ReleaseNamedScriptAudioBank('ALARM_BELL_02')
end

---@param location string
local function stop_jewel_alarm(location)
  if not Alarms[location] then return end
  for i = 1, #Alarms[location] do
    glib.audio.stopsound(Alarms[location][i])
  end
  Alarms[location] = nil
end

---@param resource string?
local function deinit_script(resource)
  if resource and type(resource) == 'string' and resource ~= RES_NAME then return end
  RemoveAnimDict('missheist_jewel')
  RemoveAnimDict('anim@heists@ornate_bank@thermal_charge')
  RemoveAnimDict('amb@world_human_seat_wall_tablet@female@base')
  RemoveNamedPtfxAsset('scr_jewelheist')
  RemoveNamedPtfxAsset('scr_ornate_heist')
  ReleaseNamedScriptAudioBank('ALARM_BELL_02')
  bridge.target.removemodel(start_case_models)
  for location, config in pairs(LOCATIONS) do
    if Alarms[location] then stop_jewel_alarm(location) end
    if config.thermite then bridge.target.removezone('jewellery:thermite:'..location) end
    if config.hack then bridge.target.removezone('jewellery:hack:'..location) end
    if Blips[location] then exports.gr_blips:remove(Blips[location]) end
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
  local closest
  local entity
  local location
  local dist = math.huge
  for k, cases in pairs(JEWELLERY_CASES) do
    for i = 1, #cases do
      local case = cases[i]
      local fnd_coords = case.coords
      local fnd_dist = #(coords - fnd_coords)

      if fnd_dist < dist then
        closest = i
        entity = GetClosestObjectOfType(fnd_coords.x, fnd_coords.y, fnd_coords.z, 0.1, case.start_prop, true, true, false)
        location = k
        dist = fnd_dist
      end
    end
  end
  return location, closest, entity
end

---@param _type string
---@param cam integer?
local function alert_dispatch(_type, cam)
  if not DISPATCH[_type] then return end
  local is_event = DISPATCH.event
  local name = DISPATCH.name
  if is_event then
    TriggerServerEvent(name, translate(('info.%s_dispatch'):format(_type)), _type ~= 'case' and nil or cam)
  elseif DISPATCH[_type].export then
    exports[name][DISPATCH[_type].export](nil, _type ~= 'case' and nil or cam)
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
  local heading = case_data.heading
  local offset = GetOffsetFromCoordAndHeadingInWorldCoords(coords.x, coords.y, coords.z, heading, 0.0, -1.0, 0.0)
  local duration = GetAnimDuration(dict, anim)
  local sequence = OpenSequenceTask()
  ---@diagnostic disable-next-line: param-type-mismatch
  TaskFollowNavMeshToCoord(0, offset.x, offset.y, offset.z, 1.0, 1500, 0.5, 512, heading)
  TaskPlayAnimAdvanced(0, dict, anim, offset.x, offset.y, offset.z, 0.0, 0.0, heading, 1.0, 1.0, duration, 1090527232 --[[+ 4194304 Adds Collision on Impact]], 0.0)
  CloseSequenceTask(sequence)
  TaskPerformSequence(ped, sequence)
  ClearSequenceTask(sequence)
  RemoveAnimDict(dict)
  CreateThread(function()
    while GetEntityAnimCurrentTime(ped, dict, anim) <= 0.04 do
      Wait(0)
      if not GetIsTaskActive(ped, 32) then
        ClearPedTasks(ped)
        TriggerServerEvent('jewellery:server:SetCaseState', location, case, 'busy', false)
        return
      end
    end
    TriggerServerEvent('jewellery:server:SetCaseState', location, case, 'open', true)
    bridge.callback.trigger('jewellery:server:IsStoreVulnerable', 100, function(hacked, hit)
      if not hacked and not GlobalState[('jewellery:alarm:%s'):format(location)] then
        local chance = math.random(100)
        if chance < (not bridge.callback.await('jewellery:server:IsStoreOpen') and 70 or 100) then
          local cams = type(case_data.cams) == 'table' and case_data.cams or {case_data.cams}
          alert_dispatch('case', cams[#cams > 1 and math.random(#cams) or 1])
        end
      end
    end, location)
  end)
  if not core.isplayergloved() then
    TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
  end
end

---@param location string
---@param coords vector3
---@param heading number
local function use_thermite(location, coords, heading)
  local chance = math.random(100)
  if chance <= 10 then alert_dispatch('suss') end

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
  local abort = false
  scene:start(function(phase)
    if phase >= 0.4 and IsEntityAttached(thermite) then
      DetachEntity(thermite, true, true)
      FreezeEntityPosition(thermite, true)
      if not exports[THERMITE.resource][THERMITE.export](nil, unpack(THERMITE.settings)) then
        Wait(500)
        scene:clear(false, true)
        abort = true
        bridge.notify.text(translate('error.fail_therm'), 'error')
        return
      end
      TriggerServerEvent('jewellery:server:SyncThermite', location)
    end
  end)
  if not abort then
    bridge.notify.text(translate('success.thermite'), 'success')
    bridge.callback.trigger('jewellery:server:IsStoreVulnerable', false, function(hacked, hit)
      if not hacked then
        chance = math.random(100)
        if chance < (not bridge.callback.await('jewellery:server:IsStoreOpen') and 85 or 100) then
          alert_dispatch('thermite')
        end
      end
      if hit then return end
      TriggerServerEvent('jewellery:server:SetStoreState', location, 'hit', true)
    end, location)
    Wait(5000)
    scene:clear(false, true)
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
  local leo = bridge.core.doesplayerhavegroup(GetTypeJobs('leo'))

  bridge.notify.text(translate('info.hacking_attempt'), 'primary', 2000)
  AttachEntityToEntity(tablet, ped, GetPedBoneIndex(ped, 57005), 0.17, 0.10, -0.13, 20.0, 180.0, 180.0, true, true, false, true, 1, true)
  TaskPlayAnim(ped, dict, 'base', 8.0, -8.0, -1, 50, 1.0, false, false, false)
  Wait(2000)

  if not leo and not exports[HACK.resource][HACK.export](nil, unpack(HACK.settings)) then
    bridge.notify.text(translate('error.fail_hack'), 'error')
  else
    bridge.callback.trigger('jewellery:server:IsStoreVulnerable', false, function()
      if not leo then
        bridge.notify.text(translate('success.hacked'), 'success')
        TriggerServerEvent('jewellery:server:SetStoreState', location, 'hacked', true)
      end
    end, location)
  end
  StopAnimTask(ped, dict, 'base', 8.0)
  DeleteObject(tablet)
  RemoveAnimDict(dict)
end

---@param resource string?
local function init_script(resource)
  if resource and type(resource) == 'string' and resource ~= RES_NAME then return end
  isLoggedIn = LocalPlayer.state.isLoggedIn or IsPlayerPlaying(PlayerId())
  bridge.callback.trigger('jewellery:server:GetCaseStates', 1000, set_cases)
  if GlobalState['jewellery:alarm'] and GlobalState['jewellery:alarm'].state then
    play_jewel_alarm(GlobalState['jewellery:alarm'].location)
  end
  bridge.target.addmodel(start_case_models, {
    {
      name = 'jewellery:case',
      icon = 'fa fa-hand',
      label = translate('general.target_label'),
      canInteract = function()
        return isLoggedIn and not bridge.callback.await('jewellery:server:IsCaseBusy', false) and is_brandishing_weapon()
      end,
      onSelect = function()
        local location, case, entity = get_closest_case(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.25, 0.0))
        if not bridge.callback.await('jewellery:server:GetPolicePresence', false, location) then return end

        smash_case(location, case, entity)
      end,
      distance = 1.5
    }
  })

  for k, v in pairs(LOCATIONS) do
    local coords = v.coords
    Blips[k] = exports.gr_blips:new('coord', {
      coords = coords
    }, {
      sprite = 617,
      name = glib.locale.iskeyvalid('general.store_labels.'..k) and translate('general.store_labels.'..k) or translate('general.store_label'),
      display = 'map',
      primary = 3,
      style = {scale = 0.4, short_range = true},
      flashes = {enable = Alarms[k] ~= nil, interval = 500, colour = 1},
      opacity = GlobalState[('jewellery:open:%s'):format(k)] and 255 or 255/2
    })
    local thermite = v.thermite
    bridge.target.addboxzone({
      center = thermite.coords,
      size = thermite.size,
      heading = thermite.heading,
      debug = DEBUG
    }, {
      {
        name = 'jewellery:thermite:'..k,
        icon = 'fas fa-bug',
        label = translate('general.thermite_label'),
        item = thermite.item,
        canInteract = function()
          local _, hit = bridge.callback.await('jewellery:server:IsStoreVulnerable', false, k)
          return isLoggedIn and not hit
        end,
        onSelect = function()
          if not bridge.callback.await('jewellery:server:GetPolicePresence', false, k) then return end

          use_thermite(k, thermite.coords, thermite.heading)
        end,
        distance = 2.5
      }
    })
    local hack = v.hack
    if hack then
      bridge.target.addboxzone({
        center = hack.coords,
        size = hack.size,
        heading = hack.heading,
        debug = DEBUG
      }, {
        {
          name = 'jewellery:hack:'..k,
          icon = 'fas fa-bug',
          label = translate('general.hack_label'),
          item = hack.item,
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
end

--------------------- HANDLERS ---------------------

AddEventHandler('onResourceStart', init_script)
AddEventHandler('onResourceStop', deinit_script)
for location in pairs(LOCATIONS) do
  AddStateBagChangeHandler(('jewellery:open:%s'):format(location), 'global', function(_, _, state)
    if state == nil then return end
    if state then
      if not Blips[location] then return end
      exports.gr_blips:setopacity(Blips[location], 255)
    else
      if not Blips[location] then return end
      exports.gr_blips:setopacity(Blips[location], 255/2)
    end
  end)
  AddStateBagChangeHandler(('jewellery:alarm:%s'):format(location), 'global', function(_, _, state)
    if state == nil then return end
    if state and not Alarms[location] then
      play_jewel_alarm(location)
      if not Blips[location] then return end
      exports.gr_blips:setflashes(Blips[location], {enable = true, interval = 500, colour = 1})
    elseif not state and Alarms[location] then
      stop_jewel_alarm(location)
      if not Blips[location] then return end
      exports.gr_blips:setflashes(Blips[location], {enable = false})
    end
  end)
end

--------------------- EVENTS ---------------------

if bridge.core.getname() == 'qbx_core' then
  AddEventHandler(bridge.core.getevent('load'), init_script)
else
  RegisterNetEvent(bridge.core.getevent('load'), init_script)
end

RegisterNetEvent(bridge.core.getevent('unload'), deinit_script)
RegisterNetEvent('jewellery:client:SetCaseState', set_case_state)
RegisterNetEvent('jewellery:client:SyncThermite', thermite_effect)
RegisterNetEvent('jewellery:client:StoreClosing', store_close_warning)
