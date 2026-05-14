MedicalPerms = MedicalPerms or {}

local RuntimeCerts = {}

local function roleForSource(source)
    local job = ServerBridge.GetJob(source)
    local jobCfg = Config.Jobs[job.name] or Config.Jobs.civilian
    return {
        job = job,
        role = jobCfg.role or 'civilian',
        label = jobCfg.label or job.label or 'Civilian',
        rankBonus = (jobCfg.rankBonus or 0) + (tonumber(job.grade) or 0)
    }
end

function MedicalPerms.GetRole(source)
    return roleForSource(source)
end

function MedicalPerms.GetRuntimeCerts(identifier)
    RuntimeCerts[identifier] = RuntimeCerts[identifier] or {}
    return RuntimeCerts[identifier]
end

function MedicalPerms.BuildCerts(source, cb)
    local identifier = ServerBridge.GetIdentifier(source)
    local role = roleForSource(source)
    local certs = {}

    for _, cert in ipairs(Config.RoleDefaults[role.role] or {}) do
        certs[cert] = Config.Certifications[cert] and Config.Certifications[cert].level or 1
    end

    for cert, level in pairs(MedicalPerms.GetRuntimeCerts(identifier)) do
        certs[cert] = math.max(certs[cert] or 0, level)
    end

    MedicalDB.GetCertifications(identifier, function(rows)
        for _, row in ipairs(rows or {}) do
            certs[row.certification] = math.max(certs[row.certification] or 0, tonumber(row.level) or 1)
        end
        cb(certs, role)
    end)
end

function MedicalPerms.HasRole(role, allowed)
    if not allowed then return true end
    return SRPMed.TableContains(allowed, role)
end

function MedicalPerms.CertLevel(certs, cert)
    if not cert then return 0 end
    return certs[cert] or 0
end

function MedicalPerms.CalculateChance(source, treatmentId, injury, context, cb)
    local treatment = Config.Treatments[treatmentId]
    if not treatment then cb(0, { reason = 'Unknown treatment.' }) return end

    MedicalPerms.BuildCerts(source, function(certs, role)
        local roleName = role.role
        local tuning = Config.SuccessTuning
        local override = Config.RoleSuccessOverrides[treatmentId] and Config.RoleSuccessOverrides[treatmentId][roleName]
        local chance = override or treatment.baseSuccess or 50
        local reasons = {}

        if not MedicalPerms.HasRole(roleName, treatment.allowedRoles) then
            chance = chance - tuning.WrongRolePenalty
            reasons[#reasons + 1] = 'role mismatch'
        end

        local requiredCert = treatment.requiredCert
        if requiredCert then
            local requiredLevel = Config.Certifications[requiredCert] and Config.Certifications[requiredCert].level or 1
            local providerLevel = MedicalPerms.CertLevel(certs, requiredCert)
            if providerLevel <= 0 then
                chance = chance - tuning.MissingCertPenalty
                reasons[#reasons + 1] = 'missing certification'
            else
                chance = chance + ((providerLevel - requiredLevel) * tuning.CertLevelBonus)
            end
        end

        chance = chance + role.rankBonus

        if injury then
            chance = chance - ((injury.severityScore or 1) - 1) * tuning.SeverityPenalty
            local untreatedMinutes = math.floor(((SRPMed.Now() - (injury.createdAt or SRPMed.Now())) / 60))
            chance = chance - math.floor(untreatedMinutes * tuning.UntreatedMinutePenalty)
            if SRPMed.TreatmentCanTreat(treatment, injury) then
                chance = chance + tuning.CorrectToolBonus
            else
                chance = chance - 18
                reasons[#reasons + 1] = 'imperfect tool choice'
            end
            if not SRPMed.TreatmentCanTargetBody(treatment, injury.bodyPart) then
                chance = chance - 35
                reasons[#reasons + 1] = 'wrong body region'
            end
            if injury.stabilized then
                chance = chance + tuning.StabilizedBonus
            end
        end

        if context and context.moving then
            chance = chance - tuning.MovementPenalty
        end
        if context and context.hospital then
            chance = chance + tuning.HospitalBonus
        elseif treatment.hospitalOnly then
            chance = chance - 50
            reasons[#reasons + 1] = 'hospital equipment required'
        end

        chance = SRPMed.Clamp(math.floor(chance), tuning.MinChance, tuning.MaxChance)
        cb(chance, { role = role, certs = certs, reasons = reasons })
    end)
end

function MedicalPerms.SetRuntimeCert(identifier, cert, level)
    RuntimeCerts[identifier] = RuntimeCerts[identifier] or {}
    RuntimeCerts[identifier][cert] = tonumber(level) or 1
end

function MedicalPerms.RemoveRuntimeCert(identifier, cert)
    RuntimeCerts[identifier] = RuntimeCerts[identifier] or {}
    RuntimeCerts[identifier][cert] = nil
end
