# Map Markers and Collectables by Raze 1.4

Released September 14, 2026.

## New in 1.4

- **Refreshed chest data:** add 54 locations, remove two original entries absent from the fresh extraction, and correct one extra-large chest position. All 1,020 chests in the displayed categories match the fresh game data. Retained chest IDs continue to use your saved collection records, including pickups before installation.
- **Progression-aware chests:** **Hide unobtainable chests** starts enabled and checks recorded world, quest and environment conditions. Unmoored-only locations appear automatically at the appropriate world state. **Reveal Unmoored-only chests early** is an optional override for the world requirement; other conditions still apply.
- **Custom chest appearance:** distinct chest artwork and category colour defaults, with separate acquired/unacquired artwork, game-symbol and colour choices. Existing settings are preserved.
- **First-token guidance:** **Show first Seeker's Token** starts enabled and marks its saved location in red on both maps. The marker disappears after Finder's Token collection and has its own visibility toggle.
- **Clearer overlapping icons:** collectible markers draw above ordinary full-map game icons, addressing overlaps such as Dragon's Gaze hiding a small token marker.
- **Cave and city chest visibility:** chest fog filtering applies outdoors. Chests ignore fog on cave/city local maps and resume the saved outdoor preference when you leave. Other filters still apply.

Three quest-controlled chest placements have unresolved activation rules and stay hidden while unopened with progression filtering enabled. Disable **Hide unobtainable chests** to display them. The retained Sphinx reward datasets are not exposed as a category.

## Install or update

Requires [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8).

Close the game and install `Map-Markers-and-Collectables-by-Raze-v1.4.zip` with Fluffy Mod Manager. For manual installation, copy both `reframework` and `natives` from the ZIP into the game folder beside `DD2.exe`, then restart the game.

**Install the complete ZIP.** This update includes new runtime modules, chest metadata and artwork. Keep `reframework/data/raze_MapMarkersAndCollectables_settings.json` to retain your choices.

Open **REFramework > Script Generated UI > Map Markers and Collectables by Raze**. Tokens and beetles start enabled; enable the chest categories you want. Existing category and fog choices are preserved. The new progression filter and first-token marker start enabled.

Height arrows, independent map visibility, marker-size controls and earlier fixes remain included. The release passes Lua, Python, syntax, asset and package checks. Raze reported that the tested build looked good in-game; the final chest reconciliation was verified against the fresh extraction.

Source credits and notices are included in `docs/raze_MapMarkersAndCollectables/THIRD_PARTY_NOTICES.md` inside the download.
