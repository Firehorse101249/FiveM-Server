# SRP Medical

Standalone advanced medical MVP for a serious FiveM roleplay server. It is original code, QBCore-first, and structured so ESX support can be added later through the framework bridge.

## Where This Goes

This resource is already placed at:

`resources/[standalone]/srp_medical`

Add this to `server.cfg` after QBCore, inventory, ox_lib, and oxmysql if you use them:

```cfg
ensure srp_medical
```

## Required Files

- `fxmanifest.lua` - resource manifest.
- `config/config.lua` - main server owner configuration.
- `shared/*.lua` - body parts, injury/vitals math, treatment helpers.
- `client/*.lua` - damage detection, commands, NUI bridge.
- `server/*.lua` - state, permissions, inventory, SQL, reports, exports.
- `nui/*` - patient chart, body diagram, vitals, treatment, reports, history.
- `sql/srp_medical.sql` - optional but recommended database schema.
- `items/qb-core-items.lua` - paste into `qb-core/shared/items.lua`.
- `items/ox_inventory_items.lua` - paste into `ox_inventory/data/items.lua`.

## MVP Features

- Injury tracking by damage type, body part, severity, bleeding, pain, consciousness impact, treatment status, and worsening risk.
- Vitals simulation for pulse, breathing, blood pressure, oxygen saturation, glucose, pain, blood volume, and consciousness.
- Staged medical state: injured, incapacitated, unconscious, critical, cardiac arrest, deceased.
- Certification and job based treatment success.
- Partial failures and worsening outcomes.
- EMS patient care reports and medical history storage when SQL is available.
- Automated hospital recovery instead of doctor/surgeon gameplay.
- Scaffolded hospital and specialist hooks for future expansion.

## Commands

- `/medui` - open nearest patient chart, or self if no one is nearby.
- `/checkpulse` - quick pulse assessment.
- `/checkbreathing` - quick breathing assessment.
- `/treat` - open treatment UI.
- `/carrypatient` - placeholder event for carry/drag integration.
- `/loadstretcher` - placeholder event for stretcher integration.
- `/emsreport` - open report tab.
- `/medicalhistory` - open history tab.

Admin commands require ACE permission `srp_medical.admin`:

- `/medtestinjury [serverId] [injuryType] [bodyPart] [severity]`
- `/medclear [serverId]`
- `/medgivecert [serverId] [certification] [level]`
- `/medremovecert [serverId] [certification]`
- `/medstate [serverId]`

Example ACE:

```cfg
add_ace group.admin srp_medical.admin allow
```

## SQL Install

Run:

`resources/[standalone]/srp_medical/sql/srp_medical.sql`

The resource works without SQL, but reports, persisted medical state, and persisted certifications will only last in memory.

## Configuration Notes

Main tuning lives in `config/config.lua`.

Useful first edits:

- `Config.Framework` - use `qb` or `standalone`.
- `Config.Inventory` - `auto`, `ox_inventory`, `qb-inventory`, or `none`.
- `Config.ItemRequirements.Enabled` - disable item consumption for early testing.
- `Config.Jobs` - map your exact QBCore job names into roles.
- `Config.RoleDefaults` - default certs by role.
- `Config.Treatments` - items, treatment timing, allowed roles, required certs, and base chances.
- `Config.AutomatedRecovery.Locations` - hospital zones and beds.

## Exports

Server exports:

```lua
exports.srp_medical:ApplyInjury(targetSource, {
    type = 'gunshot_wound',
    bodyPart = 'left_leg',
    severity = 'severe',
    source = 'external_script'
})

exports.srp_medical:HealInjury(targetSource, injuryId)
local state = exports.srp_medical:GetMedicalState(targetSource)
exports.srp_medical:SetUnconscious(targetSource)
exports.srp_medical:RevivePlayer(targetSource)
exports.srp_medical:OpenPatientUI(providerSource, targetSource)
exports.srp_medical:AddMedicalReport(providerSource, reportData, cb)
```

Events for integrations:

- `srp_medical:server:applyInjury`
- `srp_medical:server:healInjury`
- `srp_medical:server:setUnconscious`
- `srp_medical:server:revivePlayer`
- `srp_medical:server:openPatientUi`
- `srp_medical:server:addMedicalReport`
- `srp_medical:server:onCarryPatient`
- `srp_medical:server:onLoadStretcher`

The integration events above are server-side events for trusted resources. Use exports when possible.

## Doctor / Surgeon Design Choice

This version intentionally avoids doctor and surgeon gameplay per request. Severe injuries are handled by automated hospital recovery with realistic chance tuning based on injury severity and field stabilization. The config includes `Config.AutomatedRecovery.SurgeryScaffoldOnly` and hospital action scaffolds so specialist gameplay can be added later without rewriting the MVP.

## First Test Flow

1. Start QBCore, inventory, optional `ox_lib`, optional `oxmysql`, then `srp_medical`.
2. Give admin ACE.
3. Use `/medtestinjury <id> gunshot_wound left_leg severe`.
4. Use `/medui`.
5. Run full body scan, select the injury, apply tourniquet or trauma kit.
6. Use `/emsreport` and save a report.
7. Move to a configured hospital zone and use Automated Recovery.
