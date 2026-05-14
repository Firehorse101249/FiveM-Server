local callbacks = {}

local function registerCallback(name, fn)
    callbacks[name] = fn
end

RegisterNetEvent('srp_medical:serverCallback', function(name, responseEvent, data)
    local src = source
    local fn = callbacks[name]
    if not fn then
        TriggerClientEvent(responseEvent, src, { ok = false, message = 'Unknown medical callback.' })
        return
    end
    fn(src, data or {}, function(response)
        TriggerClientEvent(responseEvent, src, response or { ok = false })
    end)
end)

AddEventHandler('playerJoining', function()
    local src = source
    local identifier = ServerBridge.GetIdentifier(src)
    MedicalDB.LoadState(identifier, function(saved)
        if saved then
            saved.source = src
            saved.identifier = identifier
            saved.name = ServerBridge.GetName(src)
            MedicalState.Players[src] = saved
            MedicalState.Recalculate(src)
        else
            MedicalState.Get(src)
        end
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    MedicalState.Save(src)
    MedicalState.Players[src] = nil
end)

RegisterNetEvent('srp_medical:server:applyDamageInjury', function(data)
    local src = source
    if not Config.DeathSystem.Enabled and (data.damage or 0) <= 0 then return end
    data.type = data.injuryType
    MedicalState.ApplyInjury(src, data)
end)

RegisterNetEvent('srp_medical:server:setStage', function(stage)
    local src = source
    if stage == MedicalStages.CARDIAC_ARREST or stage == MedicalStages.UNCONSCIOUS or stage == MedicalStages.CRITICAL then
        MedicalState.SetStage(src, stage)
    end
end)

RegisterNetEvent('srp_medical:server:dragPatient', function(target)
    local src = source
    target = tonumber(target)
    if not target then return end
    ServerBridge.Notify(src, 'Drag/carry placeholder event fired. Wire this to your carry animation resource.', 'primary')
    TriggerEvent('srp_medical:server:onCarryPatient', src, target)
end)

RegisterNetEvent('srp_medical:server:stretcherPlaceholder', function(target)
    TriggerEvent('srp_medical:server:onLoadStretcher', source, target)
end)

AddEventHandler('srp_medical:server:applyInjury', function(target, data)
    target = tonumber(target)
    if target then MedicalState.ApplyInjury(target, data or {}) end
end)

AddEventHandler('srp_medical:server:healInjury', function(target, injuryId)
    target = tonumber(target)
    if not target then return end
    local injury = MedicalState.FindInjury(target, injuryId)
    if injury then
        injury.treatmentStatus = 'resolved'
        injury.stabilized = true
        MedicalState.Recalculate(target)
    end
end)

AddEventHandler('srp_medical:server:setUnconscious', function(target)
    target = tonumber(target)
    if target then MedicalState.SetStage(target, MedicalStages.UNCONSCIOUS) end
end)

AddEventHandler('srp_medical:server:revivePlayer', function(target)
    target = tonumber(target)
    if not target then return end
    MedicalState.Clear(target)
    TriggerClientEvent('srp_medical:client:revive', target)
end)

AddEventHandler('srp_medical:server:openPatientUi', function(provider, target)
    provider = tonumber(provider)
    target = tonumber(target)
    if provider and target then TriggerClientEvent('srp_medical:client:openPatientUi', provider, target) end
end)

AddEventHandler('srp_medical:server:addMedicalReport', function(provider, data)
    provider = tonumber(provider)
    if provider then MedicalReports.Create(provider, data or {}, function() end) end
end)

registerCallback('getPatient', function(src, data, cb)
    local target = tonumber(data.target) or src
    local state = MedicalState.Get(target)
    MedicalPerms.BuildCerts(src, function(certs, role)
        cb({
            ok = true,
            patient = state,
            provider = {
                source = src,
                name = ServerBridge.GetName(src),
                role = role,
                certifications = certs
            }
        })
    end)
end)

registerCallback('performAssessment', function(src, data, cb)
    local target = tonumber(data.target) or src
    local assessmentId = data.assessment
    local assessment = Config.AssessmentTools[assessmentId]
    if not assessment then cb({ ok = false, message = 'Unknown assessment.' }) return end

    MedicalPerms.BuildCerts(src, function(certs, role)
        if not MedicalPerms.HasRole(role.role, assessment.allowedRoles) then
            cb({ ok = false, message = 'Your role cannot perform that assessment.' })
            return
        end
        if assessment.cert and not certs[assessment.cert] then
            cb({ ok = false, message = 'Missing required certification.' })
            return
        end

        local state = MedicalState.Get(target)
        if assessmentId == 'full_body_scan' or assessmentId == 'trauma_assessment' then
            for _, injury in pairs(state.injuries) do
                injury.discovered = true
            end
        end

        local message = 'Assessment complete.'
        if assessmentId == 'check_pulse' then
            message = state.vitals.pulse and ('Pulse present, HR %s.'):format(state.vitals.heartRate) or 'No pulse detected.'
        elseif assessmentId == 'check_breathing' then
            message = state.vitals.breathing and ('Breathing present, SpO2 %s%%.'):format(state.vitals.oxygen) or 'Patient is not breathing.'
        elseif assessmentId == 'blood_pressure' then
            message = ('BP %s/%s.'):format(state.vitals.systolic, state.vitals.diastolic)
        elseif assessmentId == 'oxygen_saturation' then
            message = ('SpO2 %s%%.'):format(state.vitals.oxygen)
        elseif assessmentId == 'blood_glucose' then
            message = ('BGL %s mg/dL.'):format(state.vitals.glucose)
        elseif assessmentId == 'pupils' then
            message = ('Pupils: %s.'):format(state.vitals.pupils)
        elseif assessmentId == 'responsiveness' then
            message = ('Consciousness %s%%, stage %s.'):format(state.vitals.consciousness, state.stage)
        end

        MedicalState.AddLog(target, {
            providerIdentifier = ServerBridge.GetIdentifier(src),
            providerName = ServerBridge.GetName(src),
            treatment = assessmentId,
            result = 'assessment',
            notes = message
        })
        MedicalState.Sync(target)
        cb({ ok = true, message = message, patient = state })
    end)
end)

registerCallback('performTreatment', function(src, data, cb)
    MedicalState.PerformTreatment(src, tonumber(data.target) or src, data.treatment, data.injuryId, data.bodyPart, cb)
end)

registerCallback('createReport', function(src, data, cb)
    MedicalReports.Create(src, data, cb)
end)

registerCallback('getHistory', function(src, data, cb)
    MedicalReports.History(src, tonumber(data.target) or src, cb)
end)

registerCallback('automatedRecovery', function(src, data, cb)
    MedicalState.AutomatedRecovery(src, tonumber(data.target) or src, cb)
end)

CreateThread(function()
    while true do
        Wait(Config.Progression.TickMs or 30000)
        if Config.Progression.Enabled then
            for source, state in pairs(MedicalState.Players) do
                local changed = false
                for _, injury in pairs(state.injuries) do
                    if injury.treatmentStatus ~= 'resolved' and not injury.stabilized then
                        injury.timeUntreated = (injury.timeUntreated or 0) + math.floor((Config.Progression.TickMs or 30000) / 1000)
                        local minutes = math.floor(injury.timeUntreated / 60)
                        local threshold = Config.Progression.MinorBleedWorsenMinutes
                        if injury.bleeding == 2 then threshold = Config.Progression.ModerateBleedWorsenMinutes end
                        if injury.bleeding >= 3 then threshold = Config.Progression.SevereBleedShockMinutes end

                        if minutes >= threshold and math.random(1, 100) <= (injury.worsenRisk or 5) then
                            local _, note = SRPMed.WorsenInjury(injury)
                            MedicalState.AddLog(source, {
                                providerIdentifier = 'system',
                                providerName = 'System',
                                treatment = 'progression',
                                result = 'worsened',
                                injuryId = injury.id,
                                bodyPart = injury.bodyPart,
                                notes = note
                            })
                            injury.timeUntreated = 0
                            changed = true
                        end
                    end
                end
                if changed then
                    MedicalState.Recalculate(source)
                    MedicalState.Save(source)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.Progression.SaveIntervalMs or 120000)
        for source in pairs(MedicalState.Players) do
            MedicalState.Save(source)
        end
    end
end)

RegisterCommand('medtestinjury', function(source, args)
    if not ServerBridge.IsAdmin(source) then return end
    local target = tonumber(args[1]) or source
    local injuryType = args[2] or 'gunshot_wound'
    local bodyPart = args[3] or 'chest'
    local severity = args[4] or 'moderate'
    MedicalState.ApplyInjury(target, { type = injuryType, bodyPart = bodyPart, severity = severity, source = 'admin' })
    if source > 0 then ServerBridge.Notify(source, 'Test injury applied.', 'success') end
end, true)

RegisterCommand('medclear', function(source, args)
    if not ServerBridge.IsAdmin(source) then return end
    local target = tonumber(args[1]) or source
    MedicalState.Clear(target)
    if source > 0 then ServerBridge.Notify(source, 'Medical state cleared.', 'success') end
end, true)

RegisterCommand('medgivecert', function(source, args)
    if not ServerBridge.IsAdmin(source) then return end
    local target = tonumber(args[1])
    local cert = args[2]
    local level = tonumber(args[3]) or (Config.Certifications[cert] and Config.Certifications[cert].level) or 1
    if not target or not cert then return end
    local identifier = ServerBridge.GetIdentifier(target)
    MedicalPerms.SetRuntimeCert(identifier, cert, level)
    MedicalDB.SetCertification(identifier, cert, level, ServerBridge.GetIdentifier(source))
    if source > 0 then ServerBridge.Notify(source, 'Certification granted.', 'success') end
end, true)

RegisterCommand('medremovecert', function(source, args)
    if not ServerBridge.IsAdmin(source) then return end
    local target = tonumber(args[1])
    local cert = args[2]
    if not target or not cert then return end
    local identifier = ServerBridge.GetIdentifier(target)
    MedicalPerms.RemoveRuntimeCert(identifier, cert)
    MedicalDB.RemoveCertification(identifier, cert)
    if source > 0 then ServerBridge.Notify(source, 'Certification removed.', 'success') end
end, true)

RegisterCommand('medstate', function(source, args)
    if not ServerBridge.IsAdmin(source) then return end
    local target = tonumber(args[1]) or source
    print(json.encode(MedicalState.Get(target)))
end, true)

exports('ApplyInjury', function(target, data) return MedicalState.ApplyInjury(target, data) end)
exports('HealInjury', function(target, injuryId)
    local injury = MedicalState.FindInjury(target, injuryId)
    if injury then
        injury.treatmentStatus = 'resolved'
        injury.stabilized = true
        MedicalState.Recalculate(target)
    end
end)
exports('GetMedicalState', function(target) return MedicalState.Get(target) end)
exports('SetUnconscious', function(target) MedicalState.SetStage(target, MedicalStages.UNCONSCIOUS) end)
exports('RevivePlayer', function(target)
    MedicalState.Clear(target)
    TriggerClientEvent('srp_medical:client:revive', target)
end)
exports('OpenPatientUI', function(provider, target) TriggerClientEvent('srp_medical:client:openPatientUi', provider, target) end)
exports('AddMedicalReport', function(provider, data, cb) MedicalReports.Create(provider, data, cb or function() end) end)
