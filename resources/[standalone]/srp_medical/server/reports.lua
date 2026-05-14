MedicalReports = MedicalReports or {}

function MedicalReports.Create(provider, data, cb)
    local target = tonumber(data.target)
    if not target then cb({ ok = false, message = 'Missing patient.' }) return end

    local patient = MedicalState.Get(target)
    local providerRole = MedicalPerms.GetRole(provider)
    if Config.Report.RequireJob and not SRPMed.TableContains(Config.Report.AllowedRoles, providerRole.role) then
        cb({ ok = false, message = 'You cannot create EMS reports.' })
        return
    end

    local narrative = tostring(data.narrative or '')
    if #narrative > Config.Report.MaxNarrativeLength then
        narrative = narrative:sub(1, Config.Report.MaxNarrativeLength)
    end

    local report = {
        patientIdentifier = patient.identifier,
        patientName = patient.name,
        providerIdentifier = ServerBridge.GetIdentifier(provider),
        providerName = ServerBridge.GetName(provider),
        department = providerRole.label,
        injuries = patient.injuries,
        treatments = patient.treatmentLog,
        medications = data.medications or {},
        destination = data.destination or '',
        outcome = data.outcome or patient.stage,
        narrative = narrative
    }

    MedicalDB.AddReport(report, function(id)
        cb({ ok = true, id = id, message = 'Patient care report saved.', report = report })
    end)
end

function MedicalReports.History(requester, target, cb)
    local state = MedicalState.Get(target)
    MedicalDB.GetHistory(state.identifier, function(rows)
        cb({ ok = true, history = rows or {} })
    end)
end
