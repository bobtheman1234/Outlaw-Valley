# Outlaw Valley — Creator Store asset audit (October 17, 2026)

**Scope:** 11 distinct, publicly listed **free** Creator Store model IDs. They are referenced in `src/OutlawAssetCatalog.lua` and imported by `src/OutlawAssetInstaller.lua` when Roblox permits third-party assets. They are **not embedded as mesh bytes** in the offline `.rbxlx`. No Roblox Studio viewport preview or mesh inspection was possible in this environment, and no claim of live installation is made.

| Asset | Roblox Creator Store listing | Reason / placement | Public listing checks |
|:--|:--|:--|:--|
| old house | https://create.roblox.com/store/asset/15413223952/old-house | 8 existing village houses get detailed exterior meshes | Free; 2 MeshParts; ~6.7k triangles |
| Low Poly Pine Tree Pack | https://create.roblox.com/store/asset/86014764516390/Low-Poly-Pine-Tree-Pack | Forest groves outside the village and on the ridge | Free; 7 pine variants; 14 MeshParts; ~2k triangles |
| Stylized Forest Props Pack | https://create.roblox.com/store/asset/112552460612661/Stylized-Forest-Props-Pack | Ground vegetation, mushrooms, rocks and logs | 23 low-poly props; 26 MeshParts; listing reports no scripts |
| Barrel | https://create.roblox.com/store/asset/470360075/Barrel | Repeated detail around the market, camps and fort | Free; 97% rating across 200+ votes; ~2.4k triangles |
| Wizard Tower | https://create.roblox.com/store/asset/185167270/Wizard-Tower | A vertical focal point in Witchwater | Free; ~21k triangles |
| Medieval Castle mesh pack | https://create.roblox.com/store/asset/14841340596 | Stonework details inside fortress | Free; 22 MeshParts; ~28k triangles |
| Castle/Medieval Asset Pack | https://create.roblox.com/store/asset/12007890134/CastleMedieval-Asset-Pack | Courtyard detail / fortified stonework | Free; 98% rating; 306 MeshParts; ~192k triangles; single copy only |
| Medieval Asset Pack | https://create.roblox.com/store/asset/74849899553864/Medieval-Asset-Pack | Merchant's displays and period props | Free; 7 MeshParts; ~26k triangles |
| magic staff | https://create.roblox.com/store/asset/15250908165/magic-staff | Wizard shrine props | Free; 3 MeshParts; ~661 triangles |
| spooky goblin | https://create.roblox.com/store/asset/10407161427/spooky-goblin | Decorative enemy figure at bandit camp only | Free; 4 MeshParts; ~8k triangles |
| Wizard | https://create.roblox.com/store/asset/12579105102/Wizard | Decorative static caster by tower, **not** presented as active AI | Free; 2 MeshParts; ~4.8k triangles |

## Excluded after checking listings

- Paid medieval house packs (e.g. `129929120993235`, `82836039768678`) — not inserted because they require purchase.
- Some alleged medieval village free models with dozens of scripts, e.g. `6479469908` (48 scripts, very large geometry) — unsafe to blindly load and too heavy for the scene.
- Numerous unrelated roleplay models with spammy keyword descriptions or potentially infringing branded IP — visual mismatch / copyright risk.
- Oversized medieval castle kits with ~720 mesh parts — higher scene/performance cost than useful for one dense level.

## Safety measures built into the importer

1. Loads only the hardcoded list of vetted **public model listing IDs**, never IDs supplied by players.
2. Removes all `LuaSourceContainer` descendants and Tools/RemoteEvents/BindableEvents as soon as an asset is delivered. This strips third-party scripts, preserving **Outlaw Valley's own** shop/combat and NPC logic.
3. Applies static positioning, anchors pieces and disables collision/query for decorations. A single tower becomes collidable. Prior structures remain as offline fallbacks and playable geometry.
4. Rejects source models with more parts than expected; guards scale and placement in `pcall`, logs errors, and skips failed assets.
5. Identifies installed models with attributes recording the Creator Store ID and original creator.

## Actual loading restriction / next verification

Roblox's `AssetService:LoadAssetAsync(assetId)` can load public free Creator Store models *only if the experience has enabled* **Game Settings → Security → Allow Loading Third Party Assets**. This is a Roblox platform restriction (source: https://create.roblox.com/docs/reference/engine/classes/AssetService). The generated place requests that setting on the serialized AssetService, but **Studio's handling of that security setting has not been runtime verified**. If it is not enabled, the enhanced original geometry still shows and the store models won't load.

For permanent embedding rather than live server-side import, open the place in Studio, enable the setting if needed, then run the one-time editor command:

```lua
require(game.ServerScriptService.OutlawAssetInstaller).Install(true)
```

Save/publish the place after successful import. Import status appears in Studio's Output as `[Outlaw Art]` and as attributes on `Workspace.OutlawCuratedCreatorStoreArt`.

**Count honesty:** 11 Creator Store IDs *integrated for conditional loading*; **0 external Creator Store mesh bytes embedded** into the offline place. Only real Roblox Studio testing can confirm how many actually load/render in the published experience.