MedicalDB = MedicalDB or {}

local function oxReady()
    return GetResourceState('oxmysql') == 'started' and exports.oxmysql
end

local function mysqlGlobalReady()
    return MySQL ~= nil
end

function MedicalDB.Available()
    return oxReady() or mysqlGlobalReady()
end

function MedicalDB.Query(query, params, cb)
    params = params or {}
    if oxReady() then
        exports.oxmysql:query(query, params, cb)
        return
    end
    if mysqlGlobalReady() and MySQL.query then
        MySQL.query(query, params, cb)
        return
    end
    if cb then cb({}) end
end

function MedicalDB.Insert(query, params, cb)
    params = params or {}
    if oxReady() then
        exports.oxmysql:insert(query, params, cb)
        return
    end
    if mysqlGlobalReady() and MySQL.insert then
        MySQL.insert(query, params, cb)
        return
    end
    if cb then cb(nil) end
end

function MedicalDB.Update(query, params, cb)
    params = params or {}
    if oxReady() then
        exports.oxmysql:update(query, params, cb)
        return
    end
    if mysqlGlobalReady() and MySQL.update then
        MySQL.update(query, params, cb)
        return
    end
    if cb then cb(0) end
end

function MedicalDB.SaveState(identifier, state)
    if not MedicalDB.Available() or not identifier or not state then return end
    local payload = json.encode(state)
    MedicalDB.Insert([[
        INSERT INTO player_medical_state (identifier, state_json, stage, updated_at)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE state_json = VALUES(state_json), stage = VALUES(stage), updated_at = NOW()
    ]], { identifier, payload, state.stage })
end

function MedicalDB.LoadState(identifier, cb)
    if not MedicalDB.Available() then cb(nil) return end
    MedicalDB.Query('SELECT state_json FROM player_medical_state WHERE identifier = ? LIMIT 1', { identifier }, function(rows)
        if rows and rows[1] and rows[1].state_json then
            cb(json.decode(rows[1].state_json))
            return
        end
        cb(nil)
    end)
end

function MedicalDB.AddTreatmentLog(identifier, entry)
    if not MedicalDB.Available() then return end
    MedicalDB.Insert([[
        INSERT INTO treatment_logs (identifier, provider_identifier, provider_name, treatment, result, injury_id, body_part, notes, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ]], {
        identifier,
        entry.providerIdentifier,
        entry.providerName,
        entry.treatment,
        entry.result,
        entry.injuryId,
        entry.bodyPart,
        entry.notes
    })
end

function MedicalDB.AddReport(report, cb)
    if not MedicalDB.Available() then
        if cb then cb(nil) end
        return
    end
    MedicalDB.Insert([[
        INSERT INTO medical_reports
        (patient_identifier, patient_name, provider_identifier, provider_name, department, injuries_json, treatments_json, medications_json, destination, outcome, narrative, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ]], {
        report.patientIdentifier,
        report.patientName,
        report.providerIdentifier,
        report.providerName,
        report.department,
        json.encode(report.injuries or {}),
        json.encode(report.treatments or {}),
        json.encode(report.medications or {}),
        report.destination,
        report.outcome,
        report.narrative
    }, cb)
end

function MedicalDB.GetHistory(identifier, cb)
    if not MedicalDB.Available() then cb({}) return end
    MedicalDB.Query([[
        SELECT id, patient_name, provider_name, department, injuries_json, treatments_json, medications_json, destination, outcome, narrative, created_at
        FROM medical_reports
        WHERE patient_identifier = ?
        ORDER BY created_at DESC
        LIMIT 25
    ]], { identifier }, cb)
end

function MedicalDB.GetCertifications(identifier, cb)
    if not MedicalDB.Available() then cb({}) return end
    MedicalDB.Query('SELECT certification, level, granted_by, created_at FROM player_certifications WHERE identifier = ?', { identifier }, cb)
end

function MedicalDB.SetCertification(identifier, cert, level, grantedBy, cb)
    if not MedicalDB.Available() then if cb then cb(0) end return end
    MedicalDB.Insert([[
        INSERT INTO player_certifications (identifier, certification, level, granted_by, created_at)
        VALUES (?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE level = VALUES(level), granted_by = VALUES(granted_by)
    ]], { identifier, cert, level or 1, grantedBy }, cb)
end

function MedicalDB.RemoveCertification(identifier, cert, cb)
    if not MedicalDB.Available() then if cb then cb(0) end return end
    MedicalDB.Update('DELETE FROM player_certifications WHERE identifier = ? AND certification = ?', { identifier, cert }, cb)
end
