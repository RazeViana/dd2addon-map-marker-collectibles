# Map Markers and Collectables by Raze

Find Seeker's Tokens, Golden Trove Beetles, and chests more easily in Dragon's Dogma 2. This mod marks their locations on your full map and shows nearby items on your minimap while you explore.

**Current version: 1.0.**

## What it does

- Shows tokens, beetles, and different types of chests on both maps.
- Lets you choose which items to show, including items you have already collected.
- Lets you change marker symbols and colors to suit your preferences.
- Keeps minimap symbols upright as you turn the camera.
- Gives you more room for markers on both maps.
- Lets you adjust how far away nearby items appear and how many markers appear on the minimap.

Tokens and beetles are shown by default. Turn on chest categories in the mod's menu if you want to find those too.

## Install

You need [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8). Install it first.

1. Close the game and disable any other mod that adds collectable markers, so you do not see duplicates.
2. Install `Map-Markers-and-Collectables-by-Raze-v1.0.zip` with Fluffy Mod Manager. For a manual installation, open the ZIP and copy its `reframework` folder into your game folder, alongside `DD2.exe`.
3. Start the game. In the REFramework menu, open **Script Generated UI > Map Markers and Collectables by Raze**.
4. Choose the items you want to see, then explore with your full map or minimap.

## Make it your own

Use the category options to choose what appears on your maps and change its symbol or color. **Unacquired** means items you have not collected; **Acquired** means items you have already collected.

Turn **Show on minimap** on or off whenever you like. Under **Minimap settings**, you can change how far away items appear, limit markers above or below you, and choose how many nearby markers to show. Nearby items appear first. Lower the number if your minimap feels crowded.

## Need help?

If markers are missing, make sure the category is enabled. For minimap markers, also check that the game's minimap is visible and **Show on minimap** is turned on. There may be no matching items close enough to you.

Restart the game after installing or updating. If you see an error, include its message when reporting the problem. Other mods that change map markers may conflict.

## Update or uninstall

To update, replace this mod's files with the new download. Keep `reframework/data/raze_MapMarkersAndCollectables_settings.json` to keep your choices.

To uninstall, close the game and disable the mod in Fluffy Mod Manager. If you installed manually, remove these files and folders:

- `reframework/autorun/raze_MapMarkersAndCollectables.lua`
- `reframework/autorun/raze_MapMarkersAndCollectables_Diagnostics.lua`
- `reframework/autorun/raze_MapMarkersAndCollectables/`
- `reframework/data/raze_MapMarkersAndCollectables/`

You can keep the settings file if you plan to reinstall. Leave REFramework installed if your other mods use it.

## Credits

Mod adaptation and added features by Raze. Original code and location data are credited in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
