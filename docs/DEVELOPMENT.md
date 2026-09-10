# Development

Map Markers and Collectables by Raze is a Dragon's Dogma 2 REFramework Lua mod. The current packaged release is 1.3. Source and dataset attribution is documented in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Runtime

The main entry point is `reframework/autorun/raze_MapMarkersAndCollectables.lua`. Its modules handle settings, nearby selection, minimap rendering, object icons, chest fog visibility, and sprite-pool expansion. Diagnostics and probes are development tools outside the release runtime.

The full map uses `app.ui040205.setupMapIcon`. Nearby minimap markers are rendered after `app.ui020301.updateIcon`, using the game's projection and currently unused sprite slots. Borrowed minimap slots are restored before the next native update. Glyph rotation stays at zero while the map positions follow the game's projection.

The sprite-pool module preserves existing native entries and grows the full-map sprite array to 2,048 and the minimap list to 512 when height indicators are enabled (256 otherwise). Disabling arrows does not shrink a pool already expanded to 512. The managed icon wrapper requires simplified allocation; initialized native fields and independent foreground/background sprites are copied before publication to the HUD. Expanded pools are reused after script resets.

Settings are read only from `raze_MapMarkersAndCollectables_settings.json`. Missing or malformed files use normalized defaults. No other mod's settings are read or imported.

`hide_unexplored_chests` defaults to false; only a saved boolean true enables it. **Hide chests in unexplored areas** filters all seven chest categories on both maps, after normal category/acquisition selection. `fog_of_war.lua` reads `GuiManager:getMaskInfo(ui.LocalAreaNow)` and calls the exact `MapMaskInfo:isMaskOff(via.vec3)` overload with each chest's world coordinates. Both UI fields and method signatures were checked against the installed executable's TDB 83 metadata without starting the game; `MaskBit` initialization is checked before querying. No fog setters or save writes are used.

Full-map filtering runs after the marker cache on each native setup, so reopening or rebuilding the map reads current fog. Minimap filtering runs each update before distance sorting and the marker limit, while collectible positions can remain cached. Hidden chests therefore do not consume available marker slots, and revealed chests appear without waiting for that cache to expire. Area masks are resolved on every pass and never retained across save or area changes. Missing fog data or a failed lookup hides affected chest markers and shows a recoverable status message; other categories remain visible. Native boundary behavior, caves/towns, and fog edges still need the user's in-game testing.

`fullmap.enabled` defaults to true, including when an existing settings file has no full-map preference. **Show on full map** and **Show on minimap** are independent controls saved through the existing settings mechanism. Changing full-map visibility requests the normal UI-thread map rebuild. Its pre-hook restores borrowed sprite state; the disabled path clears hover labels and skips custom marker creation, collectible queries, and pool expansion. The runtime regression covers disabling an open map, reopening while disabled, restoring markers and hover labels, retaining symbol/size choices, saving both states, and minimap independence. In-game verification of the new toggle is pending.

Collection checks read the loaded game's generation flags and context database, so an existing save does not need a mod-specific pickup history. A positive live beetle `get_IsBroken()` result detects a fresh pickup immediately. A negative result falls through to the saved `GatherContext:get_Num()` check: a loaded but unbroken gimmick must not override saved depletion. This fixes the Lua path that could show a previously collected beetle on approach and hide it again at a distance. Token and chest queries retain their existing saved-state fallbacks, and the context-reset hook clears cached acquisition state on save changes.

Hover labels are stored in Lua by custom MapIconInfo address and applied through `TxtName:set_Message` after `setupIconName`; native entries are excluded by address. A valid item-name GUID lets the game show and position the native label panel before the custom text is assigned. Marker creation does not write the native `MapIconInfo.Name` field, whose setter is the failing operation at line 911 in the reported script. The runtime regression rejects that field assignment and verifies that markers still render and all category hover labels display correctly. This covers the Lua failure path; confirmation on the reporter's game and REFramework build is still pending.

Object icons use native type 31 for layout, with a separate UV sequence for the four SVG designs in `assets/icons/`. `object_icons.lua` loads additive full-map/minimap atlases under `natives/stm/raze/mapmarkers/`. The original atlas sequences and texture references are preserved. Borrowed minimap slots restore their UV coordinates along with other state, and script reset restores native atlas holders. The `object_icons` setting defaults to true and does not replace saved category symbols or colors.

Minimap height indicators use UV sequence 3, patterns 0 (up) and 1 (down), backed by `height-arrows.tex`. The original and object-icon sequences are unchanged. `minimap.height_indicators` defaults to true; `minimap.height_tolerance` defaults to 3 and accepts integer world-unit values from 0 to 30. Each frame compares collectible Y with the current `PlUPos.y`, including while collectible candidates are cached. Equality with the tolerance counts as level. A second rendering pass draws arrows only for visible collectible icons, after all collectible slots have been assigned. Arrow scale is 60% of its item's scale, with vertical placement based on the two sprites' current sizes. Arrows share the item's color, stay upright, and are omitted if their centers would fall outside the minimap. Missing custom artwork leaves arrows hidden. Every borrowed arrow slot participates in the existing restoration and HUD-destruction cleanup.

`icon_size` defaults to 50 and accepts integer percentages from 25 to 150. The full map sizes every custom marker from the current `ui040205.IconScale`, so reused slots cannot retain different sizes from earlier zoom levels. Its per-slot scale snapshots are used only for restoration before native setup reuses slots. The minimap scales custom markers relative to each slot's native scale and restores it with the other borrowed state before each update. Full-map UV state is also restored before native setup. Repeated updates apply an absolute size, preventing cumulative shrinking.

## Data and build

Twelve datasets contain 1,298 location entries. Menu categories expose tokens, beetles, four chest sizes, and three special chest categories; the three additional Sphinx datasets are retained but not exposed as categories. Each dataset points to the central third-party notice for authorship.

`scripts/dataset-manifest.json` records file hashes, canonical location hashes, and counts. `scripts/build.py` verifies all of them, checks GUIDs and finite coordinates, and requires matching versions in metadata, UI, and README. No source archive is required to build.

```powershell
python -m pip install --target .tools/python lupa==2.6
python tests/run.py
python scripts/build.py
```

The build writes `dist/Map-Markers-and-Collectables-by-Raze-v1.3.zip` and refreshes the matching archive, changelog, checksum, and package manifest in `nexus-upload/1.3/`. The earlier 1.0 and 1.2 packages remain unchanged. Nexus page descriptions use plain text; the current copy is `nexus-upload/1.3/DESCRIPTION.txt`, selected by `description_file` in the listing. GitHub release notes remain in `nexus-upload/1.3/RELEASE-NOTES.md`. An explicit file list includes only the seven runtime Lua files, four icon assets, twelve datasets, and player documentation/metadata. Build verification rejects diagnostics, probes, debug files, and saved settings, and checks that all runtime modules are included.

README, changelog, and third-party notices are packaged together under `docs/raze_MapMarkersAndCollectables/`, preserving their relative links without overwriting other mods' root documentation. Source documents remain at the repository root. The builder rejects duplicate destinations (case insensitive) and payload paths outside this mod's directories; `modinfo.ini` is the only root entry and is Fluffy metadata. Build tests install the ZIP alongside Crowded Cities 1.0.0's documented file paths and verify its files survive unchanged.

## Local debugging

`scripts/development/` retains the minimap and capacity probes. Its `reframework/` subfolder holds the independent diagnostics entry point and module, which can export metadata even when the map script fails. Tests continue to check these tools, but neither the tools nor their reports are included in the release ZIP.

To install diagnostics for a local investigation, run `./scripts/install-diagnostics.ps1 -GamePath 'E:\SteamLibrary\steamapps\common\Dragons Dogma 2'`, then restart the game or reset scripts. Temporary reports and session probes belong in the ignored `reference/runtime/` directory. Disable the diagnostics entry point when testing the normal release menu.

## Verification

Eight Lua test files cover full-map labels and symbols, settings isolation and validation, diagnostics, nearby selection, minimap slot restoration, fog visibility and recovery, atlas switching, and sprite expansion/reuse/failure handling. Fog regressions exercise the actual main-script controls and all chest categories, saved preferences, acquisition rules, exploration with cached markers, local-area changes, unavailable data, and filtering before the minimap limit. The minimap stress fixture renders 200 custom markers alongside 56 native icons. Runtime Lua files are syntax checked. Asset validation checks that every original atlas entry is unchanged and the custom texture and UV coordinates are valid.

The 1.2 height-indicator regression additionally renders 200 collectible icons and 200 arrows alongside 56 native icons in a 512-slot pool. It checks direction, tolerance boundaries, current player height with cached candidates, camera rotation, restored state, toggles, missing artwork, map edges, HUD destruction, and collectible priority when slots are exhausted. Settings controls and atlas callbacks are exercised through the main entry point. Packaging checks verify that both arrow glyphs reference the installed texture. In-game verification of position, scale, readability, and transitions is left to the user for this build; none of these offline fixtures simulates the native HUD.

`tests/run.py` also runs the Python packaging tests. They build in a temporary copy so running tests cannot overwrite release archives or upload metadata.

### Crowded Cities compatibility

The 2026-09-07 code audit compared the runtime with Crowded Cities / MoreNPC 1.0.0 from the installed archive. No direct code conflict was found. Crowded Cities keeps local state, reads `MoreNPC.json`, registers frame/UI callbacks, and writes five NPC/enemy population-limit fields on `GenerateManager`. Its repopulation buttons request NPC/enemy destruction. This mod uses separate settings, modules, resources, and map/minimap hooks. Its only generation-manager operation is the collectible query `isNeverGenerate`; it does not write population limits or request character destruction.

A local Lua smoke check loaded the actual Crowded Cities script both before and after this mod. It ran the full-map regressions with population caps active, rejected unexpected global or population-cap writes, and checked that the repopulation buttons still called their own methods. Both orders passed. The local check is retained in ignored `reference/runtime/check-crowded-cities.py` and requires the installed third-party script; it is not bundled. Native calls are mocked, so this does not verify combined in-game stability, performance, or native despawn behavior. If additional NPCs produce more native minimap icons, collectible markers can run out of free slots; the renderer preserves native icons and stops at capacity.

The full-map size regression starts with two slots retaining different scales, then exercises zoom changes and partial native scale updates. It checks matching custom sizes, native-marker preservation, and exact slot restoration. This fixture covers the Lua boundary behavior; the zoom fix still needs an in-game check at 1440p before release.

To edit the artwork, update the SVG files, run `node scripts/render-icons.cjs` with `sharp` installed, then run `python scripts/icon_assets.py` with Pillow installed. Generated native assets are committed; building the ZIP does not require those graphics dependencies or extracted game files.

In-game verification on 2026-09-06 with REFramework TDB 83 confirmed both capacities, upright minimap symbols, map transitions, category controls, and the minimap toggle. The full map displayed 1,272 custom markers plus three native icons. Hiding small chests changed total visible icons from 1,275 to 686 and cleared all 251 occupied slots beyond index 1,023; restoring the category restored those icons. The 256-slot minimap survived repeated script resets.

Collection removal and save/load need broader native testing. The full 200-marker minimap load has offline coverage but has not been reached naturally in the live test area.

The 1.1 acquisition regression supplies collection records before any pickup is observed, then simulates an unbroken beetle object entering range. It exercises the actual minimap marker-provider callback and world-map rendering, acquired-only display, uncollected and missing-record cases, a fresh pickup ahead of saved state, and a different save. Existing token/chest records also have coverage. These are Lua boundary tests; confirmation on the reported affected New Game Plus save is still pending.

The same live session confirmed plain hover names and the custom object artwork on both maps. Changing the size slider between 50% and 100% changed full-map custom scale from approximately 0.3833 to 0.7667 and minimap custom scale from 0.3 to 0.6. Native marker scales were unchanged, and minimap glyph rotation remained zero across repeated updates.
