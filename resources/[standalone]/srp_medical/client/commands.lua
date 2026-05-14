local function nearestPlayer()
    local players = GetActivePlayers()
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local closestPlayer = nil
    local closestDistance = Config.Targeting.MaxPatientDistance or 3.0

    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            local distance = #(GetEntityCoords(ped) - myCoords)
            if distance < closestDistance then
                closestPlayer = player
                closestDistance = distance
            end
        end
    end

    if closestPlayer then
        return GetPlayerServerId(closestPlayer)
    end
    return GetPlayerServerId(PlayerId())
end

RegisterCommand('medui', function()
    OpenMedicalUi(nearestPlayer())
end, false)

RegisterCommand('treat', function()
    OpenMedicalUi(nearestPlayer())
end, false)

RegisterCommand('emsreport', function()
    OpenMedicalUi(nearestPlayer())
    SendNUIMessage({ action = 'tab', tab = 'reports' })
end, false)

RegisterCommand('medicalhistory', function()
    OpenMedicalUi(nearestPlayer())
    SendNUIMessage({ action = 'tab', tab = 'history' })
end, false)

RegisterCommand('checkpulse', function()
    local target = nearestPlayer()
    ClientBridge.Callback('performAssessment', { target = target, assessment = 'check_pulse' }, function(response)
        ClientBridge.Notify(response and response.message or 'Unable to check pulse.', response and response.ok and 'primary' or 'error')
    end)
end, false)

RegisterCommand('checkbreathing', function()
    local target = nearestPlayer()
    ClientBridge.Callback('performAssessment', { target = target, assessment = 'check_breathing' }, function(response)
        ClientBridge.Notify(response and response.message or 'Unable to check breathing.', response and response.ok and 'primary' or 'error')
    end)
end, false)

RegisterCommand('carrypatient', function()
    TriggerServerEvent('srp_medical:server:dragPatient', nearestPlayer())
end, false)

RegisterCommand('loadstretcher', function()
    ClientBridge.Notify('Stretcher integration placeholder fired. Connect this event to your stretcher resource.', 'primary')
    TriggerServerEvent('srp_medical:server:stretcherPlaceholder', nearestPlayer())
end, false)

RegisterNetEvent('srp_medical:client:useMedicalItem', function()
    OpenMedicalUi(nearestPlayer())
end)
