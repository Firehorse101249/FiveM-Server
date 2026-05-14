# FiveM Server

This repo keeps the editable server code separate from generated server files, logs, cache, and secrets.

## Layout

- `server.cfg.example` - safe starter server config. Copy this to `server.cfg` locally and add secrets there.
- `myLogo.png` - server icon referenced by the txAdmin config.
- `resources/[core]/fivem_core` - main shared/client/server Lua code for custom server behavior.
- `resources/[ui]/fivem_hud` - starter NUI resource for future HUD or menu work.
- `resources/[standalone]` - small independent resources.
- `resources/[qb]` - QBCore framework and QBCore gameplay resources from the txAdmin profile.
- `resources/[voice]` - voice/radio resources from the txAdmin profile.
- `resources/[defaultmaps]` - default map resources from the txAdmin profile.
- `resources/[jobs]` - job and economy gameplay resources.
- `resources/[maps]` - map, IPL, and interior resources.
- `resources/[vehicles]` - vehicle packs and handling resources.
- `resources/[system]`, `resources/[managers]`, `resources/[gamemodes]`, `resources/[gameplay]` - default resources from the G-Portal server-data package.
- `resources/[framework]` - ESX, QBCore, or other framework resources if you add one later.
- `shared` - repo-wide documentation or data that is not a FiveM resource by itself.
- `docs` - setup notes and development conventions.
- `templates/fivem_resource` - copyable starter shape for new custom resources.

## Getting Started

1. Copy `server.cfg.example` to `server.cfg`.
2. Add your license key, database connection, and admin identifiers to `server.cfg`.
3. Import SQL from `data/sql/qbcore` and `data/sql/srp_medical.sql` when preparing a fresh database.
4. Put downloaded third-party resources under the matching `resources/[...]` folder.
5. Keep custom standalone systems in clearly named resources such as `resources/[standalone]/srp_medical`.
6. Start resources from `server.cfg` with `ensure resource_name`.

`server.cfg` is ignored by Git so private keys and local settings stay off the repo.
