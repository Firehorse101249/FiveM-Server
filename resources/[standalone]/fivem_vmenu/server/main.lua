RegisterNetEvent('fivem_vmenu:server:requestPermission', function()
    local source = source
    local allowed = true

    if Config.RequireAce then
        allowed = IsPlayerAceAllowed(source, Config.AcePermission)
    end

    TriggerClientEvent('fivem_vmenu:client:permissionResult', source, allowed)
end)
