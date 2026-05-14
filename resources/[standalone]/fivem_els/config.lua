Config = {}

Config.Command = 'els'
Config.DefaultUiVisible = true
Config.ControlDistance = 85.0
Config.DriverOnly = true
Config.Debug = true
Config.AllowAnyVehicleForTesting = true

Config.Keybinds = {
    toggleUi = 'F6',
    focusUi = 'F7',
    lights = 'Q',
    siren = 'R',
    tone = 'T',
    manual = 'LSHIFT',
    airhorn = 'E'
}

Config.AllowedClasses = {
    [18] = true
}

Config.AllowedModels = {
    -- [`police`] = true,
    -- [`police2`] = true,
    -- [`ambulance`] = true
}

Config.LightStages = {
    {
        label = 'Off',
        extras = {}
    },
    {
        label = 'Stage 1',
        extras = { 1, 2 }
    },
    {
        label = 'Stage 2',
        extras = { 1, 2, 3, 4 }
    },
    {
        label = 'Stage 3',
        extras = { 1, 2, 3, 4, 5, 6 }
    }
}

Config.ManagedExtras = { 1, 2, 3, 4, 5, 6 }

Config.SirenTones = {
    {
        label = 'Wail',
        soundName = 'VEHICLES_HORNS_SIREN_1',
        soundSet = '0'
    },
    {
        label = 'Yelp',
        soundName = 'VEHICLES_HORNS_SIREN_2',
        soundSet = '0'
    },
    {
        label = 'Priority',
        soundName = 'VEHICLES_HORNS_POLICE_WARNING',
        soundSet = '0'
    }
}

Config.ManualTone = {
    label = 'Manual',
    soundName = 'VEHICLES_HORNS_POLICE_WARNING',
    soundSet = '0'
}

Config.Airhorn = {
    label = 'Airhorn',
    soundName = 'SIRENS_AIRHORN',
    soundSet = '0'
}
