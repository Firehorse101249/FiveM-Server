SRPMed = SRPMed or {}

function SRPMed.ResolveSeverity(damage)
    damage = tonumber(damage) or 1
    for severity, cfg in pairs(Config.Severity) do
        if damage >= cfg.minDamage and damage <= cfg.maxDamage then
            return severity
        end
    end
    return 'minor'
end

function SRPMed.SeverityScore(severity)
    local cfg = Config.Severity[severity or 'minor']
    return cfg and cfg.score or 1
end

function SRPMed.NormalizeBodyPart(part)
    if part and Config.BodyParts[part] then return part end
    return 'chest'
end

function SRPMed.ProfileForInjury(injuryType)
    return Config.InjuryProfiles[injuryType] or Config.InjuryProfiles.blunt_trauma
end

function SRPMed.CreateInjury(data)
    local injuryType = data.type or 'blunt_trauma'
    local profile = SRPMed.ProfileForInjury(injuryType)
    local severity = data.severity or SRPMed.ResolveSeverity(data.damage or 1)
    local severityScore = SRPMed.SeverityScore(severity)
    local now = SRPMed.Now()

    return {
        id = data.id or SRPMed.NewId('inj'),
        type = injuryType,
        label = profile.label or injuryType,
        bodyPart = SRPMed.NormalizeBodyPart(data.bodyPart),
        severity = severity,
        severityScore = severityScore,
        bleeding = SRPMed.Clamp((data.bleeding or profile.bleeding or 0) + math.max(0, severityScore - 2), 0, 4),
        pain = SRPMed.Clamp((data.pain or profile.pain or 0) + (severityScore * 5), 0, 100),
        consciousnessImpact = SRPMed.Clamp((data.consciousness or profile.consciousness or 0) + (severityScore * 3), 0, 100),
        oxygenImpact = SRPMed.Clamp(data.oxygen or profile.oxygen or 0, -100, 20),
        treatmentStatus = data.treatmentStatus or 'untreated',
        stabilized = data.stabilized or false,
        discovered = data.discovered or false,
        createdAt = data.createdAt or now,
        lastTreatedAt = data.lastTreatedAt,
        worsenedAt = data.worsenedAt,
        timeUntreated = data.timeUntreated or 0,
        worsenRisk = SRPMed.Clamp((data.worsenRisk or profile.worsenRisk or 5) + (severityScore * 3), 0, 100),
        possibleComplications = data.possibleComplications or profile.complications or {},
        complications = data.complications or {},
        source = data.source or 'unknown'
    }
end

function SRPMed.CalculateVitals(injuries, previous)
    local vitals = SRPMed.CopyTable(MedicalVitalsDefaults)
    if previous then
        vitals.glucose = previous.glucose or vitals.glucose
        vitals.temperature = previous.temperature or vitals.temperature
    end

    local totalPain = 0
    local bleedingLoad = 0
    local consciousnessLoss = 0
    local oxygenLoss = 0
    local criticalCount = 0
    local severeCount = 0

    for _, injury in pairs(injuries or {}) do
        if injury.treatmentStatus ~= 'resolved' then
            local mitigation = injury.stabilized and 0.55 or 1.0
            totalPain = totalPain + ((injury.pain or 0) * mitigation)
            bleedingLoad = bleedingLoad + ((injury.bleeding or 0) * (injury.severityScore or 1) * mitigation)
            consciousnessLoss = consciousnessLoss + ((injury.consciousnessImpact or 0) * mitigation)
            oxygenLoss = oxygenLoss + math.abs(math.min(0, injury.oxygenImpact or 0)) * mitigation

            if injury.severity == 'critical' then criticalCount = criticalCount + 1 end
            if injury.severity == 'severe' then severeCount = severeCount + 1 end
        end
    end

    vitals.pain = SRPMed.Clamp(math.floor(totalPain), 0, 100)
    vitals.bloodVolume = SRPMed.Clamp(100 - math.floor(bleedingLoad * 4), 0, 100)
    vitals.oxygen = SRPMed.Clamp(98 - math.floor(oxygenLoss) - math.max(0, 85 - vitals.bloodVolume), 0, 100)
    vitals.consciousness = SRPMed.Clamp(100 - math.floor(consciousnessLoss) - math.max(0, 88 - vitals.oxygen), 0, 100)

    vitals.heartRate = SRPMed.Clamp(78 + math.floor(vitals.pain * 0.55) + math.floor((100 - vitals.bloodVolume) * 0.8), 0, 190)
    vitals.systolic = SRPMed.Clamp(122 - math.floor((100 - vitals.bloodVolume) * 0.9) - (criticalCount * 12), 45, 190)
    vitals.diastolic = SRPMed.Clamp(78 - math.floor((100 - vitals.bloodVolume) * 0.45) - (criticalCount * 7), 25, 120)
    vitals.breathing = vitals.oxygen > 18
    vitals.pulse = vitals.heartRate > 20 and vitals.systolic > 45

    if criticalCount > 0 or severeCount > 1 then
        vitals.pupils = 'Sluggish'
    end
    if vitals.oxygen < 70 or vitals.consciousness < 45 then
        vitals.pupils = 'Unequal / sluggish'
    end

    return vitals
end

function SRPMed.CalculateStage(vitals, injuries, currentStage)
    local hasInjury = false
    local hasCritical = false
    for _, injury in pairs(injuries or {}) do
        if injury.treatmentStatus ~= 'resolved' then
            hasInjury = true
            if injury.type == 'cardiac_arrest' or injury.severity == 'critical' then
                hasCritical = true
            end
        end
    end

    if currentStage == MedicalStages.DECEASED then return MedicalStages.DECEASED end
    if not vitals.pulse or vitals.heartRate <= 20 then return MedicalStages.CARDIAC_ARREST end
    if vitals.oxygen <= 18 then return MedicalStages.CARDIAC_ARREST end
    if vitals.bloodVolume <= 15 then return MedicalStages.CARDIAC_ARREST end
    if vitals.consciousness <= 5 then return MedicalStages.UNCONSCIOUS end
    if hasCritical or vitals.oxygen < 55 or vitals.bloodVolume < 45 or vitals.systolic < 75 then return MedicalStages.CRITICAL end
    if vitals.consciousness < 35 then return MedicalStages.UNCONSCIOUS end
    if vitals.pain > 75 or vitals.bloodVolume < 70 or vitals.oxygen < 82 then return MedicalStages.INCAPACITATED end
    if hasInjury then return MedicalStages.INJURED end
    return 'healthy'
end

function SRPMed.WorsenInjury(injury)
    if injury.treatmentStatus == 'resolved' or injury.stabilized then
        return injury, nil
    end

    local severityOrder = { minor = 'moderate', moderate = 'severe', severe = 'critical', critical = 'critical' }
    local oldSeverity = injury.severity

    if injury.bleeding > 0 then
        injury.bleeding = SRPMed.Clamp(injury.bleeding + 1, 0, 4)
    end
    injury.pain = SRPMed.Clamp((injury.pain or 0) + 8, 0, 100)
    injury.consciousnessImpact = SRPMed.Clamp((injury.consciousnessImpact or 0) + 5, 0, 100)
    injury.severity = severityOrder[injury.severity] or injury.severity
    injury.severityScore = SRPMed.SeverityScore(injury.severity)
    injury.worsenedAt = SRPMed.Now()

    if oldSeverity ~= injury.severity then
        return injury, ('%s worsened from %s to %s'):format(injury.label, oldSeverity, injury.severity)
    end
    return injury, ('%s worsened'):format(injury.label)
end
