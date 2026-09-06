# Map Markers and Collectables by Raze

A Dragon's Dogma 2 mod by Raze that adds customizable collectible markers to the full map and minimap. Based on Arisen's Almanac by gibbed.

**Current version: 1.0.** Includes nearby minimap markers, upright symbols, shared category controls, and expanded icon capacity on both maps.

The full map supports Seeker's Tokens, Golden Trove Beetles, four chest sizes, and three special chest categories. Each category has separate visibility, icon, and color settings for acquired and unacquired items, plus display priority controls. Tokens and beetles are enabled by default; chest categories can be enabled in the menu. All 12 supplied datasets are retained, including the three Sphinx datasets that the original script did not expose as categories.

The minimap shares the category visibility, icons, and colors. It selects the nearest eligible locations, refreshes collection state twice per second, and uses the game's coordinate projection. Collectible symbols stay upright as the camera turns. Native game icons take priority over custom markers.

## Install

Requires [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8), installed and working before installing this mod. Fluffy Mod Manager is optional; manual installation is supported.

1. Close the game and disable Arisen's Almanac in Fluffy Mod Manager. With a manual installation, move `reframework/autorun/gibbed_Almanac.lua` out of `autorun`. The old deprecated `gibbed_SeekersTokenMarkers.lua` can also be removed. Do not run both map scripts together: each adds its own markers.
2. Keep `reframework/data/gibbed_Almanac_settings.json` if you want to reuse your settings.
3. Import `Map-Markers-and-Collectables-by-Raze-v1.0.zip` into Fluffy, or extract its `reframework` folder into the game folder containing `DD2.exe`.
4. Launch the game and expand **Map Markers and Collectables by Raze** in REFramework's Script Generated UI. Show the minimap and open the full map to see enabled markers.

The mod reads `reframework/data/raze_MapMarkersAndCollectables/`. It saves settings to `reframework/data/raze_MapMarkersAndCollectables_settings.json`. On first load, existing Almanac settings are imported if no usable new settings file exists. The old file is never overwritten. Invalid values revert to defaults.

When updating an earlier development build of this mod, overwrite its files and keep the settings file. Version 1.0 is the first public release number and includes the features tested in the development builds.

## Compatibility and uninstall

Disable Arisen's Almanac and the deprecated Seeker's Token Markers script before using this mod. Other scripts that modify the same map icon pools may conflict; compatibility with every UI or map mod has not been verified.

To uninstall, close the game and disable the mod in Fluffy. For a manual installation, remove `reframework/autorun/raze_MapMarkersAndCollectables.lua`, `reframework/autorun/raze_MapMarkersAndCollectables_Diagnostics.lua`, the `reframework/autorun/raze_MapMarkersAndCollectables/` folder, and the `reframework/data/raze_MapMarkersAndCollectables/` folder. Keep `raze_MapMarkersAndCollectables_settings.json` to retain preferences for reinstalling. REFramework itself does not need to be removed.

## Minimap settings

**Show on minimap** enables the overlay. **Minimap settings** controls the search radius (default 180 world units), vertical range (60), and marker limit (24, adjustable up to 200). Existing settings are preserved on upgrade; raise **Maximum custom icons** to use the higher allowance. The on-screen counter reports custom icons actually drawn. The count may be lower than the configured limit because of the minimap boundary, category filters, collected state, and space needed by native game icons.

The renderer only uses currently unused native sprite slots. It returns those slots before the next native update and restores their previous appearance. If a runtime error occurs, minimap drawing pauses and the menu shows the error. Toggle **Show on minimap** to retry after the cause is resolved. Updating files while the game is running requires **ScriptRunner > Reset scripts** or a game restart.

## Icon capacity

The full map's sprite pool expands from 1,024 to 2,048 slots. The minimap's pool expands from 50 to 256 slots, with up to 200 custom markers. The menu reports each pool's current capacity. These are total sprite slots shared with the game's icons, so the actual custom count depends on native usage and category filters.

Expansion preserves existing icons, creates hidden sprites with the same atlas and scale context, and reuses an already expanded pool after a script reset. It runs when each map is ready and is recreated with the HUD. If allocation is unavailable on another runtime, the menu reports the error and the original capacity remains available. Higher counts can increase map clutter and rendering work.

## Validation

On 2026-09-06 with REFramework TDB 83, the full-map pool expanded to 2,048 and the minimap pool to 256. The full map displayed 1,272 custom markers plus three native icons, leaving 773 slots free. Hiding small chests reduced the custom count to 683 and cleared all 251 visible slots beyond the original limit; restoring the category returned those icons and the 1,272 custom count. The expanded minimap survived script reloads and continued showing nearby markers. No script error appeared during these checks. Raze previously confirmed upright minimap symbols while turning the camera, full-map/minimap transitions, and the visibility toggle.

Six offline Lua test files cover map behavior, settings, diagnostics, nearby selection, pool expansion/reuse/failure handling, and rendering 200 custom minimap markers alongside 56 native icons. Collection removal and save/load still require in-game confirmation; the maximum 200-marker minimap load has offline coverage but has not been reached naturally in the live test area.

## Minimap diagnostics

The independent diagnostics script exports `reframework/data/raze_MapMarkersAndCollectables_minimap_diagnostics.json` at startup. For a report with the live HUD present, load a save, show the minimap, and press **Export Minimap Diagnostics** under **Map Markers and Collectables by Raze - Diagnostics**. Share that JSON along with `re2_framework_log.txt` from the game folder.

The exporter reads type metadata and checks whether the HUD exists. It does not add icons or modify game objects or saves. Use its report to investigate compatibility with another game or REFramework version.

## Development

Python 3.12 and Lupa 2.6 are used for offline verification. Install the test dependency with `python -m pip install --target .tools/python lupa==2.6`, then run:

```powershell
python tests/run.py
python scripts/build.py
```

The builder checks dataset integrity against the source backup and validates every GUID and position before creating the ZIP. Runtime settings, original sources, old preview, test dependencies, and diagnostics output are excluded from the package.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the original code and dataset credits.
