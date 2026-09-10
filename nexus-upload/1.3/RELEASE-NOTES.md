# Map Markers and Collectables by Raze 1.3

Released September 10, 2026.

## New in 1.3

- **Three independent fog controls:** use **Hide chests in unexplored areas**, **Hide beetles in unexplored areas**, and **Hide Seeker's Tokens in unexplored areas** to choose which collectible types follow fog of war on both maps. The chest option covers regular and special chests.
- **Optional for each type:** all three settings start disabled. Enable any combination; category visibility, Acquired/Unacquired filters, symbols, colors, and size are preserved.
- **Visibility follows exploration:** minimap markers for the selected types appear as their locations are revealed. Hidden collectibles do not count toward the minimap marker limit.
- **Loading recovery:** if fog data is temporarily unavailable, affected markers stay hidden and the menu shows a message. Visibility recovers automatically when the data is ready.

## Install or update

Requires [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8).

Close the game and install `Map-Markers-and-Collectables-by-Raze-v1.3.zip` with Fluffy Mod Manager. For a manual installation, copy both the `reframework` and `natives` folders from the ZIP into the game folder beside `DD2.exe`.

Install the complete ZIP, including the new fog module, then restart the game. Keep `reframework/data/raze_MapMarkersAndCollectables_settings.json` to preserve your preferences.

Open **REFramework > Script Generated UI > Map Markers and Collectables by Raze** and enable the fog options you want. Your desired collectible categories must also be enabled.

This updated 1.3 package adds the beetle and token options to the earlier chest-only download. Reinstall the complete ZIP if you downloaded that earlier package. Your existing chest preference is preserved; the two added options start disabled.

All features from 1.2 remain included: minimap height arrows, independent map visibility, object icons, marker-size controls, and the previous fixes.

Raze confirmed the build with all three fog controls works in-game. Automated Lua, packaging, syntax, dataset, and asset checks also pass.

Source credits and notices are included in `docs/raze_MapMarkersAndCollectables/THIRD_PARTY_NOTICES.md` inside the download.
