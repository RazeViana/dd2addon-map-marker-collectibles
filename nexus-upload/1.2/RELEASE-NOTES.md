# Map Markers and Collectables by Raze 1.2

Released September 9, 2026.

## New in 1.2

- **Minimap height arrows:** an upward arrow above an icon means the item is higher than you; a downward arrow below it means it is lower. Arrows stay upright and use the item's marker color with either object icons or game symbols.
- **Height controls:** **Show height indicators** starts enabled. **Height tolerance (world units)** defaults to 3 and accepts 0–30. Items within the tolerance have no arrow.
- **Independent map controls:** use **Show on full map** and **Show on minimap** to choose where collectible markers appear. Both start enabled and preserve your category and appearance preferences.
- **Marker-name error fix:** avoids the reported full-map `newindex` script error when assigning marker names.

## Also included in this download

- Consistent full-map collectible icon sizes after zooming.
- Saved collection status takes precedence when approaching previously collected beetles.
- Packaged documentation uses this mod's own directory, avoiding root README overwrite warnings with Crowded Cities and similar packages.

## Install or update

Requires [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8).

Close the game and install `Map-Markers-and-Collectables-by-Raze-v1.2.zip` with Fluffy Mod Manager. For a manual installation, copy both the `reframework` and `natives` folders from the ZIP into your game folder beside `DD2.exe`.

Install the complete ZIP so the new arrow artwork is included, then restart the game. Keep `reframework/data/raze_MapMarkersAndCollectables_settings.json` to preserve your preferences. The new controls are under **REFramework > Script Generated UI > Map Markers and Collectables by Raze > Minimap settings**; the two map visibility toggles are directly above that section.

Automated Lua, packaging, syntax, dataset, and asset checks pass. In-game appearance and native HUD behavior require in-game testing.

Source credits and notices are included in `docs/raze_MapMarkersAndCollectables/THIRD_PARTY_NOTICES.md` inside the download.
