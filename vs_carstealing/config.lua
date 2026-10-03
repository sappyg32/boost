Config = {}

Config.Lang = 'en'

Config.Bridge = {
    Notification = "ESX", -- Supports: QB, ESX, OKOK, OX, mythic and CUSTOM
    MiniGame = 'path' --  path, spot and math
}

Config.UseInteract = false --(Soon more info 😍)
Config.PoliceJob = 'police'
Config.PoliceJobs = 0

Config.Wait = {
    Found = 10000,
    Cooldown = 6000,
    WhenPlayerCanGoSell = 6000
}

Config.Item = { -- Only use this if you require the user to have the item
    UseItem = false,
    DeleteItem = false
}

Config.Payment = {
    type = 'black_money',
    min = 10000,
    max = 100000
}

Config.Stealing_Cars = {
    Ped = {
        Ped = 'a_m_m_soucent_01',
        Loc = vector4(499.5712, -1959.1184, 24.8266, 132.5988),
        Blip = { -- Map marker for the mission giver
            Sprite = 480, -- 480 = the generic person marker; swap for any blip sprite id you prefer
            Colour = 5, -- 5 = yellow
            Scale = 1.0,
            ShortRange = true -- Set to false to keep the marker visible from anywhere on the map
        },
        Animation = {
            dict = "amb@world_human_hang_out_street@female_arms_crossed@base",
            lib = "base"
        }
    },
    Blip = { -- Styling of the search radius that is drawn while a theft is active
        Scale = 1.0,
        Colour = 1, -- Blip colour of the radius circle
        Alpha = 65, -- Opacity of the radius circle (0 - 255)
        Flash = true, -- Set to false for a steady circle instead of a pulsing one
        ShowOnMap = true -- true = radius is drawn on the minimap / pause map, false = world only
    },
    SearchRadius = 150.0, -- Radius (in metres) of the search area around the target zone. No blip points at the zone or the car - the radius is the only visual, and it disappears as soon as the theft ends.
    ShowZoneMarker = true, -- Adds a beam marker at the centre of the search zone so the area is easy to spot
    ZoneMarker = {
        Sprite = 1, -- 1 = plain dot, 161 = coloured circle
        Colour = 1,
        Scale = 1.2,
        ShortRange = false
    },
    VehList = {
        'sultan',
        'sultanrs',
        'adder',
        'dubsta3',
	'comet2',
	'kuruma',
	'baller2'
    },
    CarLocalisations = {
        [0] = {
            veh_location = vector3(362.5755, -1901.0297, 24.8006),
            scanner_local = {
                [0] = vector3(356.6270, -1896.4694, 24.8007),
            },
            heading = 225.1943
        },
        [1] = {
            veh_location = vector3(354.2261, 438.2636, 146.3904),
            scanner_local = {
                [0] = vector3(346.3746, 440.3703, 147.8711),
                [1] = vector3(330.0071, 442.1160, 145.2287)
            },
            heading = 295.2698
        },
        [2] = {
            veh_location = vector3(-564.0890, -446.8748, 33.5037),
            scanner_local = {
                [0] = vector3(-528.6183, -435.5323, 34.3612),
                [1] = vector3(-505.1220, -442.5299, 34.4815)
            },
            heading = 270.6159
        },
        [3] = {
            veh_location = vector3(-113.6040, -326.8205, 34.7465),
            scanner_local = {
                [0] = vector3(-115.5734, -372.6852, 38.1231),
                [1] = vector3(-46.2218, -391.7847, 38.1579)
            },
            heading = 162.4536
        }
    },
    CarDeposit = {
        [0] = vector4(125.9712, -2203.2930, 6.0333, 359.5962),
        [1] = vector4(89.7125, -1745.3871, 30.0871, 312.7146),
        [2] = vector4(455.0675, -1699.3125, 29.3873, 328.6909),
        [3] = vector4(483.5880, -1312.2823, 29.2090, 289.7550)
    }
}

Config.Language = {
    ['en'] = {
        BlipName = 'Vehicle Key Signal',
        OpenMinigame = 'Hack Key Signal',
        TakeMission = 'Do Mission',
        SuccessOpen = 'You successfuly opened the vehicle. You have 5 minutes to run away from cops!',
        GoAndFind = 'Go to the radius and find me the vehicle!',
        Blip = 'Stolen Car',
        SellCar = 'Talk with pedro',
        RewardInfo = 'Hey greate work! Here is your payment for this job {REWARD}$. Come back later we might have another job for you!',
        NoMuchPd = 'Hey men there is not much cops out there cant do it.',
        CarBuy = "Car Buyer",
        NoItem = 'You don`t have the required item!',
        LostGame = 'You did it wrong! Run away as cops gone be here soon!',
        Cancelled = 'Theft cancelled! The job is off the table.',
        ContractBlip = 'Contracts',
        ZoneMarker = 'Search Area'
    },
    ['pl'] = {
        BlipName = 'Sygnał kluczyka pojazdu',
        OpenMinigame = 'Zhakuj sygnał kluczyka',
        TakeMission = 'Weź misję',
        SuccessOpen = 'Udało ci się otworzyć pojazd. Masz 5 minut, aby uciec przed policją!',
        GoAndFind = 'Idź do wyznaczonego obszaru i znajdź pojazd!',
        Blip = 'Skradziony samochód',
        SellCar = 'Porozmawiaj z Pedro',
        RewardInfo = 'Świetna robota! Oto twoja zapłata za to zadanie {REWARD}$. Wróć później, możemy mieć dla ciebie kolejne zlecenie!',
        NoMuchPd = 'Hej, nie ma zbyt wielu policjantów, nie dam rady tego zrobić.',
        CarBuy = "Kupujący",
        NoItem = 'Nie posiadasz urządzenia!',
        LostGame = 'Zrobiłeś to źle! Uciekaj, bo gliny zaraz tu będą!',
        Cancelled = 'Kradzież anulowana! Zlecenie przepadło.',
        ContractBlip = 'Zlecenia',
        ZoneMarker = 'Obszar poszukiwań'
    }      
}

-- Functions

function AlertPD(veh, torf)
    Core.Notification('[ALERT] Car Stealing in progress!')
end

function GetFramework()
    if GetResourceState('qb-core'):find('started') then
        QBCore = exports['qb-core']:GetCoreObject()
        return 'QB'
    elseif GetResourceState('es_extended'):find('started') then
        ESX = exports['es_extended']:getSharedObject()
        return 'ESX'
    elseif GetResourceState('qbx_core'):find('started') then
        QBX = exports['es_extended']:getSharedObject()
        return 'QBOX'
    else
        return 'STANDALONE'
    end
end
