SRPMed = SRPMed or {}

function SRPMed.Debug(message, data)
    if not Config or not Config.Debug then return end
    if data ~= nil then
        print(('[srp_medical] %s %s'):format(message, json.encode(data)))
    else
        print(('[srp_medical] %s'):format(message))
    end
end

function SRPMed.Clamp(value, min, max)
    value = tonumber(value) or 0
    if value < min then return min end
    if value > max then return max end
    return value
end

function SRPMed.TableContains(list, value)
    if not list then return false end
    for _, item in ipairs(list) do
        if item == value then return true end
    end
    return false
end

function SRPMed.CopyTable(source)
    if type(source) ~= 'table' then return source end
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = SRPMed.CopyTable(value)
    end
    return copy
end

function SRPMed.NewId(prefix)
    local rand = math.random(100000, 999999)
    return ('%s_%s_%s'):format(prefix or 'id', os.time(), rand)
end

function SRPMed.Now()
    return os.time()
end

function SRPMed.BodyLabel(part)
    local body = Config.BodyParts and Config.BodyParts[part]
    return body and body.label or part or 'Unknown'
end

function SRPMed.IsHospitalPosition(coords)
    if not Config.AutomatedRecovery or not Config.AutomatedRecovery.Locations then
        return false, nil
    end

    for _, location in ipairs(Config.AutomatedRecovery.Locations) do
        local distance = #(coords - location.coords)
        if distance <= location.radius then
            return true, location
        end
    end

    return false, nil
end

function SRPMed.FormatPatientName(player)
    if not player then return 'Unknown Patient' end
    if player.PlayerData and player.PlayerData.charinfo then
        local charinfo = player.PlayerData.charinfo
        return ('%s %s'):format(charinfo.firstname or 'Unknown', charinfo.lastname or 'Patient')
    end
    if player.name then return player.name end
    return 'Unknown Patient'
end
