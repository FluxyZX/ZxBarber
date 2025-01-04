ESX = exports["es_extended"]:getSharedObject()

local listPlaceTake = {}

ESX.RegisterServerCallback("check_place_enable", function(source, cb, chair)
    local enable = true
    for k, v in pairs(listPlaceTake) do
        if v == chair then
            enable = false
        end
    end
    cb(enable)
end)

ESX.RegisterServerCallback("pay", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= Config.Price then
        xPlayer.removeMoney(Config.Price)
        cb(true)
    else
        cb(false)
    end
end)



RegisterServerEvent("get_place")
AddEventHandler("get_place", function(chair)
    table.insert(listPlaceTake, chair)
end)

RegisterServerEvent("remove_place")
AddEventHandler("remove_place", function(chair)
    for k, v in pairs(listPlaceTake) do
        if v == chair then
            table.remove(listPlaceTake, k)
        end
    end
end)
