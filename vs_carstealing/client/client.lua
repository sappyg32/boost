Core = GetLib()
local cooldown = false
local sellingcar = false
local spawnedPed
local spawned_car
local BlipForCar
local spawnedPedd
local BlipForPed
CarCoords = vec3(0,0,0)

-- Search radius state. The radius only exists while a theft is active and is always
-- torn down through ClearSearchRadius() so it can never be left behind on the map.
local SearchRadiusBlip = nil
local SearchRadiusHandle = nil
local ZoneMarkerHandle = nil
local theftActive = false

function ClearSearchRadius()
    if SearchRadiusBlip then
        if DoesBlipExist(SearchRadiusBlip) then
            RemoveBlip(SearchRadiusBlip)
        end
        SearchRadiusBlip = nil
    end
    SearchRadiusHandle = nil
end

function CreateSearchRadius(coords)
    ClearSearchRadius()
    if not coords then return end

    SearchRadiusHandle = AddBlipForRadius(coords.x, coords.y, coords.z, Config.Stealing_Cars.SearchRadius)
    local area = SearchRadiusHandle

    SetBlipColour(area, Config.Stealing_Cars.Blip.Colour)
    SetBlipAlpha(area, Config.Stealing_Cars.Blip.Alpha)
    SetBlipSprite(area, 1)
    SetBlipDisplay(area, 4)
    SetBlipScale(area, Config.Stealing_Cars.Blip.Scale)
    SetBlipAsShortRange(area, false) -- a radius must be a long-range blip to be drawn at all
    if Config.Stealing_Cars.Blip.ShowOnMap then
        SetBlipHiddenOnLegend(area, false)
    else
        -- Keeps the circle off the minimap / pause map while still drawing it in the world.
        SetBlipHiddenOnLegend(area, true)
    end
    SetBlipHighDetail(area, true)
    SearchRadiusBlip = area

    -- Keep the radius alive in the world for as long as the theft is running, and pulse it
    -- so the search area stays readable at night and through buildings.
    CreateThread(function()
        local pulses = 0
        while theftActive and SearchRadiusBlip and DoesBlipExist(SearchRadiusBlip) do
            if Config.Stealing_Cars.Blip.Flash then
                if pulses % 2 == 0 then
                    SetBlipAlpha(SearchRadiusBlip, Config.Stealing_Cars.Blip.Alpha)
                else
                    SetBlipAlpha(SearchRadiusBlip, math.max(25, math.floor(Config.Stealing_Cars.Blip.Alpha / 2)))
                end
                pulses = pulses + 1
            end
            Wait(750)
        end
        ClearSearchRadius()
    end)
end

-- Optional ground-level beam over the centre of the search zone, so the area can be found
-- even when the player is looking straight down a street. Purely visual, removed with the radius.
function ClearZoneMarker()
    if ZoneMarkerHandle and DoesEntityExist(ZoneMarkerHandle) then
        RemoveBlip(ZoneMarkerHandle)
    end
    ZoneMarkerHandle = nil
end

function CreateZoneMarker(coords)
    ClearZoneMarker()
    if not coords then return end

    local marker = Config.Stealing_Cars.ZoneMarker
    ZoneMarkerHandle = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(ZoneMarkerHandle, marker.Sprite)
    SetBlipColour(ZoneMarkerHandle, marker.Colour)
    SetBlipScale(ZoneMarkerHandle, marker.Scale)
    SetBlipAsShortRange(ZoneMarkerHandle, marker.ShortRange)
    SetBlipHighDetail(ZoneMarkerHandle, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Language[Config.Lang].ZoneMarker)
    EndTextCommandSetBlipName(ZoneMarkerHandle)
end

-- Shared end-of-theft cleanup. Used by a finished/failed hack and by the Backspace cancel.
function EndTheft(cancelled)
    theftActive = false
    ClearSearchRadius()
    ClearZoneMarker()

    if spawned_car and DoesEntityExist(spawned_car) then
        SetEntityAsMissionEntity(spawned_car, true, true)
        DeleteVehicle(spawned_car)
        spawned_car = nil
    end

    if spawnedPedd and DoesEntityExist(spawnedPedd) then
        DeleteEntity(spawnedPedd)
        spawnedPedd = nil
    end

    sellingcar = false
    CarCoords = vec3(0, 0, 0)

    TriggerEvent('vs_carstealing:rmblip') -- clears any active scanner blip
    TriggerServerEvent('vs_carstealing:rmscanner')

    if cancelled then
        TriggerServerEvent('vs_carstealing:cancel')
        Core.Notification(Config.Language[Config.Lang].Cancelled)
    end

    RemoveCoolDown()
end

CreateThread(function()
    local model = Config.Stealing_Cars.Ped.Ped
    RequestModel(model)
	while not HasModelLoaded(model) do
		Citizen.Wait(50)
	end
    spawnedPed = CreatePed(0, model, Config.Stealing_Cars.Ped.Loc.x, Config.Stealing_Cars.Ped.Loc.y, Config.Stealing_Cars.Ped.Loc.z-0.99, Config.Stealing_Cars.Ped.Loc.w, false, true)

    if Config.UseInteract then
        exports.vs_interactions:addLocalEntity({
            entity = spawnedPed,
            icon = "fa-solid fa-user-ninja",
            distance = 2.0,
            options = {
                {
                    label = Config.Language[Config.Lang].TakeMission,
                    type = 'function',
                    icon = 'fa-solid fa-location-dot',
                    onSelect = function()  
                        Core.TriggerCallback('vs_carstealing:checkitem', function(data) 
                            if data then
                                Core.TriggerCallback('vs_carstealing:getpd', function(data) 
                                    if data >= Config.PoliceJobs then
                                        local RandomLocal = math.random(0,#Config.Stealing_Cars.CarLocalisations)
                                        cooldown = true
                                        Core.Notification(Config.Language[Config.Lang].GoAndFind)
                                        TriggerServerEvent('vs_carstealing:scanner', true)
                                        local Randomscanner_local = math.random(0,#Config.Stealing_Cars.CarLocalisations[RandomLocal].scanner_local)
                                        SetupScanner(Config.Stealing_Cars.CarLocalisations[RandomLocal].scanner_local[Randomscanner_local], RandomLocal)
                                    else
                                        Core.Notification(Config.Language[Config.Lang].NoMuchPd)
                                    end
                                end)
                            else
                                Core.Notification(Config.Language[Config.Lang].NoItem)
                            end
                        end)
                    end,
                    canInteract = function()
                        if not cooldown then
                            return true
                        end
            
                        return false
                    end
                },
            }
        })
    else
        exports.ox_target:addLocalEntity(spawnedPed, {
            {
                icon = "fa-solid fa-user-ninja",
                label = Config.Language[Config.Lang].TakeMission,
                onSelect = function()    
                    Core.TriggerCallback('vs_carstealing:checkitem', function(data) 
                        if data then
                            Core.TriggerCallback('vs_carstealing:getpd', function(data) 
                                if data >= Config.PoliceJobs then
                                    local RandomLocal = math.random(0,#Config.Stealing_Cars.CarLocalisations)
                                    cooldown = true
                                    Core.Notification(Config.Language[Config.Lang].GoAndFind)
                                    TriggerServerEvent('vs_carstealing:scanner', true)
                                    local Randomscanner_local = math.random(0,#Config.Stealing_Cars.CarLocalisations[RandomLocal].scanner_local)
                                    SetupScanner(Config.Stealing_Cars.CarLocalisations[RandomLocal].scanner_local[Randomscanner_local], RandomLocal)
                                else
                                    Core.Notification(Config.Language[Config.Lang].NoMuchPd)
                                end
                            end)
                        else
                            Core.Notification(Config.Language[Config.Lang].NoItem)
                        end
                    end)
                end,
                distance = 2.0,
                canInteract = function(entity)
                    if not cooldown then
                        return true
                    end
        
                    return false
                end
            }
        })
    end

    -- Map marker so players can find the mission giver.
    local pedBlip = AddBlipForCoord(Config.Stealing_Cars.Ped.Loc.x, Config.Stealing_Cars.Ped.Loc.y, Config.Stealing_Cars.Ped.Loc.z)
    SetBlipSprite(pedBlip, Config.Stealing_Cars.Ped.Blip.Sprite)
    SetBlipColour(pedBlip, Config.Stealing_Cars.Ped.Blip.Colour)
    SetBlipScale(pedBlip, Config.Stealing_Cars.Ped.Blip.Scale)
    SetBlipAsShortRange(pedBlip, Config.Stealing_Cars.Ped.Blip.ShortRange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Language[Config.Lang].ContractBlip)
    EndTextCommandSetBlipName(pedBlip)
    BlipForPed = pedBlip

    SetAmbientVoiceName(spawnedPed, 'AMMUCITY') -- Sets Voice Type
    FreezeEntityPosition(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    SetEntityInvincible(spawnedPed, true)
    RequestAnimDict(Config.Stealing_Cars.Ped.Animation.dict)
    while (not HasAnimDictLoaded(Config.Stealing_Cars.Ped.Animation.dict)) do Citizen.Wait(0) end
    TaskPlayAnim(spawnedPed,Config.Stealing_Cars.Ped.Animation.dict,Config.Stealing_Cars.Ped.Animation.lib,1.0,-1.0, -1, 1, 1, true, true, true)
end)

function SetupScanner(vec, rmd)
    local RandomLocal = math.random(1,#Config.Stealing_Cars.VehList)
    local ModelHash = Config.Stealing_Cars.VehList[RandomLocal]
    
    if not IsModelInCdimage(ModelHash) then return end
        RequestModel(ModelHash) -- Request the model
        while not HasModelLoaded(ModelHash) do -- Waits for the model to load
        Wait(0)
    end
    CarCoords = Config.Stealing_Cars.CarLocalisations[rmd].veh_location
    spawned_car = CreateVehicle(GetHashKey(ModelHash), Config.Stealing_Cars.CarLocalisations[rmd].veh_location, Config.Stealing_Cars.CarLocalisations[rmd].heading, true, false)
    SetVehicleOnGroundProperly(spawned_car)
    SetVehicleFixed(spawned_car)
    SetVehicleDeformationFixed(spawned_car)
    SetVehicleEngineOn(spawned_car, false, false)
    SetVehicleDoorsLocked(spawned_car, 2)
    SetModelAsNoLongerNeeded(ModelHash)

    -- Radius first, then the vehicle: the old bug was calling this before CarCoords was set,
    -- which created the circle at 0,0,0. Never trust a zero vector for a mission zone.
    if not CarCoords or (CarCoords.x == 0 and CarCoords.y == 0) then
        print('[vs_carstealing] Search radius skipped: target zone coords are missing')
    else
        CreateSearchRadius(CarCoords)
        if Config.Stealing_Cars.ShowZoneMarker then
            CreateZoneMarker(CarCoords)
        end
    end
    theftActive = true

    SetupDigiScanner(vec, {
        event = FoundX,
        isAction = true,
        args = {},
        -- No marker blip: the search radius is the only thing guiding the player to the zone.
        blip = false,
        interact = {
            interactKey = 38,
            interactMessage = Config.Language[Config.Lang].OpenMinigame,
        }
    })
end

function FoundX()
    StartMinigame(function(success)
        if success then
            SetNuiFocus(false, false)
            Core.Notification(Config.Language[Config.Lang].SuccessOpen)
            SetVehicleDoorsLocked(spawned_car, 0)
            theftActive = false
            ClearSearchRadius() -- the car is open, the searching phase is over
            Citizen.Wait(Config.Wait.Found)
            TriggerServerEvent('vs_carstealing:SendToPolice', spawned_car, true)
            Citizen.Wait(Config.Wait.WhenPlayerCanGoSell)
            TriggerEvent('vs_carstealing:rmblip')
            SellVehicle()
        else
            SetNuiFocus(false, false)
            Core.Notification(Config.Language[Config.Lang].LostGame)
            Citizen.Wait(Config.Wait.Found)
            TriggerServerEvent('vs_carstealing:SendToPolice', spawned_car, true)
            Citizen.Wait(Config.Wait.WhenPlayerCanGoSell)
            TriggerEvent('vs_carstealing:rmblip')
            TriggerServerEvent('vs_carstealing:rmscanner')
            theftActive = false
            ClearSearchRadius()
            RemoveCoolDown()
        end
    end, Config.Bridge.MiniGame)
end

function SellVehicle()
    -- Generate a random location for car deposit
    local RandomLocal = math.random(0,#Config.Stealing_Cars.CarDeposit)
    local carDepositLocation = Config.Stealing_Cars.CarDeposit[RandomLocal]

    -- Add a blip for the Car Buyer
    local carBuyerBlip = AddBlipForCoord(carDepositLocation.x, carDepositLocation.y, carDepositLocation.z)
    SetBlipSprite(carBuyerBlip, 225)  -- Set an appropriate icon for the car buyer
    SetBlipColour(carBuyerBlip, 1)    -- You can set the color here (1 = red, you can change this)
    SetBlipScale(carBuyerBlip, 0.8)   -- Adjust blip size
    SetBlipAsShortRange(carBuyerBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Language[Config.Lang].CarBuy)
    EndTextCommandSetBlipName(carBuyerBlip)

    -- Set new waypoint to the car deposit location
    SetNewWaypoint(carDepositLocation.x, carDepositLocation.y)

    -- Ped model and animation
    local model = Config.Stealing_Cars.Ped.Ped
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(50)
    end

    sellingcar = true

    -- Create ped at the car deposit location
    spawnedPedd = CreatePed(0, model, carDepositLocation.x, carDepositLocation.y, carDepositLocation.z-0.99, carDepositLocation.w, false, true)
    SetAmbientVoiceName(spawnedPedd, 'AMMUCITY') -- Sets Voice Type
    FreezeEntityPosition(spawnedPedd, true)
    SetBlockingOfNonTemporaryEvents(spawnedPedd, true)
    SetEntityInvincible(spawnedPedd, true)

    -- Request and play the animation
    RequestAnimDict(Config.Stealing_Cars.Ped.Animation.dict)
    while not HasAnimDictLoaded(Config.Stealing_Cars.Ped.Animation.dict) do 
        Citizen.Wait(0) 
    end
    TaskPlayAnim(spawnedPedd, Config.Stealing_Cars.Ped.Animation.dict, Config.Stealing_Cars.Ped.Animation.lib, 1.0, -1.0, -1, 1, 1, true, true, true)

    if Config.UseInteract then
        exports.vs_interactions:addLocalEntity({
            entity = spawnedPedd,
            icon = "fa-solid fa-user-ninja",
            distance = 2.0,
            options = {
                {
                    label = Config.Language[Config.Lang].SellCar,
                    type = 'function',
                    icon = 'fa-solid fa-location-dot',
                    onSelect = function()    
                        TriggerServerEvent('vs_carstealing:scanner', false)
                        Citizen.Wait(1000)

                        -- Remove the blip after interaction
                        if DoesBlipExist(carBuyerBlip) then
                            RemoveBlip(carBuyerBlip)
                        end

                        FreezeEntityPosition(spawnedPedd, false)
                        SetBlockingOfNonTemporaryEvents(spawnedPedd, false)
                        SetEntityInvincible(spawnedPedd, false)
                        TaskVehicleDriveWander(spawnedPedd, spawned_car, 60.0, 316)
                        sellingcar = false
                        RemoveCoolDown()
                    end,
                    canInteract = function()
                        if cooldown and sellingcar then
                            return true
                        end
                        return false
                    end
                },
            }
        })
    else
        exports.ox_target:addLocalEntity(spawnedPedd, {
            {
                icon = "fa-solid fa-user-ninja",
                label = Config.Language[Config.Lang].SellCar,
                onSelect = function()
                    TriggerServerEvent('vs_carstealing:scanner', false)
                    Citizen.Wait(1000)

                    -- Remove the blip after interaction
                    if DoesBlipExist(carBuyerBlip) then
                        RemoveBlip(carBuyerBlip)
                    end

                    FreezeEntityPosition(spawnedPedd, false)
                    SetBlockingOfNonTemporaryEvents(spawnedPedd, false)
                    SetEntityInvincible(spawnedPedd, false)
                    TaskVehicleDriveWander(spawnedPedd, spawned_car, 60.0, 316)
                    sellingcar = false
                    RemoveCoolDown()
                end,
                distance = 2.0,
                canInteract = function(entity)
                    if cooldown and sellingcar then
                        return true
                    end
                    return false
                end
            }
        })
    end
end

function RemoveCoolDown()
    Citizen.Wait(Config.Wait.Cooldown)
    cooldown = false
    sellingcar = false
end

-- Backspace: abandon an active theft at any point (searching, hacking, or delivering).
CreateThread(function()
    while true do
        local sleep = 1000
        if theftActive then
            sleep = 0
            if IsControlJustPressed(0, 194) then -- 194 = INPUT_FRONTEND_DELETE / Backspace
                EndTheft(true)
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('vs_carstealing:PDTracker', function(ped_thing, addorremove)
    if Core.GetJob() == Config.PoliceJob then
        BlipForCar = AddBlipForEntity(ped_thing)
        SetBlipSprite(BlipForCar, 56)
        SetBlipDisplay(BlipForCar, 56)
        SetBlipScale(BlipForCar, 1.0)
        SetBlipColour(BlipForCar, 60)
        SetBlipAsShortRange(BlipForCar, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Language[Config.Lang].Blip)
        EndTextCommandSetBlipName(BlipForCar)
        Citizen.Wait(Config.Wait.WhenPlayerCanGoSell)
        RemoveBlip(BlipForCar)
    end
end)
