CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(250)
    end

    TriggerServerEvent(Core.Events.PlayerReady)
end)
