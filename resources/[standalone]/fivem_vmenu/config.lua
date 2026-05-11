Config = {}

Config.Command = 'vmenu'
Config.OpenKey = 'V'
Config.RequireAce = false
Config.AcePermission = 'fivem_vmenu.use'
Config.DeleteRadius = 8.0
Config.SpawnInsideVehicle = true
Config.ReplaceCurrentVehicle = false

Config.VehicleCategories = {
    {
        label = 'Emergency',
        vehicles = {
            { label = 'Police Cruiser', model = 'police' },
            { label = 'Police Buffalo', model = 'police2' },
            { label = 'Sheriff Cruiser', model = 'sheriff' },
            { label = 'Ambulance', model = 'ambulance' },
            { label = 'Fire Truck', model = 'firetruk' }
        }
    },
    {
        label = 'Sports',
        vehicles = {
            { label = 'Adder', model = 'adder' },
            { label = 'Comet S2', model = 'comet6' },
            { label = 'Elegy RH8', model = 'elegy2' },
            { label = 'Jester RR', model = 'jester4' }
        }
    },
    {
        label = 'Utility',
        vehicles = {
            { label = 'Baller', model = 'baller' },
            { label = 'Dubsta', model = 'dubsta' },
            { label = 'Sultan', model = 'sultan' },
            { label = 'Tow Truck', model = 'towtruck' }
        }
    }
}

Config.PlayerModels = {
    { label = 'Freemode Male', model = 'mp_m_freemode_01' },
    { label = 'Freemode Female', model = 'mp_f_freemode_01' },
    { label = 'Police Officer', model = 's_m_y_cop_01' },
    { label = 'Paramedic', model = 's_m_m_paramedic_01' },
    { label = 'Firefighter', model = 's_m_y_fireman_01' }
}

Config.QuickOutfits = {
    {
        label = 'Casual',
        components = {
            { id = 3, drawable = 0, texture = 0 },
            { id = 4, drawable = 1, texture = 0 },
            { id = 6, drawable = 1, texture = 0 },
            { id = 8, drawable = 15, texture = 0 },
            { id = 11, drawable = 1, texture = 0 }
        }
    },
    {
        label = 'Police Duty',
        components = {
            { id = 3, drawable = 30, texture = 0 },
            { id = 4, drawable = 35, texture = 0 },
            { id = 6, drawable = 25, texture = 0 },
            { id = 8, drawable = 58, texture = 0 },
            { id = 11, drawable = 55, texture = 0 }
        }
    }
}

Config.VehicleColors = {
    { label = 'Black', primary = 0, secondary = 0 },
    { label = 'White', primary = 111, secondary = 111 },
    { label = 'Red', primary = 27, secondary = 27 },
    { label = 'Blue', primary = 64, secondary = 64 },
    { label = 'Yellow', primary = 89, secondary = 89 },
    { label = 'Green', primary = 55, secondary = 55 }
}
