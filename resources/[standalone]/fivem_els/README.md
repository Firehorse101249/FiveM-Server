# fivem_els

Standalone ELS and siren controller with a clickable NUI panel, selectable tones, synced light stages, manual siren, and airhorn.

## Controls

- `/els` or `F6` toggles the panel.
- `F7` focuses the panel so it can be clicked.
- `Q` cycles light stages.
- `R` toggles the siren.
- `T` cycles siren tones.
- Hold `Left Shift` for manual tone.
- Hold `E` for airhorn.

Players must be driving an allowed emergency vehicle. By default, vehicle class `18` is allowed.

## Vehicle Setup

Edit `config.lua` to match your vehicle pack:

- `Config.ManagedExtras` lists every extra the script may control.
- `Config.LightStages` decides which extras turn on for each stage.
- `Config.SirenTones`, `Config.ManualTone`, and `Config.Airhorn` can be changed for your preferred sound names or custom soundsets.
- `Config.AllowedModels` can restrict the system to exact vehicle models.

Add this to `server.cfg` after your core resources:

```cfg
ensure fivem_els
```
