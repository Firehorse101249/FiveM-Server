local hudVisible = true

RegisterCommand('hud', function()
    hudVisible = not hudVisible

    SendNUIMessage({
        type = 'setVisible',
        visible = hudVisible
    })
end, false)
