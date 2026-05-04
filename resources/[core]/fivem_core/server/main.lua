local function log(message)
    if Config.Debug then
        print(('[%s] %s'):format(Core.ResourceName, message))
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Core.ResourceName then
        return
    end

    log('server core started')
end)

RegisterNetEvent(Core.Events.PlayerReady, function()
    local source = source
    log(('player %s is ready'):format(source))
end)
