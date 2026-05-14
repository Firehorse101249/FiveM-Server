# fivem_vmenu

Custom V menu for player options, vehicle spawning, and vehicle modification.

## Start

Add this to `server.cfg`:

```cfg
ensure fivem_vmenu
```

The menu opens with `V` by default. Players can also use `/vmenu`.

## Configure

Edit `config.lua` to change:

- `Config.OpenKey` - default keybind.
- `Config.RequireAce` - set to `true` if only admins should use the menu.
- `Config.VehicleCategories` - vehicles shown in the spawn tab.
- `Config.PlayerModels` - peds shown in the player tab.
- `Config.QuickOutfits` - quick clothing presets.
- `Config.VehicleColors` - paint buttons shown in the mods tab.

If `Config.RequireAce = true`, add this to your local `server.cfg`:

```cfg
add_ace group.admin fivem_vmenu.use allow
```

Then make sure your admin identifiers are added to `group.admin`.
