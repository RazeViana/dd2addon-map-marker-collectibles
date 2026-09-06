# Development

Map Markers and Collectables by Raze is a Dragon's Dogma 2 REFramework Lua mod. The public version is 1.0. Source and dataset attribution is documented in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Runtime

The main entry point is `reframework/autorun/raze_MapMarkersAndCollectables.lua`. Its modules handle settings, nearby selection, minimap rendering, object icons, and sprite-pool expansion. Diagnostics and probes are development tools outside the release runtime.

The full map uses `app.ui040205.setupMapIcon`. Nearby minimap markers are rendered after `app.ui020301.updateIcon`, using the game's projection and currently unused sprite slots. Borrowed minimap slots are restored before the next native update. Glyph rotation stays at zero while the map positions follow the game's projection.

The sprite-pool module preserves existing native entries and grows the full-map sprite array to 2,048 and the minimap list to 256. The managed icon wrapper requires simplified allocation; initialized native fields and independent foreground/background sprites are copied before publication to the HUD. Expanded pools are reused after script resets.

Settings are read only from `raze_MapMarkersAndCollectables_settings.json`. Missing or malformed files use normalized defaults. No other mod's settings are read or imported.

Hover labels are assigned to custom MapIconInfo entries and applied after `setupIconName`; native entries are excluded by address. A valid item-name GUID lets the game show and position the native label panel before the custom text is assigned.

Object icons use native type 31 for layout, with a separate UV sequence for the four SVG designs in `assets/icons/`. `object_icons.lua` loads additive full-map/minimap atlases under `natives/stm/raze/mapmarkers/`. The original atlas sequences and texture references are preserved. Borrowed minimap slots restore their UV coordinates along with other state, and script reset restores native atlas holders. The `object_icons` setting defaults to true and does not replace saved category symbols or colors.

`icon_size` defaults to 50 and accepts integer percentages from 25 to 150. Both renderers scale only custom markers relative to each slot's native scale. Full-map scale and UV state are restored before native setup can reuse slots; minimap scale is restored with its other borrowed state before each update. Repeated updates apply an absolute size, preventing cumulative shrinking.

## Data and build

Twelve datasets contain 1,298 location entries. Menu categories expose tokens, beetles, four chest sizes, and three special chest categories; the three additional Sphinx datasets are retained but not exposed as categories. Each dataset points to the central third-party notice for authorship.

`scripts/dataset-manifest.json` records file hashes, canonical location hashes, and counts. `scripts/build.py` verifies all of them, checks GUIDs and finite coordinates, and requires matching versions in metadata, UI, and README. No source archive is required to build.

```powershell
python -m pip install --target .tools/python lupa==2.6
python tests/run.py
python scripts/build.py
```

The build writes `dist/Map-Markers-and-Collectables-by-Raze-v1.0.zip` and refreshes the archive, changelog, checksum, and package manifest in `nexus-upload/1.0/`. The Nexus description is maintained in `DESCRIPTION.md`. An explicit file list includes only the six runtime Lua files, three icon assets, twelve datasets, and player documentation/metadata. Build verification rejects diagnostics, probes, debug files, and saved settings, and checks that all runtime modules are included.

## Local debugging

`scripts/development/` retains the minimap and capacity probes. Its `reframework/` subfolder holds the independent diagnostics entry point and module, which can export metadata even when the map script fails. Tests continue to check these tools, but neither the tools nor their reports are included in the release ZIP.

To install diagnostics for a local investigation, run `./scripts/install-diagnostics.ps1 -GamePath 'E:\SteamLibrary\steamapps\common\Dragons Dogma 2'`, then restart the game or reset scripts. Temporary reports and session probes belong in the ignored `reference/runtime/` directory. Disable the diagnostics entry point when testing the normal release menu.

## Verification

Seven Lua test files cover full-map labels and symbols, settings isolation and validation, diagnostics, nearby selection, minimap slot restoration, atlas switching, and sprite expansion/reuse/failure handling. The minimap stress fixture renders 200 custom markers alongside 56 native icons. Runtime Lua files are syntax checked. Asset validation checks that every original atlas entry is unchanged and the custom texture and UV coordinates are valid.

To edit the artwork, update the SVG files, run `node scripts/render-icons.cjs` with `sharp` installed, then run `python scripts/icon_assets.py` with Pillow installed. Generated native assets are committed; building the ZIP does not require those graphics dependencies or extracted game files.

In-game verification on 2026-09-06 with REFramework TDB 83 confirmed both capacities, upright minimap symbols, map transitions, category controls, and the minimap toggle. The full map displayed 1,272 custom markers plus three native icons. Hiding small chests changed total visible icons from 1,275 to 686 and cleared all 251 occupied slots beyond index 1,023; restoring the category restored those icons. The 256-slot minimap survived repeated script resets.

Collection removal and save/load need broader native testing. The full 200-marker minimap load has offline coverage but has not been reached naturally in the live test area.

The same live session confirmed plain hover names and the custom object artwork on both maps. Changing the size slider between 50% and 100% changed full-map custom scale from approximately 0.3833 to 0.7667 and minimap custom scale from 0.3 to 0.6. Native marker scales were unchanged, and minimap glyph rotation remained zero across repeated updates.
