MedicalState = MedicalState or {}
MedicalState.Players = MedicalState.Players or {}

local function emptyState(source)
    return {
        source = source,
        identifier = ServerBridge.GetIdentifier(source),
        name = ServerBridge.GetName(source),
        stage = 'healthy',
        injuries = {},
        vitals = SRPMed.CopyTable(MedicalVitalsDefaults),
        treatmentLog = {},
        flags = {
            admitted = false,
            triage = nil,
            recoveryInProgress = false,
            deceasedAt = nil
        },
        createdAt = SRPMed.Now(),
        updatedAt = SRPMed.Now()
    }
end

function MedicalState.Get(source)
    source = tonumber(source)
    if not source then return nil end
    if not MedicalState.Players[source] then
        MedicalState.Players[source] = emptyState(source)
    end
    MedicalState.Players[source].source = source
    MedicalState.Players[source].identifier = ServerBridge.GetIdentifier(source)
    MedicalState.Players[source].name = ServerBridge.GetName(source)
    return MedicalState.Players[source]
end

function MedicalState.Set(source, state)
    MedicalState.Players[source] = state
    MedicalState.Sync(source)
end

function MedicalState.Sync(source)
    local state = MedicalState.Get(source)
    if state then
        TriggerClientEvent('srp_medical:client:syncState', source, state)
    end
end

function MedicalState.Save(source)
    local state = MedicalState.Get(source)
    if state then
        MedicalDB.SaveState(state.identifier, state)
    end
end

function MedicalState.Recalculate(source)
    local state = MedicalState.Get(source)
    state.vitals = SRPMed.CalculateVitals(state.injuries, state.vitals)
    state.stage = SRPMed.CalculateStage(state.vitals, state.injuries, state.stage)
    state.updatedAt = SRPMed.Now()
    MedicalState.Sync(source)
    return state
end

function MedicalState.AddLog(source, entry)
    local state = MedicalState.Get(source)
    entry.id = entry.id or SRPMed.NewId('log')
    entry.createdAt = SRPMed.Now()
    state.treatmentLog[#state.treatmentLog + 1] = entry
    if #state.treatmentLog > 80 then
        table.remove(state.treatmentLog, 1)
    end
    MedicalDB.AddTreatmentLog(state.identifier, entry)
end

function MedicalState.ApplyInjury(source, data)
    local state = MedicalState.Get(source)
    local injury = SRPMed.CreateInjury(data or {})
    state.injuries[injury.id] = injury
    MedicalState.AddLog(source, {
        providerIdentifier = 'system',
        providerName = 'System',
        treatment = 'injury_applied',
        result = injury.type,
        injuryId = injury.id,
        bodyPart = injury.bodyPart,
        notes = ('%s %s to %s'):format(injury.severity, injury.label, SRPMed.BodyLabel(injury.bodyPart))
    })
    MedicalState.Recalculate(source)
    MedicalState.Save(source)
    return injury
end

function MedicalState.Clear(source)
    MedicalState.Players[source] = emptyState(source)
    MedicalState.Save(source)
    MedicalState.Sync(source)
end

function MedicalState.FindInjury(source, injuryId, bodyPart)
    local state = MedicalState.Get(source)
    if injuryId and state.injuries[injuryId] then
        return state.injuries[injuryId]
    end
    for _, injury in pairs(state.injuries) do
        if injury.treatmentStatus ~= 'resolved' and (not bodyPart or injury.bodyPart == bodyPart) then
            return injury
        end
    end
    return nil
end

function MedicalState.SetStage(source, stage)
    local state = MedicalState.Get(source)
    state.stage = stage
    state.updatedAt = SRPMed.Now()
    if stage == MedicalStages.DECEASED then
        state.flags.deceasedAt = SRPMed.Now()
    end
    MedicalState.Save(source)
    MedicalState.Sync(source)
end

function MedicalState.PerformTreatment(provider, target, treatmentId, injuryId, bodyPart, cb)
    local treatment = Config.Treatments[treatmentId]
    if not treatment then cb({ ok = false, message = 'Unknown treatment.' }) return end

    local targetState = MedicalState.Get(target)
    local injury = MedicalState.FindInjury(target, injuryId, bodyPart)
    local providerPed = GetPlayerPed(provider)
    local targetPed = GetPlayerPed(target)
    local providerCoords = GetEntityCoords(providerPed)
    local targetCoords = GetEntityCoords(targetPed)
    local inHospital = SRPMed.IsHospitalPosition(providerCoords)
    local distance = #(providerCoords - targetCoords)

    if distance > (Config.Targeting.MaxPatientDistance or 3.0) and not inHospital then
        cb({ ok = false, message = 'Patient is too far away.' })
        return
    end

    if treatment.target ~= 'provider' and not injury and not treatment.effect.automatedRecovery then
        cb({ ok = false, message = 'No matching injury found for that treatment.' })
        return
    end

    if not InventoryBridge.HasItem(provider, treatment.item, 1) then
        cb({ ok = false, message = ('Missing required item: %s'):format(treatment.item) })
        return
    end

    MedicalPerms.CalculateChance(provider, treatmentId, injury, { hospital = inHospital }, function(chance, permission)
        local roll = math.random(1, 100)
        local result
        if roll <= chance then
            result = MedicalResult.SUCCESS
        elseif roll <= chance + Config.SuccessTuning.PartialWithin then
            result = MedicalResult.PARTIAL
        elseif chance <= Config.SuccessTuning.WorsenBelow and roll > 88 then
            result = MedicalResult.WORSENED
        else
            result = MedicalResult.FAILED
        end

        local consume = false
        if result == MedicalResult.SUCCESS then consume = Config.ItemRequirements.ConsumeOnSuccess end
        if result == MedicalResult.PARTIAL then consume = Config.ItemRequirements.ConsumeOnPartial end
        if result == MedicalResult.FAILED then consume = Config.ItemRequirements.ConsumeOnFail end
        if result == MedicalResult.WORSENED then consume = Config.ItemRequirements.ConsumeOnWorsen end
        if consume then InventoryBridge.RemoveItem(provider, treatment.item, 1) end

        TriggerClientEvent('srp_medical:client:playTreatment', provider, treatment.label, treatment.time or 3000)

        if result == MedicalResult.SUCCESS or result == MedicalResult.PARTIAL then
            if treatment.effect and treatment.effect.automatedRecovery then
                MedicalState.AutomatedRecovery(provider, target, function() end)
            else
                injury, targetState.vitals = SRPMed.ApplyTreatmentEffect(injury, targetState.vitals, treatment, result)
                if injury then injury.lastTreatedAt = SRPMed.Now() end
            end
        elseif result == MedicalResult.WORSENED and injury then
            injury.pain = SRPMed.Clamp((injury.pain or 0) + 10, 0, 100)
            injury.bleeding = SRPMed.Clamp((injury.bleeding or 0) + 1, 0, 4)
        end

        local providerIdentifier = ServerBridge.GetIdentifier(provider)
        local entry = {
            providerIdentifier = providerIdentifier,
            providerName = ServerBridge.GetName(provider),
            treatment = treatmentId,
            result = result,
            injuryId = injury and injury.id or injuryId,
            bodyPart = injury and injury.bodyPart or bodyPart,
            notes = ('%s rolled %s/%s as %s'):format(treatment.label, roll, chance, permission.role.role)
        }

        MedicalState.AddLog(target, entry)
        local state = MedicalState.Recalculate(target)
        MedicalState.Save(target)

        cb({
            ok = true,
            result = result,
            chance = chance,
            roll = roll,
            message = ('%s: %s'):format(treatment.label, result),
            patient = state
        })
    end)
end

function MedicalState.AutomatedRecovery(provider, target, cb)
    local state = MedicalState.Get(target)
    if state.flags.recoveryInProgress then
        cb({ ok = false, message = 'Recovery is already in progress.' })
        return
    end

    local coords = GetEntityCoords(GetPlayerPed(provider))
    local inHospital, location = SRPMed.IsHospitalPosition(coords)
    if Config.AutomatedRecovery.RequireHospital and not inHospital then
        cb({ ok = false, message = 'Automated recovery requires a configured hospital zone.' })
        return
    end

    state.flags.recoveryInProgress = true
    state.flags.admitted = true
    state.flags.hospital = location and location.id or 'field'
    MedicalState.Sync(target)

    SetTimeout((Config.AutomatedRecovery.TreatmentDurationSeconds or 45) * 1000, function()
        local fresh = MedicalState.Get(target)
        local severePenalty = 0
        local stableBonus = 0

        for _, injury in pairs(fresh.injuries) do
            if injury.severity == 'critical' then severePenalty = severePenalty + 12 end
            if injury.severity == 'severe' then severePenalty = severePenalty + 7 end
            if injury.stabilized then stableBonus = stableBonus + 4 end
        end

        local chance = Config.AutomatedRecovery.BaseChance - severePenalty
        if Config.AutomatedRecovery.StabilizationImprovesChance then
            chance = chance + math.min(Config.AutomatedRecovery.StableBonus, stableBonus)
        end
        if fresh.stage == MedicalStages.CRITICAL or fresh.stage == MedicalStages.CARDIAC_ARREST then
            chance = chance - Config.AutomatedRecovery.CriticalPenalty
        end
        chance = SRPMed.Clamp(chance, 10, 98)

        if math.random(1, 100) <= chance then
            for _, injury in pairs(fresh.injuries) do
                injury.treatmentStatus = 'resolved'
                injury.stabilized = true
                injury.bleeding = 0
                injury.pain = math.min(injury.pain or 0, 10)
            end
            fresh.vitals = SRPMed.CopyTable(MedicalVitalsDefaults)
            fresh.stage = 'healthy'
            fresh.flags.recoveryInProgress = false
            MedicalState.AddLog(target, {
                providerIdentifier = ServerBridge.GetIdentifier(provider),
                providerName = ServerBridge.GetName(provider),
                treatment = 'automated_recovery',
                result = 'success',
                notes = ('Automated recovery completed at %s with %s%% chance.'):format(location and location.label or 'hospital', chance)
            })
            TriggerClientEvent('srp_medical:client:revive', target)
            ServerBridge.Notify(target, 'Automated recovery completed successfully.', 'success')
        else
            fresh.flags.recoveryInProgress = false
            for _, injury in pairs(fresh.injuries) do
                if injury.treatmentStatus ~= 'resolved' then
                    injury.stabilized = true
                    injury.treatmentStatus = 'stabilized_pending_recovery'
                end
            end
            MedicalState.AddLog(target, {
                providerIdentifier = ServerBridge.GetIdentifier(provider),
                providerName = ServerBridge.GetName(provider),
                treatment = 'automated_recovery',
                result = 'stabilized',
                notes = ('Recovery did not fully resolve injuries. Chance was %s%%.'):format(chance)
            })
            ServerBridge.Notify(target, 'Hospital recovery stabilized you, but more recovery time is needed.', 'primary')
        end

        MedicalState.Recalculate(target)
        MedicalState.Save(target)
    end)

    cb({ ok = true, message = 'Automated recovery started.', patient = state })
end
