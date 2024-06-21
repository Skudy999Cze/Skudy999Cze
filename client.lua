-- client.lua

-- Načtení konfigurace
Config = {}

Config.StealWheelAnimation = {
    dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
    anim = "machinic_loop_mechandplayer",
    time = 5000 -- Délka animace v milisekundách
}

Config.WheelBones = {
    {name = 'wheel_lf', index = 0},
    {name = 'wheel_rf', index = 1},
    {name = 'wheel_lr', index = 4},
    {name = 'wheel_rr', index = 5}
}

local ESX = exports['es_extended']:getSharedObject()
local stolenWheels = {}

RegisterNetEvent('carTheft:stealWheel')
AddEventHandler('carTheft:stealWheel', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = ESX.Game.GetClosestVehicle(coords)

    if DoesEntityExist(vehicle) then
        local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
        stolenWheels[vehicleId] = stolenWheels[vehicleId] or {}

        for _, wheelData in ipairs(Config.WheelBones) do
            if not stolenWheels[vehicleId][wheelData.index] then
                local boneIndex = GetEntityBoneIndexByName(vehicle, wheelData.name)
                if boneIndex ~= -1 then
                    local wheelCoords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
                    if GetDistanceBetweenCoords(coords, wheelCoords, true) < 1.5 then
                        ESX.Streaming.RequestAnimDict(Config.StealWheelAnimation.dict, function()
                            TaskPlayAnim(playerPed, Config.StealWheelAnimation.dict, Config.StealWheelAnimation.anim, 8.0, -8.0, Config.StealWheelAnimation.time, 1, 0, false, false, false)
                        end)
                        Citizen.Wait(Config.StealWheelAnimation.time) -- Wait for animation duration

                        -- Vyfouknutí kola
                        SetVehicleTyreBurst(vehicle, wheelData.index, true, 1000.0)
                        stolenWheels[vehicleId][wheelData.index] = true

                        ClearPedTasksImmediately(playerPed)
                        TriggerServerEvent('carTheft:addItem', 'wheel')
                        TriggerServerEvent('carTheft:notifyPlayers', NetworkGetNetworkIdFromEntity(vehicle), wheelData.index)
                        ESX.ShowNotification('Kolo bylo ukradeno!')

                        -- Dispatch export for cd_dispatch
                        local streetName, crossingRoad = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                        streetName = GetStreetNameFromHashKey(streetName)
                        if crossingRoad ~= 0 then
                            crossingRoad = GetStreetNameFromHashKey(crossingRoad)
                            streetName = streetName .. " and " .. crossingRoad
                        end

                        TriggerEvent('cd_dispatch:AddNotification', {
                            job_table = {'police', 'sasp'}, -- Job(s) that will receive the notification
                            coords = coords,
                            title = 'Krádež kola',
                            message = 'Bylo nahlášeno, že kolo bylo ukradeno z vozidla na ulici ' .. streetName .. '.',
                            flash = 0,
                            unique_id = tostring(math.random(0000000,9999999)),
                            blip = {
                                sprite = 488, -- Blip icon
                                scale = 1.2, -- Blip size
                                colour = 1, -- Blip color
                                flashes = false, -- Blip flashes on minimap
                                text = 'Krádež kola', -- Blip text
                                time = (5*60*1000), -- Blip duration in ms
                            }
                        })
                        return
                    end
                end
            end
        end
        ESX.ShowNotification('Žádné kolo není k dispozici pro krádež nebo již bylo ukradeno!')
    else
        ESX.ShowNotification('Žádné vozidlo poblíž!')
    end
end)

RegisterNetEvent('carTheft:installWheel')
AddEventHandler('carTheft:installWheel', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = ESX.Game.GetClosestVehicle(coords)

    if DoesEntityExist(vehicle) then
        local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
        stolenWheels[vehicleId] = stolenWheels[vehicleId] or {}

        for _, wheelData in ipairs(Config.WheelBones) do
            if stolenWheels[vehicleId][wheelData.index] then
                local boneIndex = GetEntityBoneIndexByName(vehicle, wheelData.name)
                if boneIndex ~= -1 then
                    local wheelCoords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
                    if GetDistanceBetweenCoords(coords, wheelCoords, true) < 1.5 then
                        ESX.Streaming.RequestAnimDict(Config.StealWheelAnimation.dict, function()
                            TaskPlayAnim(playerPed, Config.StealWheelAnimation.dict, Config.StealWheelAnimation.anim, 8.0, -8.0, Config.StealWheelAnimation.time, 1, 0, false, false, false)
                        end)
                        Citizen.Wait(Config.StealWheelAnimation.time) -- Wait for animation duration

                        -- Oprava kola
                        SetVehicleTyreFixed(vehicle, wheelData.index)
                        stolenWheels[vehicleId][wheelData.index] = nil

                        ClearPedTasksImmediately(playerPed)
                        TriggerServerEvent('carTheft:removeItem', 'wheel')
                        TriggerServerEvent('carTheft:notifyPlayers', NetworkGetNetworkIdFromEntity(vehicle), wheelData.index, true)
                        ESX.ShowNotification('Kolo bylo nainstalováno!')
                        return
                    end
                end
            end
        end
        ESX.ShowNotification('Žádné kolo není k dispozici pro instalaci nebo již bylo nainstalováno!')
    else
        ESX.ShowNotification('Žádné vozidlo poblíž!')
    end
end)

RegisterCommand('stealwheel', function()
    TriggerEvent('carTheft:stealWheel')
end, false)

RegisterCommand('installwheel', function()
    TriggerEvent('carTheft:installWheel')
end, false)

RegisterNetEvent('carTheft:updateWheel')
AddEventHandler('carTheft:updateWheel', function(vehicleNetId, wheelIndex, fixed)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        if fixed then
            SetVehicleTyreFixed(vehicle, wheelIndex)
        else
            SetVehicleTyreBurst(vehicle, wheelIndex, true, 1000.0)
        end
    end
end)
