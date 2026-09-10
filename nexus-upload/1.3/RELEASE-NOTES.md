# Map Markers and Collectables by Raze 1.3

Released September 10, 2026.

## New in 1.3

- **Hide chests in unexplored areas:** enable this new option to hide regular and special chest markers under the map's fog of war on both the full map and minimap. It starts disabled, so updating preserves the previous display behavior.
- **Visibility follows exploration:** minimap chest markers appear as their locations are revealed. Hidden chests do not count toward the minimap marker limit.
- **Your existing choices still apply:** category visibility, Acquired/Unacquired filters, symbols, colors, and size are preserved. Tokens and beetles retain their usual visibility.
- **Loading recovery:** if fog data is temporarily unavailable, affected chest markers stay hidden and the menu shows a message. Visibility recovers automatically when the data is ready.

## Install or update

Requires [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8).

Close the game and install `Map-Markers-and-Collectables-by-Raze-v1.3.zip` with Fluffy Mod Manager. For a manual installation, copy both the `reframework` and `natives` folders from the ZIP into the game folder beside `DD2.exe`.

Install the complete ZIP, including the new fog module, then restart the game. Keep `reframework/data/raze_MapMarkersAndCollectables_settings.json` to preserve your preferences.

Open **REFramework > Script Generated UI > Map Markers and Collectables by Raze** and enable **Hide chests in unexplored areas**. Enable your desired chest categories as well.

All features from 1.2 remain included: minimap height arrows, independent map visibility, object icons, marker-size controls, and the previous fixes.

Automated Lua, packaging, syntax, dataset, and asset checks pass. Fog boundaries, local-area transitions, and native HUD behavior still require in-game verification; no in-game result is claimed for this release.

Source credits and notices are included in `docs/raze_MapMarkersAndCollectables/THIRD_PARTY_NOTICES.md` inside the download.
