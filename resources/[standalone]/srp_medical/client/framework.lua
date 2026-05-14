ClientBridge = ClientBridge or {}

local QBCore = nil

CreateThread(function()
    if Config.Framework == 'qb' then
        local ok, core = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok then
            QBCore = core
        end
    end
end)

function ClientBridge.Notify(message, notifyType)
    notifyType = notifyType or 'primary'
    if Config.UseOxLib and GetResourceState('ox_lib') == 'started' and lib then
        lib.notify({ title = 'Medical', description = message, type = notifyType })
        return
    end
    if QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(message, notifyType)
        return
    end
    TriggerEvent('chat:addMessage', { args = { 'Medical', message } })
end

function ClientBridge.Progress(label, duration)
    if duration <= 0 then return true end
    if Config.UseOxLib and GetResourceState('ox_lib') == 'started' and lib and lib.progressCircle then
        return lib.progressCircle({
            duration = duration,
            label = label,
            position = 'bottom',
            canCancel = true,
            disable = { move = false, car = true, combat = true }
        })
    end
    Wait(duration)
    return true
end

function ClientBridge.Callback(name, data, cb)
    local eventName = ('srp_medical:serverCallback:%s:%s'):format(name, GetGameTimer())
    RegisterNetEvent(eventName, function(response)
        cb(response)
    end)
    TriggerServerEvent('srp_medical:serverCallback', name, eventName, data or {})
end
