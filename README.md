# FiveM Server

This repo keeps the editable server code separate from generated server files, logs, cache, and secrets.

## Layout

- `server.cfg.example` - safe starter server config. Copy this to `server.cfg` locally and add secrets there.
- `resources/[core]/fivem_core` - main shared/client/server Lua code for custom server behavior.
- `resources/[ui]/fivem_hud` - starter NUI resource for future HUD or menu work.
- `resources/[standalone]` - small independent resources.
- `resources/[jobs]` - job and economy gameplay resources.
- `resources/[maps]` - map, IPL, and interior resources.
- `resources/[vehicles]` - vehicle packs and handling resources.
- `resources/[framework]` - ESX, QBCore, ox, or other framework resources if you add one later.
- `shared` - repo-wide documentation or data that is not a FiveM resource by itself.
- `docs` - setup notes and development conventions.
- `templates/fivem_resource` - copyable starter shape for new custom resources.

## Getting Started

1. Copy `server.cfg.example` to `server.cfg`.
2. Add your license key, database connection, and admin identifiers to `server.cfg`.
3. Put downloaded third-party resources under the matching `resources/[...]` folder.
4. Keep your custom code in clearly named resources, starting with `resources/[core]/fivem_core`.
5. Start resources from `server.cfg` with `ensure resource_name`.

`server.cfg` is ignored by Git so private keys and local settings stay off the repo.
