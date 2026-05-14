local lastHealth = 200
local lastArmor = 0
local isDeadState = false

local weaponGroups = {
    [-957766203] = 'unarmed',
    [416676503] = 'firearm',
    [860033945] = 'firearm',
    [970310034] = 'firearm',
    [1159398588] = 'firearm',
    [-1212426201] = 'firearm',
    [-1569042529] = 'explosion',
    [1548507267] = 'fire',
    [-728555052] = 'melee',
    [-1609580060] = 'melee'
}

local function getBodyPart()
    local ped = PlayerPedId()
    local hit, bone = GetPedLastDamageBone(ped)
    if hit and Config.BoneMap[bone] then
        return Config.BoneMap[bone]
    end
    return 'chest'
end

local function getDamageType(weapon)
    if not weapon or weapon == 0 then return 'generic' end
    local group = GetWeapontypeGroup(weapon)
    return weaponGroups[group] or 'generic'
end

local function reportDamage(weapon, damage, source)
    if damage <= 0 then return end
    local damageType = getDamageType(weapon)
    TriggerServerEvent('srp_medical:server:applyDamageInjury', {
        damageType = damageType,
        injuryType = Config.DamageMap[damageType] or Config.DamageMap.generic,
        bodyPart = getBodyPart(),
        damage = damage,
        weapon = weapon,
        source = source or 'damage'
    })
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local victim = args[1]
    if victim ~= PlayerPedId() then return end

    local weapon = args[7] or args[5] or 0
    local newHealth = GetEntityHealth(victim)
    local newArmor = GetPedArmour(victim)
    local healthDamage = math.max(0, lastHealth - newHealth)
    local armorDamage = math.max(0, lastArmor - newArmor)
    local totalDamage = healthDamage + math.floor(armorDamage * 0.35)

    if totalDamage > 0 then
        reportDamage(weapon, totalDamage, 'combat')
    end

    lastHealth = newHealth
    lastArmor = newArmor
end)

CreateThread(function()
    Wait(1000)
    local ped = PlayerPedId()
    lastHealth = GetEntityHealth(ped)
    lastArmor = GetPedArmour(ped)

    while true do
        Wait(1500)
        ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        if health > lastHealth then
            lastHealth = health
        end
        lastArmor = GetPedArmour(ped)
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if IsEntityDead(ped) and not isDeadState then
            isDeadState = true
            TriggerServerEvent('srp_medical:server:setStage', MedicalStages.CARDIAC_ARREST)
            SetEntityHealth(ped, 120)
            SetPedToRagdoll(ped, 5000, 5000, 0, false, false, false)
        elseif not IsEntityDead(ped) and isDeadState then
            isDeadState = false
        end
    end
end)

RegisterNetEvent('srp_medical:client:syncState', function(state)
    if not state then return end
    local ped = PlayerPedId()
    if state.stage == MedicalStages.UNCONSCIOUS or state.stage == MedicalStages.CRITICAL or state.stage == MedicalStages.CARDIAC_ARREST then
        SetPedToRagdoll(ped, 4000, 4000, 0, false, false, false)
    end
    SendNUIMessage({ action = 'stateUpdated', state = state })
end)

RegisterNetEvent('srp_medical:client:notify', function(message, notifyType)
    ClientBridge.Notify(message, notifyType)
end)

RegisterNetEvent('srp_medical:client:revive', function(coords)
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(coords and coords.x or GetEntityCoords(ped).x, coords and coords.y or GetEntityCoords(ped).y, coords and coords.z or GetEntityCoords(ped).z, GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, 160)
    ClearPedTasksImmediately(ped)
    ClientBridge.Notify('You have been stabilized.', 'success')
end)

RegisterNetEvent('srp_medical:client:playTreatment', function(label, duration)
    ClientBridge.Progress(label or 'Treating patient', duration or 3000)
end)
