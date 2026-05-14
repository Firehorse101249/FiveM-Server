ServerBridge = ServerBridge or {}

local QBCore = nil

CreateThread(function()
    Wait(1000)
    if Config.Framework == 'qb' then
        local ok, core = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok then
            QBCore = core
            ServerBridge.RegisterUsableMedicalItems()
        else
            print('[srp_medical] QBCore not found. Running in standalone fallback mode.')
        end
    end
end)

function ServerBridge.GetPlayer(source)
    if QBCore and QBCore.Functions then
        return QBCore.Functions.GetPlayer(source)
    end
    return nil
end

function ServerBridge.GetIdentifier(source)
    local player = ServerBridge.GetPlayer(source)
    if player and player.PlayerData then
        return player.PlayerData.citizenid
    end
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:find('license:') then return identifier end
    end
    return ('src:%s'):format(source)
end

function ServerBridge.GetName(source)
    local player = ServerBridge.GetPlayer(source)
    if player then
        return SRPMed.FormatPatientName(player)
    end
    return GetPlayerName(source) or 'Unknown Patient'
end

function ServerBridge.GetJob(source)
    local player = ServerBridge.GetPlayer(source)
    if player and player.PlayerData and player.PlayerData.job then
        local job = player.PlayerData.job
        return {
            name = job.name or 'civilian',
            grade = (job.grade and (job.grade.level or job.grade.grade)) or 0,
            label = job.label or job.name or 'Civilian'
        }
    end
    return { name = 'civilian', grade = 0, label = 'Civilian' }
end

function ServerBridge.Notify(source, message, notifyType)
    TriggerClientEvent('srp_medical:client:notify', source, message, notifyType or 'primary')
end

function ServerBridge.IsAdmin(source)
    if source == 0 then return Config.Admin.AllowConsole end
    return IsPlayerAceAllowed(source, Config.Admin.AcePermission)
end

function ServerBridge.RegisterUsableMedicalItems()
    if not QBCore or not QBCore.Functions or not QBCore.Functions.CreateUseableItem then return end

    local registered = {}
    for _, treatment in pairs(Config.Treatments or {}) do
        if treatment.item and not registered[treatment.item] then
            registered[treatment.item] = true
            QBCore.Functions.CreateUseableItem(treatment.item, function(source)
                TriggerClientEvent('srp_medical:client:useMedicalItem', source)
            end)
        end
    end
end
