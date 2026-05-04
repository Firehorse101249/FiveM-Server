# Development Notes

## Resource Naming

Use lowercase resource names with underscores, for example `fivem_core`, `police_job`, or `vehicle_shop`.

## Resource Shape

Most custom resources should follow this shape:

```text
resource_name/
  fxmanifest.lua
  config.lua
  shared/
  server/
  client/
  html/
```

- `shared` is loaded by both client and server.
- `server` is trusted server-side logic.
- `client` is player-side logic.
- `html` is only needed for NUI resources.

Use `templates/fivem_resource` as the starting point for new resources, then rename the folder and update its `fxmanifest.lua` metadata.

## Git Rules

Commit source code, examples, docs, and SQL migrations. Do not commit logs, cache, txAdmin generated data, database files, license keys, or real `server.cfg` values.
