local uiVisible = Config.DefaultUiVisible
local uiFocused = false
local localState = {
    lights = 1,
    siren = false,
    tone = 1,
    manual = false,
    airhorn = false
}
local syncedStates = {}
local activeSounds = {}
local lastVehicle = 0

local function hasValue(list, value)
    for _, item in ipairs(list) do
        if item == value then
            return true
        end
    end

    return false
end

local function getPedVehicle()
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        return 0
    end

    local vehicle = GetVehiclePedIsIn(ped, false)

    if Config.DriverOnly and GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return 0
    end

    return vehicle
end

local function isAllowedVehicle(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    if Config.AllowAnyVehicleForTesting then
        return true
    end

    local model = GetEntityModel(vehicle)

    if Config.AllowedModels[model] then
        return true
    end

    return Config.AllowedClasses[GetVehicleClass(vehicle)] == true
end

local function getVehicleNetId(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    if not NetworkGetEntityIsNetworked(vehicle) then
        NetworkRegisterEntityAsNetworked(vehicle)
        Wait(0)
    end

    local netId = VehToNet(vehicle)

    if netId == 0 then
        return nil
    end

    return netId
end

local function debugMessage(message)
    if not Config.Debug then
        return
    end

    print(('[fivem_els] %s'):format(message))
    TriggerEvent('chat:addMessage', {
        color = { 255, 80, 80 },
        args = { 'ELS', message }
    })
end

local function clampStage(stage)
    stage = tonumber(stage) or 1

    if stage < 1 then
        return 1
    end

    if stage > #Config.LightStages then
        return #Config.LightStages
    end

    return stage
end

local function clampTone(tone)
    tone = tonumber(tone) or 1

    if tone < 1 then
        return 1
    end

    if tone > #Config.SirenTones then
        return #Config.SirenTones
    end

    return tone
end

local function sendUiState(vehicle)
    SendNUIMessage({
        type = 'state',
        visible = uiVisible,
        focused = uiFocused,
        available = isAllowedVehicle(vehicle or getPedVehicle()),
        state = localState,
        lightStages = Config.LightStages,
        tones = Config.SirenTones
    })
end

local function setFocus(focused)
    uiFocused = focused == true
    SetNuiFocus(uiFocused, uiFocused)
    SetNuiFocusKeepInput(uiFocused)
    sendUiState()
end

local function setVisible(visible)
    uiVisible = visible == true
    SendNUIMessage({
        type = 'visible',
        visible = uiVisible
    })

    if not uiVisible then
        setFocus(false)
    else
        sendUiState()
    end
end

local function stopSound(netId, key)
    local bucket = activeSounds[netId]

    if not bucket or not bucket[key] then
        return
    end

    StopSound(bucket[key])
    ReleaseSoundId(bucket[key])
    bucket[key] = nil
end

local function playLoopSound(netId, key, vehicle, tone)
    if not tone or not tone.soundName then
        return
    end

    activeSounds[netId] = activeSounds[netId] or {}

    if activeSounds[netId][key] then
        StopSound(activeSounds[netId][key])
        ReleaseSoundId(activeSounds[netId][key])
    end

    local soundId = GetSoundId()
    activeSounds[netId][key] = soundId
    PlaySoundFromEntity(soundId, tone.soundName, vehicle, tone.soundSet or '0', false, 0)
end

local function applyLights(vehicle, stage)
    stage = clampStage(stage)
    local selectedExtras = Config.LightStages[stage].extras or {}

    for _, extra in ipairs(Config.ManagedExtras) do
        if DoesExtraExist(vehicle, extra) then
            SetVehicleExtra(vehicle, extra, hasValue(selectedExtras, extra) and 0 or 1)
        end
    end

    SetVehicleSiren(vehicle, stage > 1)
end

local function applyVehicleState(netId, state)
    local vehicle = NetToVeh(netId)

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle)) > Config.ControlDistance then
        return
    end

    state.lights = clampStage(state.lights)
    state.tone = clampTone(state.tone)
    applyLights(vehicle, state.lights)
    SetVehicleHasMutedSirens(vehicle, true)

    if state.siren then
        playLoopSound(netId, 'siren', vehicle, Config.SirenTones[state.tone])
    else
        stopSound(netId, 'siren')
    end

    if state.manual then
        playLoopSound(netId, 'manual', vehicle, Config.ManualTone)
    else
        stopSound(netId, 'manual')
    end

    if state.airhorn then
        playLoopSound(netId, 'airhorn', vehicle, Config.Airhorn)
    else
        stopSound(netId, 'airhorn')
    end
end

local function syncState()
    local vehicle = getPedVehicle()

    if not isAllowedVehicle(vehicle) then
        debugMessage('No allowed vehicle found. Get in the driver seat, or enable testing/allowed model in config.lua.')
        sendUiState(vehicle)
        return
    end

    localState.lights = clampStage(localState.lights)
    localState.tone = clampTone(localState.tone)

    local netId = getVehicleNetId(vehicle)

    if not netId then
        debugMessage('Vehicle has no network id yet. Applying lights locally only.')
        applyLights(vehicle, localState.lights)
        SetVehicleHasMutedSirens(vehicle, true)
        return
    end

    applyVehicleState(netId, localState)
    TriggerServerEvent('fivem_els:server:setState', netId, localState)
    sendUiState(vehicle)
end

local function setLights(stage)
    localState.lights = clampStage(stage)

    if localState.lights <= 1 then
        localState.siren = false
        localState.manual = false
        localState.airhorn = false
    end

    syncState()
end

local function cycleLights()
    local nextStage = localState.lights + 1

    if nextStage > #Config.LightStages then
        nextStage = 1
    end

    setLights(nextStage)
end

local function setSiren(enabled)
    if enabled and localState.lights <= 1 then
        localState.lights = math.min(2, #Config.LightStages)
    end

    localState.siren = enabled == true
    syncState()
end

local function cycleTone()
    localState.tone = localState.tone + 1

    if localState.tone > #Config.SirenTones then
        localState.tone = 1
    end

    syncState()
end

RegisterNetEvent('fivem_els:client:applyState', function(netId, state)
    syncedStates[netId] = state
    applyVehicleState(netId, state)
end)

RegisterNetEvent('fivem_els:client:hydrateStates', function(states)
    syncedStates = states or {}

    for netId, state in pairs(syncedStates) do
        applyVehicleState(netId, state)
    end
end)

RegisterNetEvent('fivem_els:client:clearState', function(netId)
    syncedStates[netId] = nil
    stopSound(netId, 'siren')
    stopSound(netId, 'manual')
    stopSound(netId, 'airhorn')
end)

RegisterNUICallback('close', function(_, cb)
    setFocus(false)
    cb({})
end)

RegisterNUICallback('setLights', function(data, cb)
    setLights(data.stage)
    cb({})
end)

RegisterNUICallback('toggleSiren', function(data, cb)
    setSiren(data.enabled)
    cb({})
end)

RegisterNUICallback('setTone', function(data, cb)
    localState.tone = clampTone(data.tone)
    syncState()
    cb({})
end)

RegisterNUICallback('setMomentary', function(data, cb)
    local key = data.key
    local enabled = data.enabled == true

    if key == 'manual' or key == 'airhorn' then
        if enabled and localState.lights <= 1 then
            localState.lights = math.min(2, #Config.LightStages)
        end

        localState[key] = enabled
        syncState()
    end

    cb({})
end)

RegisterCommand(Config.Command, function()
    setVisible(not uiVisible)
end, false)

RegisterCommand('els_focus', function()
    if uiVisible then
        setFocus(not uiFocused)
    end
end, false)

RegisterCommand('els_lights', cycleLights, false)
RegisterCommand('els_siren', function()
    setSiren(not localState.siren)
end, false)
RegisterCommand('els_tone', cycleTone, false)
RegisterCommand('els_debug', function()
    local vehicle = getPedVehicle()

    if vehicle == 0 then
        debugMessage('You are not in the driver seat of a vehicle.')
        return
    end

    local message = ('vehicle=%s model=%s class=%s allowed=%s networked=%s netId=%s extras='):format(
        vehicle,
        GetEntityModel(vehicle),
        GetVehicleClass(vehicle),
        tostring(isAllowedVehicle(vehicle)),
        tostring(NetworkGetEntityIsNetworked(vehicle)),
        tostring(getVehicleNetId(vehicle))
    )

    local extras = {}

    for _, extra in ipairs(Config.ManagedExtras) do
        if DoesExtraExist(vehicle, extra) then
            extras[#extras + 1] = tostring(extra)
        end
    end

    debugMessage(message .. table.concat(extras, ','))
end, false)
RegisterCommand('+els_manual', function()
    localState.manual = true
    syncState()
end, false)
RegisterCommand('-els_manual', function()
    localState.manual = false
    syncState()
end, false)
RegisterCommand('+els_airhorn', function()
    localState.airhorn = true
    syncState()
end, false)
RegisterCommand('-els_airhorn', function()
    localState.airhorn = false
    syncState()
end, false)

RegisterKeyMapping(Config.Command, 'Toggle ELS panel', 'keyboard', Config.Keybinds.toggleUi)
RegisterKeyMapping('els_focus', 'Focus ELS panel', 'keyboard', Config.Keybinds.focusUi)
RegisterKeyMapping('els_lights', 'ELS cycle lights', 'keyboard', Config.Keybinds.lights)
RegisterKeyMapping('els_siren', 'ELS toggle siren', 'keyboard', Config.Keybinds.siren)
RegisterKeyMapping('els_tone', 'ELS cycle tone', 'keyboard', Config.Keybinds.tone)
RegisterKeyMapping('+els_manual', 'ELS manual siren', 'keyboard', Config.Keybinds.manual)
RegisterKeyMapping('+els_airhorn', 'ELS airhorn', 'keyboard', Config.Keybinds.airhorn)

CreateThread(function()
    Wait(1000)
    setVisible(uiVisible)
    TriggerServerEvent('fivem_els:server:requestStates')

    while true do
        local vehicle = getPedVehicle()

        if vehicle ~= lastVehicle then
            lastVehicle = vehicle
            sendUiState(vehicle)
        end

        Wait(500)
    end
end)

CreateThread(function()
    while true do
        for netId, state in pairs(syncedStates) do
            applyVehicleState(netId, state)
        end

        Wait(1250)
    end
end)
