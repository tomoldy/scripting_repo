# Agility with Birdhouses – Runtime Setup Guide

This guide documents the environment prerequisites and the user configurable inputs that must be
in place before running `agility-withbh.simba` inside Simba 1.4.

## Simba include paths

The script now expects the default Simba include lookup behaviour. Ensure the following folders are
available under *Tools → Manage Includes* (or manually inside `Simba/Includes`):

- `SRL-T` – provides the core OSRS include and form helpers.
- `WaspLib` – provides framework routines, optional teleport handlers, and GUI components.

If you synchronise these folders through Git, the paths should look similar to:

```
Simba/
└── Includes/
    ├── SRL-T/
    └── WaspLib/
```

The script conditionally includes additional modules when they are not already present:

- `optional/interfaces/mainscreen/mushtree.simba` – required for the mushroom teleport interface.
- `optional/handlers/teleports/transport.simba` – provides the universal transport helper used by
  the banking prep routines.
- `optional/handlers/discord.simba` – enables webhook messages when the webhook URL is provided in
  the GUI.

## Compiling in Simba 1.4

1. Launch Simba 1.4 and open `scripts/standard/agility-withbh.simba`.
2. Confirm the *Includes* path points at the folders listed above.
3. Use **Script → Compile**. Simba will halt on the first missing include or syntax issue. Fix the
   include path if you see errors referencing `SRL-T` or `WaspLib` files.
4. Successful compilation will leave the console idle with no new error output.

> **Tip:** If Simba still cannot locate `WaspLib`, add an explicit include path under
> *Settings → Paths → Includes* that points directly at your `Simba/Includes` directory.

## Debugging GUI initialisation

To verify saved settings and tab toggles:

1. Open the script in Simba and press **F9** to start debugging.
2. Set breakpoints on `TAgilityGUI.Create` and `TAgilityGUI.Run`.
3. Step through `Create` to confirm the INI loader resolves a username and populates:
   - `BankTab`, `Course`, `CompostMethod` numeric values
   - Toggle booleans: `DoBirdhouseRuns`, `DoFarmRuns`, `FarmRunNow`, `CompostFlowers`
   - Seed dropdown values `SavedHerbSeedName` and `SavedFlowerSeedName`
   - Webhook fields: `WebhookURL`, `SendHourlyReports`, `SendSessionSummaryReports`
4. Continue into `Run` and expand each tab to confirm the `Farm` and `Birdhouse` containers display
   the saved checkbox states.

## Banking preparation entry points

The bank-prep logic is triggered from two start routines:

- `Farm.OnStart` – opens the configured bank tab, withdraws farm run items, then restores the
  return inventory.
- `TBirdHouseInclude.OnStart` – mirrors the banking logic for birdhouse runs and pauses the antiban
  tasks.

During debugging, place breakpoints inside both methods to verify the countdown timers are initialised
and `OpenConfiguredBankTab` falls back to tab `0` when the saved tab is missing.

## INI configuration reference

The script persists configuration under `Configs/AgilityWithBH.ini` using the key prefix
`<username> AgilityWithBH`. Important keys include:

| Key | Description | Default |
| --- | --- | --- |
| `BankTab` | Bank tab index (0–9) used when preparing inventories. | `0` |
| `Course` | Agility course index (`ECourse` enum). | `DRAYNOR_ROOF` |
| `DoBirdhouseRuns` | Enables birdhouse module. | `true` |
| `DoFarmRuns` | Enables farm runs. | `true` |
| `FarmRunNow` | Forces an immediate farm run. | `false` |
| `CompostFlowers` | Enables compost use on flower patches. | `false` |
| `HerbSeed` | Last herb seed selection. | `Ranarr seed` |
| `FlowerSeed` | Last flower seed selection. | `Limpwurt seed` |
| `CompostIndex` | Dropdown index for compost method (offset to match `ECompostMethod`). | `ULTRA` |
| `WebhookURL` | Discord webhook destination. Leave empty to disable. | `` |
| `SendHourlyReports` | Sends periodic webhook updates when enabled. | `false` |
| `SendSessionSummaryReports` | Sends a summary webhook when the session ends. | `false` |

Ensure the `Configs` folder exists under the Simba working directory so the script can read and write
these settings.

## Optional features

- **Discord reporting:** Provide a valid URL in the GUI field. Without one, webhook handlers remain
  idle even though the include is present.
- **Mushtree teleports:** Enable the relevant checkbox in the GUI. The include is auto-loaded when
  `ANDREW_MUSHTREE_INCLUDED` is not already defined.
- **Universal transport:** Leave `SKUNK_UNIVERSAL_TRANSPORT` undefined to pull in the optional
  teleport helper. Define it in Simba if another script already registers a custom transport handler.

With the includes installed and the INI keys populated (either by previous runs or after one manual
configuration in the GUI), the script is ready to run for end users.
