local nuiOpen = false
local currentPatient = nil

local function setNui(open)
    nuiOpen = open
    SetNuiFocus(open, open)
    SendNUIMessage({ action = open and 'open' or 'close' })
end

local function requestPatient(target)
    ClientBridge.Callback('getPatient', { target = target }, function(response)
        if not response or not response.ok then
            ClientBridge.Notify(response and response.message or 'Unable to open patient chart.', 'error')
            return
        end
        currentPatient = response.patient.source
        SendNUIMessage({
            action = 'hydrate',
            patient = response.patient,
            provider = response.provider,
            config = {
                bodyParts = Config.BodyParts,
                treatments = Config.Treatments,
                assessments = Config.AssessmentTools,
                hospitalActions = Config.HospitalActions
            }
        })
        setNui(true)
    end)
end

function OpenMedicalUi(target)
    requestPatient(target or GetPlayerServerId(PlayerId()))
end

RegisterNetEvent('srp_medical:client:openPatientUi', function(target)
    OpenMedicalUi(target)
end)

RegisterNUICallback('close', function(_, cb)
    setNui(false)
    cb({ ok = true })
end)

RegisterNUICallback('refreshPatient', function(data, cb)
    ClientBridge.Callback('getPatient', { target = data.target or currentPatient }, function(response)
        cb(response or { ok = false })
    end)
end)

RegisterNUICallback('performAssessment', function(data, cb)
    ClientBridge.Callback('performAssessment', {
        target = data.target or currentPatient,
        assessment = data.assessment
    }, function(response)
        cb(response or { ok = false })
    end)
end)

RegisterNUICallback('performTreatment', function(data, cb)
    ClientBridge.Callback('performTreatment', {
        target = data.target or currentPatient,
        treatment = data.treatment,
        injuryId = data.injuryId,
        bodyPart = data.bodyPart
    }, function(response)
        cb(response or { ok = false })
    end)
end)

RegisterNUICallback('createReport', function(data, cb)
    ClientBridge.Callback('createReport', data, function(response)
        cb(response or { ok = false })
    end)
end)

RegisterNUICallback('getHistory', function(data, cb)
    ClientBridge.Callback('getHistory', { target = data.target or currentPatient }, function(response)
        cb(response or { ok = false })
    end)
end)

RegisterNUICallback('automatedRecovery', function(data, cb)
    ClientBridge.Callback('automatedRecovery', { target = data.target or currentPatient }, function(response)
        cb(response or { ok = false })
    end)
end)

RegisterNUICallback('dragPatient', function(data, cb)
    TriggerServerEvent('srp_medical:server:dragPatient', data.target or currentPatient)
    cb({ ok = true })
end)
