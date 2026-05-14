SRPMed = SRPMed or {}

function SRPMed.TreatmentCanTargetBody(treatment, bodyPart)
    if treatment.bodyParts == 'all' then return true end
    if type(treatment.bodyParts) ~= 'table' then return true end
    return SRPMed.TableContains(treatment.bodyParts, bodyPart)
end

function SRPMed.TreatmentCanTreat(treatment, injury)
    if not injury then
        return treatment.treats and SRPMed.TableContains(treatment.treats, 'all')
    end
    if treatment.treats and SRPMed.TableContains(treatment.treats, 'all') then return true end
    if treatment.treats and SRPMed.TableContains(treatment.treats, injury.type) then return true end
    if treatment.treats and SRPMed.TableContains(treatment.treats, 'pain') and (injury.pain or 0) > 25 then return true end
    return false
end

function SRPMed.ApplyTreatmentEffect(injury, vitals, treatment, result)
    local effect = treatment.effect or {}
    local power = result == MedicalResult.SUCCESS and 1.0 or 0.5

    if injury and effect.bleeding then
        injury.bleeding = SRPMed.Clamp((injury.bleeding or 0) + math.floor(effect.bleeding * power), 0, 4)
    end
    if injury and effect.pain then
        injury.pain = SRPMed.Clamp((injury.pain or 0) + math.floor(effect.pain * power), 0, 100)
    end
    if injury and effect.stabilize then
        injury.stabilized = true
    end
    if injury and effect.immobilize then
        injury.stabilized = true
    end
    if injury and effect.scan then
        injury.discovered = true
    end
    if injury and effect.oxygen then
        injury.oxygenImpact = SRPMed.Clamp((injury.oxygenImpact or 0) + math.floor(effect.oxygen * power), -100, 20)
        injury.consciousnessImpact = SRPMed.Clamp((injury.consciousnessImpact or 0) - math.floor(effect.oxygen * 0.35 * power), 0, 100)
    end
    if injury and effect.bloodVolume then
        injury.bleeding = SRPMed.Clamp((injury.bleeding or 0) - 1, 0, 4)
        injury.consciousnessImpact = SRPMed.Clamp((injury.consciousnessImpact or 0) - math.floor(effect.bloodVolume * 0.4 * power), 0, 100)
    end
    if injury and effect.shock then
        injury.stabilized = true
        injury.worsenRisk = SRPMed.Clamp((injury.worsenRisk or 0) - 12, 0, 100)
        injury.consciousnessImpact = SRPMed.Clamp((injury.consciousnessImpact or 0) - 10, 0, 100)
    end
    if injury and effect.arrest then
        injury.stabilized = true
        injury.oxygenImpact = SRPMed.Clamp((injury.oxygenImpact or 0) + 45, -100, 20)
        injury.consciousnessImpact = SRPMed.Clamp((injury.consciousnessImpact or 0) - 65, 0, 100)
        if injury.type == 'cardiac_arrest' then
            injury.severity = 'severe'
            injury.severityScore = SRPMed.SeverityScore('severe')
        end
    end
    if injury and result == MedicalResult.SUCCESS and (injury.bleeding or 0) <= 0 and (injury.pain or 0) <= 18 then
        injury.treatmentStatus = 'resolved'
    elseif injury and result == MedicalResult.SUCCESS then
        injury.treatmentStatus = 'treated'
        injury.stabilized = true
    elseif injury and result == MedicalResult.PARTIAL then
        injury.treatmentStatus = 'partially_treated'
    end

    if effect.oxygen then
        vitals.oxygen = SRPMed.Clamp((vitals.oxygen or 98) + math.floor(effect.oxygen * power), 0, 100)
    end
    if effect.bloodVolume then
        vitals.bloodVolume = SRPMed.Clamp((vitals.bloodVolume or 100) + math.floor(effect.bloodVolume * power), 0, 100)
    end
    if effect.heartRate then
        vitals.heartRate = SRPMed.Clamp((vitals.heartRate or 78) + math.floor(effect.heartRate * power), 0, 190)
    end
    if effect.consciousness then
        vitals.consciousness = SRPMed.Clamp((vitals.consciousness or 100) + math.floor(effect.consciousness * power), 0, 100)
    end

    return injury, vitals
end
