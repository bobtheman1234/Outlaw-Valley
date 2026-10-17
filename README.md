# OUTLAW VALLEY: THE HOLLOW CROWN — Art Upgrade 0.4

This is the independent Roblox game, **not Goblin Hunt**. Open `Outlaw_Valley_Hollow_Crown_v04_ArtUpgrade.rbxlx` in Roblox Studio. Prior v0.3 combat, saved progression and Godslayer owner entitlement are preserved.

## What changed visually

- **11 Creator Store models selected and integrated** for automatic loading: stone castle kits, medieval village houses, pine tree clusters, forest props, barrels, wizard tower, village market props and magical figures. All are listed in `ASSET_AUDIT.md` with links and checks.
- **Hundreds of additional built-in scene details** work even if external assets are blocked: roof trim, chimneys, shutters, climbing ivy, banners, market stalls, forge racks, flowers, ritual gardens, water lilies, trees, ruined walls, and a detailed Godslayer shrine.
- The original functional scenery and collision fallbacks remain. Imported models are sanitized and most are cosmetic; the gameplay engine is unchanged.

## Why external models might not appear immediately

Roblox requires **Game Settings → Security → Allow Loading Third Party Assets** for server-side imports of public free Creator Store models. The place requests the setting in the XML, but we can't verify from here whether Studio applies it. If the setting remains disabled, the import will fail safely, and the original plus built-in visual improvements are shown. Check Output for `[Outlaw Art]` and `Workspace.OutlawCuratedCreatorStoreArt` attributes.

If you prefer external models to become permanent objects in the place instead of fetching them on each new server, use Studio's **Command Bar** once after enabling the setting:

`require(game.ServerScriptService.OutlawAssetInstaller).Install(true)`

Then save/publish the place. The auto-import script will detect them and avoid duplicating the objects.

## Game systems preserved

- Solo PvE, cooperative fights and optional wilderness PvP, with separate banked and carried loot.
- Finite ammunition and reloading for regular weapons, actual arcing grenades, dodge, eight enemy types, boss phases, treasure hunts, three wave defenses, timed egg incubation and magic companion.
- **Godslayer** available automatically to the personal experience creator, free for that owner. The 100 Robux pass isn't active until you create it on Roblox and put the pass ID in `ReplicatedStorage.OutlawConfig.PassId`.

## Testing truthfulness

The **offline** test suite checks Luau syntax using a Lua parser (not a Roblox runtime), pure game rules, XML script wiring, scene count and presence of importer safety controls. It does not execute Roblox Studio. **Model appearance, actual Creator Store delivery, collisions, multiplayer, and playtime have not been verified in the engine.** There are **zero pre-embedded Creator Store model meshes** in this offline `.rbxlx`; the model references/loader are included and require Roblox delivery to render.

`tests/validate.py` and `tests/gameplay_contracts.py` generate test reports. Source scripts remain editable under `src`.