# Development

Map Markers and Collectables by Raze is a Dragon's Dogma 2 REFramework Lua mod. The public version is 1.0. Source and dataset attribution is documented in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Runtime

The main entry point is `reframework/autorun/raze_MapMarkersAndCollectables.lua`. Its modules handle settings, nearby selection, minimap rendering, sprite-pool expansion, and diagnostics. A separate diagnostic entry point can export metadata even if the map script fails to initialize.

The full map uses `app.ui040205.setupMapIcon`. Nearby minimap markers are rendered after `app.ui020301.updateIcon`, using the game's projection and currently unused sprite slots. Borrowed minimap slots are restored before the next native update. Glyph rotation stays at zero while the map positions follow the game's projection.

The sprite-pool module preserves existing native entries and grows the full-map sprite array to 2,048 and the minimap list to 256. The managed icon wrapper requires simplified allocation; initialized native fields and independent foreground/background sprites are copied before publication to the HUD. Expanded pools are reused after script resets.

Settings are read only from `raze_MapMarkersAndCollectables_settings.json`. Missing or malformed files use normalized defaults. No other mod's settings are read or imported.

## Data and build

Twelve datasets contain 1,298 location entries. Menu categories expose tokens, beetles, four chest sizes, and three special chest categories; the three additional Sphinx datasets are retained but not exposed as categories. Each dataset points to the central third-party notice for authorship.

`scripts/dataset-manifest.json` records file hashes, canonical location hashes, and counts. `scripts/build.py` verifies all of them, checks GUIDs and finite coordinates, and requires matching versions in metadata, UI, diagnostics, and README. No source archive is required to build.

```powershell
python -m pip install --target .tools/python lupa==2.6
python tests/run.py
python scripts/build.py
```

The build writes `dist/Map-Markers-and-Collectables-by-Raze-v1.0.zip` and refreshes the archive, changelog, checksum, and package manifest in `nexus-upload/1.0/`. The Nexus description is maintained in `DESCRIPTION.md`. Runtime settings and development probes are excluded from the archive.

## Verification

Six Lua test files cover full-map behavior, settings isolation and validation, diagnostics, nearby selection, minimap slot restoration, and sprite expansion/reuse/failure handling. The minimap stress fixture renders 200 custom markers alongside 56 native icons. Runtime Lua files are syntax checked.

In-game verification on 2026-09-06 with REFramework TDB 83 confirmed both capacities, upright minimap symbols, map transitions, category controls, and the minimap toggle. The full map displayed 1,272 custom markers plus three native icons. Hiding small chests changed total visible icons from 1,275 to 686 and cleared all 251 occupied slots beyond index 1,023; restoring the category restored those icons. The 256-slot minimap survived repeated script resets.

Collection removal and save/load need broader native testing. The full 200-marker minimap load has offline coverage but has not been reached naturally in the live test area.
