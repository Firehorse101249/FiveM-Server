local menuOpen = false
local hasPermission = not Config.RequireAce

local componentIds = {
    { id = 1, label = 'Mask' },
    { id = 3, label = 'Arms' },
    { id = 4, label = 'Pants' },
    { id = 6, label = 'Shoes' },
    { id = 7, label = 'Accessories' },
    { id = 8, label = 'Undershirt' },
    { id = 9, label = 'Armor' },
    { id = 11, label = 'Top' }
}

local function notify(message)
    TriggerEvent('chat:addMessage', {
        color = { 87, 182, 255 },
        args = { 'V Menu', message }
    })
end

local function setMenuOpen(open)
    menuOpen = open == true
    SetNuiFocus(menuOpen, menuOpen)
    SetNuiFocusKeepInput(menuOpen)
    SendNUIMessage({
        type = 'visible',
        visible = menuOpen
    })
end

local function sendConfig()
    SendNUIMessage({
        type = 'config',
        vehicles = Config.VehicleCategories,
        playerModels = Config.PlayerModels,
        outfits = Config.QuickOutfits,
        colors = Config.VehicleColors,
        components = componentIds,
        requireAce = Config.RequireAce
    })
end

local function requestModel(model)
    local hash = type(model) == 'number' and model or joaat(model)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(0)

        if GetGameTimer() > timeout then
            return nil
        end
    end

    return hash
end

local function getCurrentVehicle()
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        return 0
    end

    return GetVehiclePedIsIn(ped, false)
end

local function deleteVehicle(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    NetworkRequestControlOfEntity(vehicle)

    local timeout = GetGameTimer() + 1500
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
        Wait(0)
        NetworkRequestControlOfEntity(vehicle)
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
    return true
end

local function spawnVehicle(model)
    local hash = requestModel(model)

    if not hash then
        notify(('Could not load vehicle model: %s'):format(tostring(model)))
        return
    end

    local ped = PlayerPedId()
    local currentVehicle = getCurrentVehicle()

    if Config.ReplaceCurrentVehicle and currentVehicle ~= 0 then
        deleteVehicle(currentVehicle)
    end

    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, 0.0)
    local heading = GetEntityHeading(ped)
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)

    SetVehicleOnGroundProperly(vehicle)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetModelAsNoLongerNeeded(hash)

    if Config.SpawnInsideVehicle then
        SetPedIntoVehicle(ped, vehicle, -1)
    end

    notify(('Spawned %s'):format(model))
end

local function getVehicleForAction()
    local ped = PlayerPedId()
    local vehicle = getCurrentVehicle()

    if vehicle ~= 0 then
        return vehicle
    end

    local coords = GetEntityCoords(ped)
    vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, Config.DeleteRadius, 0, 70)

    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        return vehicle
    end

    return 0
end

local function maxVehicleMods(vehicle)
    SetVehicleModKit(vehicle, 0)

    for modType = 0, 48 do
        local count = GetNumVehicleMods(vehicle, modType)

        if count and count > 0 then
            SetVehicleMod(vehicle, modType, count - 1, false)
        end
    end

    ToggleVehicleMod(vehicle, 18, true)
    ToggleVehicleMod(vehicle, 22, true)
    SetVehicleWindowTint(vehicle, 1)
end

local function repairVehicle(vehicle)
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleDirtLevel(vehicle, 0.0)
end

local function cycleComponent(componentId, direction)
    local ped = PlayerPedId()
    local currentDrawable = GetPedDrawableVariation(ped, componentId)
    local maxDrawable = GetNumberOfPedDrawableVariations(ped, componentId)

    if maxDrawable <= 0 then
        return
    end

    local nextDrawable = currentDrawable + direction

    if nextDrawable >= maxDrawable then
        nextDrawable = 0
    elseif nextDrawable < 0 then
        nextDrawable = maxDrawable - 1
    end

    SetPedComponentVariation(ped, componentId, nextDrawable, 0, 0)
end

RegisterNetEvent('fivem_vmenu:client:permissionResult', function(allowed)
    hasPermission = allowed == true

    if not hasPermission then
        notify('You do not have permission to use this menu.')
        setMenuOpen(false)
        return
    end

    setMenuOpen(not menuOpen)
end)

RegisterCommand(Config.Command, function()
    if Config.RequireAce then
        TriggerServerEvent('fivem_vmenu:server:requestPermission')
        return
    end

    if not hasPermission then
        notify('You do not have permission to use this menu.')
        return
    end

    setMenuOpen(not menuOpen)
end, false)

RegisterKeyMapping(Config.Command, 'Open custom V menu', 'keyboard', Config.OpenKey)

RegisterNUICallback('ready', function(_, cb)
    sendConfig()
    cb({})
end)

RegisterNUICallback('close', function(_, cb)
    setMenuOpen(false)
    cb({})
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    spawnVehicle(data.model)
    cb({})
end)

RegisterNUICallback('vehicleAction', function(data, cb)
    local vehicle = getVehicleForAction()

    if vehicle == 0 then
        notify('No nearby vehicle found.')
        cb({})
        return
    end

    if data.action == 'repair' then
        repairVehicle(vehicle)
    elseif data.action == 'clean' then
        SetVehicleDirtLevel(vehicle, 0.0)
    elseif data.action == 'delete' then
        deleteVehicle(vehicle)
    elseif data.action == 'maxMods' then
        maxVehicleMods(vehicle)
    elseif data.action == 'flip' then
        SetVehicleOnGroundProperly(vehicle)
    end

    cb({})
end)

RegisterNUICallback('setVehicleColor', function(data, cb)
    local vehicle = getVehicleForAction()

    if vehicle ~= 0 then
        SetVehicleColours(vehicle, tonumber(data.primary) or 0, tonumber(data.secondary) or 0)
    end

    cb({})
end)

RegisterNUICallback('toggleExtra', function(data, cb)
    local vehicle = getVehicleForAction()
    local extra = tonumber(data.extra)

    if vehicle ~= 0 and extra and DoesExtraExist(vehicle, extra) then
        local enabled = IsVehicleExtraTurnedOn(vehicle, extra)
        SetVehicleExtra(vehicle, extra, enabled and 1 or 0)
    end

    cb({})
end)

RegisterNUICallback('setPlayerModel', function(data, cb)
    local hash = requestModel(data.model)

    if hash then
        SetPlayerModel(PlayerId(), hash)
        SetModelAsNoLongerNeeded(hash)
        SetPedDefaultComponentVariation(PlayerPedId())
    else
        notify(('Could not load player model: %s'):format(tostring(data.model)))
    end

    cb({})
end)

RegisterNUICallback('playerAction', function(data, cb)
    local ped = PlayerPedId()

    if data.action == 'heal' then
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
    elseif data.action == 'armor' then
        SetPedArmour(ped, 100)
    elseif data.action == 'clearBlood' then
        ClearPedBloodDamage(ped)
        ResetPedVisibleDamage(ped)
    elseif data.action == 'defaultClothes' then
        SetPedDefaultComponentVariation(ped)
        ClearAllPedProps(ped)
    end

    cb({})
end)

RegisterNUICallback('cycleComponent', function(data, cb)
    cycleComponent(tonumber(data.component) or 0, tonumber(data.direction) or 1)
    cb({})
end)

RegisterNUICallback('applyOutfit', function(data, cb)
    local index = tonumber(data.index)
    local outfit = index and Config.QuickOutfits[index]

    if outfit then
        local ped = PlayerPedId()

        for _, component in ipairs(outfit.components) do
            SetPedComponentVariation(ped, component.id, component.drawable, component.texture or 0, 0)
        end
    end

    cb({})
end)

CreateThread(function()
    Wait(500)
    sendConfig()
    SendNUIMessage({
        type = 'visible',
        visible = false
    })
end)
