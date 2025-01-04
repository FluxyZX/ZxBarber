ESX = exports["es_extended"]:getSharedObject()

local PositionList = {
    vector3(136.39, -1707.90, 29.29), 
    vector3(-1282.87, -1116.36, 6.99),
    vector3(1930.81, 3730.30, 32.84), 
    vector3(1213.63, -472.29, 66.20),
    vector3(-32.58, -153.39, 57.07), 
    vector3(-277.49, 6228.49, 31.69),
    vector3(-814.94, -183.82, 37.56)
}


local rgbColorList = {
    {28, 31, 33}, {39, 42, 44}, {49, 46, 44}, {53, 38, 28}, {75, 50, 31}, {92, 59, 36}, {109, 76, 53}, {107, 80, 59},
    {118, 92, 69}, {127, 104, 78}, {153, 129, 93}, {167, 147, 105}, {175, 156, 112}, {187, 160, 99}, {214, 185, 123},
    {218, 195, 142}, {159, 127, 89}, {132, 80, 57}, {104, 43, 31}, {97, 18, 12}, {100, 15, 10}, {124, 20, 15},
    {160, 46, 25}, {182, 75, 40}, {162, 80, 47}, {170, 78, 43}, {98, 98, 98}, {128, 128, 128}, {170, 170, 170},
    {197, 197, 197}, {70, 57, 85}, {90, 63, 107}, {118, 60, 118}, {237, 116, 227}, {235, 75, 147}, {242, 153, 188},
    {4, 149, 158}, {2, 95, 134}, {2, 57, 116}, {63, 161, 106}, {33, 124, 97}, {24, 92, 85}, {182, 192, 52},
    {112, 169, 11}, {67, 157, 19}, {220, 184, 87}, {229, 177, 3}, {230, 145, 2}, {242, 136, 49}, {251, 128, 87},
    {226, 139, 88}, {209, 89, 60}, {206, 49, 32}, {173, 9, 3}, {136, 3, 2}, {31, 24, 20}, {41, 31, 25},
    {46, 34, 27}, {55, 41, 30}, {46, 34, 24}, {35, 27, 21}, {2, 2, 2}, {112, 108, 102}, {157, 122, 80}
}


local timout = false

local function setTimout(time)
    timout = true
    Citizen.SetTimeout(time, function()
        timout = false
    end)
end


local function loadSkin()
    ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin, jobSkin)
        TriggerEvent("skinchanger:loadSkin", skin)
    end)
end

local function saveSkin()
    TriggerEvent('skinchanger:getSkin', function(skin)
        TriggerServerEvent('esx_skin:save', skin)
    end)
end

local function helpNotification(msg)
    SetTextComponentFormat("STRING")
    AddTextComponentString(msg)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

local sit = false
local cam = nil
local ped = nil
local scissor = nil
local chairSelected = nil

local function requestModel(model)
    RequestModel(model)
    repeat Wait(0) until HasModelLoaded(model)
end
local function requestAnimDict(dict)
    RequestAnimDict(dict)
    repeat Wait(0) until HasAnimDictLoaded(dict)
end

local function getOffsetCoords(coords, heading, offset)
    local headingRadians = math.rad(heading)
    local offsetDistance = offset
    local directionVector = vector3(-math.sin(headingRadians) * offsetDistance, math.cos(headingRadians) * offsetDistance, 0.0)
    local offsetCoords = coords + directionVector
    return offsetCoords
end

local function CreateCamInFrontOfHeadPlayer(coords, heading)
    local camCoords = getOffsetCoords(coords, heading, -0.8)
    local camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(camera, camCoords.x, camCoords.y, camCoords.z + 1.1)
    SetCamRot(camera, 0.0, 0.0, heading, 2)
    SetCamActive(camera, true)
    RenderScriptCams(true, false, 1, true, true)
    return camera
end

-- Marker 

Citizen.CreateThread(function()
    while true do
        local interval = 1000
        local playerPos = GetEntityCoords(PlayerPedId())

        for k,v in pairs(Config.Position.barber) do
            local dist = #(v.pos - playerPos)

            if dist <= 10.0 then
                interval = 0
                DrawMarker(Config.Marker.Type, v.pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.1, 1.1, 0.5, Config.Marker.ColorR, Config.Marker.ColorG, Config.Marker.ColorB, 180, 0, 1, 2, 0, false, false, 0)
            end
        end
        
        Citizen.Wait(interval)
    end
end)




local function stopHairCut()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)

    ClearPedTasks(playerPed)
    FreezeEntityPosition(playerPed, false)
    RenderScriptCams(false, false, 1, true, true)
    DestroyCam(cam, true)
    DeleteEntity(ped)
    DeleteObject(scissor)
    DoScreenFadeIn(250)
end


local resetSkin = true
local hairstyles = {}
local hairIndex = 1
local hairColors = {1,1, 0.0}
local beards = {}
local beardsIndex = 1
local beardOpacity = 1
local breadColors = {1,1, 0.0}
local eyebrows = {}
local eyebrowsIndex = 1
local eyebrowsOpacity = 0.0
local eyebrowsColors = {1,1, 0.0}

local function generateList(startIndex, endIndex, targetTable)
    for i = startIndex, endIndex - 1 do
        table.insert(targetTable, i)
    end
end

local function getLists()
    local playerPed = PlayerPedId()
    local hairStylesCount = GetNumberOfPedDrawableVariations(playerPed, 2)
    local beardsCount = GetNumHeadOverlayValues(1)
    local eyebrowsCount = GetNumHeadOverlayValues(2)
    generateList(0, hairStylesCount, hairstyles)
    generateList(0, beardsCount, beards)
    generateList(0, eyebrowsCount, eyebrows)
end

local open = false

local function closeMenu()
    RageUI.CloseAll()  
    open = false  
    stopHairCut()

    if resetSkin then
        loadSkin()
    else
        saveSkin()
        resetSkin = true
    end

    hairIndex = 1
    hairColors = {1, 1, 0.0}
    beardsIndex = 1
    beardOpacity = 1
    breadColors = {1, 1, 0.0}
    eyebrowsIndex = 1
    eyebrowsOpacity = 0.0
    chairSelected = nil
    sit = false
end






local menuBarber = RageUI.CreateMenu("", "Barber")


menuBarber.Closed = function()
    closeMenu() 
end



function RageUI.PoolMenus:ZxBarber()
    menuBarber.EnableMouse = true
    menuBarber:IsVisible(function(Items)

        Items:AddList("Coiffure", hairstyles, string.format("#%s", hairstyles), hairIndex, nil, { IsDisabled = false }, function(Index, onSelected, onListChange)
            if (onListChange) then
                hairIndex = Index
                TriggerEvent('skinchanger:change', "hair_1", hairIndex)
            end
        end)
        Items:AddList("barbe", beards, string.format("#%s", beards), beardsIndex, nil, { IsDisabled = false }, function(Index, onSelected, onListChange)
            if (onListChange) then
                beardsIndex = Index
                TriggerEvent('skinchanger:change', "beard_1", beardsIndex)
                TriggerEvent('skinchanger:change', "beard_2", (beardOpacity * 10) + 0.0)
            end
        end)
        Items:AddList("Sourcils", eyebrows, string.format("#%s", eyebrows), eyebrowsIndex, nil, { IsDisabled = false }, function(Index, onSelected, onListChange)
            if (onListChange) then
                eyebrowsIndex = Index
                TriggerEvent('skinchanger:change', "eyebrows_1", eyebrowsIndex)
                TriggerEvent('skinchanger:change', "eyebrows_2", (eyebrowsOpacity * 10) + 0.0)
            end
        end)
        Items:AddButton("Payer", nil, { RightLabel = string.format("~g~%s$", Config.Price), IsDisabled = false}, function(onSelected)
            if (onSelected) then
                ESX.TriggerServerCallback("pay", function(paid)
                    if paid then
                        resetSkin = false
                        closeMenu()
                        ESX.ShowNotification("Vous avez payé ~g~" .. Config.Price .. "$")
                    else
                        ESX.ShowNotification("Vous n'avez pas assez ~r~d'argent")
                    end
                end)
            end
        end)

    end, function(Panels)
        Items:ColourPanel("Couleur", rgbColorList, hairColors[1], hairColors[2], function(MinimumIndex, CurrentIndex, onColorChange)
            if (onColorChange) then
                CurrentIndex = CurrentIndex
                hairColors[1] = MinimumIndex
                hairColors[2] = CurrentIndex
                TriggerEvent('skinchanger:change', "hair_color_1", CurrentIndex - 1)
                TriggerEvent('skinchanger:change', "hair_color_2", CurrentIndex - 1)
            end
        end, 1)
        Items:PercentagePanel(beardOpacity, "Opacité", "0%", "100%", function(Percentage)
            beardOpacity = Percentage
            TriggerEvent('skinchanger:change', "beard_2", (beardOpacity * 10) + 0.0)
        end, 2)
        Items:ColourPanel("couleur", rgbColorList, breadColors[1], breadColors[2], function(MinimumIndex, CurrentIndex, onColorChange)
            if (onColorChange) then
                CurrentIndex = CurrentIndex
                breadColors[1] = MinimumIndex
                breadColors[2] = CurrentIndex
                TriggerEvent('skinchanger:change', "beard_3", CurrentIndex - 1)
                TriggerEvent('skinchanger:change', "beard_4", CurrentIndex - 1)
            end
        end, 2)
        Items:PercentagePanel(eyebrowsOpacity, "Opacité", "0%", "100%", function(Percentage)
            eyebrowsOpacity = Percentage
            TriggerEvent('skinchanger:change', "eyebrows_2", (eyebrowsOpacity * 10) + 0.0)
        end, 3)
        Items:ColourPanel("couleur", rgbColorList, eyebrowsColors[1], eyebrowsColors[2], function(MinimumIndex, CurrentIndex, onColorChange)
            if (onColorChange) then
                CurrentIndex = CurrentIndex
                eyebrowsColors[1] = MinimumIndex
                eyebrowsColors[2] = CurrentIndex
                TriggerEvent('skinchanger:change', "eyebrows_3", CurrentIndex - 1)
                TriggerEvent('skinchanger:change', "eyebrows_4", CurrentIndex - 1)
                if IsControlJustPressed(0, 178) and open then
                    closeMenu()  
                end
            end
        end, 3)
    end)
end

local function startHairCut()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    if open == false then  
        open = true
        RageUI.Visible(menuBarber, true)
        FreezeEntityPosition(playerPed, true)  

        while open do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 38) then  
                RageUI.Visible(menuBarber, false)  
                open = false  
                FreezeEntityPosition(playerPed, false)  
                break  
            end
        end
    end
end





CreateThread(function()
    while not ESX.PlayerLoaded do
        Wait(500)
    end
    while not (GetEntityModel(PlayerPedId()) == GetHashKey("mp_f_freemode_01") or GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01") or GetEntityModel(PlayerPedId()) == 1885233650 or GetEntityModel(PlayerPedId()) == -1667301416) do
        Wait(500)
    end
    Wait(1000)
    getLists()
    Wait(1000)
end)
CreateThread(function()
    while true do
        local wait = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for k, v in pairs(PositionList) do
            local chairCoords = vector3(v.x, v.y, v.z)
            local distance = #(playerCoords - chairCoords)
            if distance <= 1.5 and not sit and not open and k ~= chairSelected then
                wait = 0
                Visual.Subtitle("Appuyez sur ~b~[E]~s~ pour modifier votre style")
                
                if IsControlJustPressed(0, 38) then
                    setTimout(1000) 
                    startHairCut()  
                end
            end
        end
    
        Citizen.Wait(wait)
    end
end)

    


CreateThread(function()
    for k, v in pairs(Config.BarberShopPositions) do
        local blip = AddBlipForCoord(v.x, v.y, v.z)
        SetBlipSprite(blip, Config.Blip.Sprite)
        SetBlipColour(blip, Config.Blip.Color)
        SetBlipScale(blip, Config.Blip.Scale)
        SetBlipDisplay(blip, Config.Blip.Display)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.Name)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function()
    ESX.PlayerLoaded = true
end)

