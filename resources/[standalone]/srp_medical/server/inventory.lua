InventoryBridge = InventoryBridge or {}

local function inventoryMode()
    if Config.Inventory ~= 'auto' then return Config.Inventory end
    if GetResourceState('ox_inventory') == 'started' then return 'ox_inventory' end
    if GetResourceState('qb-inventory') == 'started' then return 'qb-inventory' end
    return 'none'
end

function InventoryBridge.HasItem(source, item, amount)
    amount = amount or 1
    if not item or not Config.ItemRequirements.Enabled then return true end
    local mode = inventoryMode()

    if mode == 'ox_inventory' then
        local count = exports.ox_inventory:Search(source, 'count', item)
        return (count or 0) >= amount
    end

    if mode == 'qb-inventory' then
        local player = ServerBridge.GetPlayer(source)
        if player and player.Functions and player.Functions.GetItemByName then
            local invItem = player.Functions.GetItemByName(item)
            return invItem and (invItem.amount or 0) >= amount
        end
    end

    return true
end

function InventoryBridge.RemoveItem(source, item, amount)
    amount = amount or 1
    if not item or not Config.ItemRequirements.Enabled then return true end
    local mode = inventoryMode()

    if mode == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(source, item, amount)
    end

    if mode == 'qb-inventory' then
        local player = ServerBridge.GetPlayer(source)
        if player and player.Functions and player.Functions.RemoveItem then
            return player.Functions.RemoveItem(item, amount)
        end
    end

    return true
end
