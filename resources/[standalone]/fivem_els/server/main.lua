local vehicleStates = {}

local function normalizeState(state)
    return {
        lights = tonumber(state.lights) or 1,
        siren = state.siren == true,
        tone = tonumber(state.tone) or 1,
        manual = state.manual == true,
        airhorn = state.airhorn == true
    }
end

RegisterNetEvent('fivem_els:server:setState', function(netId, state)
    if type(netId) ~= 'number' or type(state) ~= 'table' then
        return
    end

    local normalized = normalizeState(state)

    if normalized.lights <= 1 and not normalized.siren and not normalized.manual and not normalized.airhorn then
        vehicleStates[netId] = nil
    else
        vehicleStates[netId] = normalized
    end

    TriggerClientEvent('fivem_els:client:applyState', -1, netId, normalized)
end)

RegisterNetEvent('fivem_els:server:requestStates', function()
    TriggerClientEvent('fivem_els:client:hydrateStates', source, vehicleStates)
end)

RegisterNetEvent('fivem_els:server:clearState', function(netId)
    if type(netId) ~= 'number' then
        return
    end

    vehicleStates[netId] = nil
    TriggerClientEvent('fivem_els:client:clearState', -1, netId)
end)
