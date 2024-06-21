-- server.lua

local ESX = exports['es_extended']:getSharedObject()

RegisterServerEvent('carTheft:addItem')
AddEventHandler('carTheft:addItem', function(itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.addInventoryItem(itemName, 1)
    end
end)

RegisterServerEvent('carTheft:removeItem')
AddEventHandler('carTheft:removeItem', function(itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.removeInventoryItem(itemName, 1)
    end
end)

RegisterServerEvent('carTheft:notifyPlayers')
AddEventHandler('carTheft:notifyPlayers', function(vehicleNetId, wheelIndex, fixed)
    TriggerClientEvent('carTheft:updateWheel', -1, vehicleNetId, wheelIndex, fixed)
end)
