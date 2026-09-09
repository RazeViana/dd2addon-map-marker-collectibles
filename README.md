# Map Markers and Collectables by Raze

Find Seeker's Tokens, Golden Trove Beetles, and chests more easily in Dragon's Dogma 2. This mod marks their locations on your full map and shows nearby items on your minimap while you explore.

**Current version: 1.2.**

## What it does

- Shows tokens, beetles, and different types of chests on both maps.
- Lets you turn full-map and minimap markers on or off independently.
- Uses recognizable token, beetle, chest, and special chest symbols.
- Shows simple names when you hover over full-map markers, such as **Chest (S)** and **Special Chest (L)**.
- Lets you choose which items to show, including items you have already collected.
- Lets you change marker symbols and colors to suit your preferences.
- Starts with smaller icons and lets you adjust their size on both maps.
- Keeps minimap symbols upright as you turn the camera.
- Shows minimap arrows for collectibles above or below you, with an adjustable height tolerance.
- Gives you more room for markers on both maps.
- Lets you adjust how far away nearby items appear and how many markers appear on the minimap.

Tokens and beetles are shown by default. Turn on chest categories in the mod's menu if you want to find those too.

## Install

You need [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8). Install it first.

1. Close the game and disable any other mod that adds collectable markers, so you do not see duplicates.
2. Install `Map-Markers-and-Collectables-by-Raze-v1.2.zip` with Fluffy Mod Manager. For a manual installation, open the ZIP and copy both its `reframework` and `natives` folders into your game folder, alongside `DD2.exe`.
3. Start the game. In the REFramework menu, open **Script Generated UI > Map Markers and Collectables by Raze**.
4. Choose the items you want to see, then explore with your full map or minimap.

## Make it your own

Use the category options to choose what appears on your maps and change its symbol or color. **Unacquired** means items you have not collected; **Acquired** means items you have already collected.

**Use object icons** gives tokens, beetles, chests, and special chests their own symbols. Turn it off to use your saved game symbols and choose others in each category. Your colors and category choices are kept. Chest labels use **S**, **M**, **L**, and **XL** for small, medium, large, and extra large.

Use **Show on full map** and **Show on minimap** to turn collectible markers on or off independently. Both start enabled. Changing the full-map toggle refreshes an open map and keeps your category, symbol, color, and size choices.

Under **Minimap settings**, you can change how far away items appear, limit markers above or below you, and choose how many nearby markers to show. Nearby items appear first. Lower the number if your minimap feels crowded.

**Show height indicators** adds an upward arrow above an item icon when it is higher than you, or a downward arrow below it when it is lower. It starts enabled. **Height tolerance (world units)** defaults to **3** and can be set from **0 to 30**; items within that difference have no arrow. The arrows work with object icons and game symbols and use the item's marker color. They show relative height, not the route to the item. Items beyond **Maximum height difference** remain hidden. On a crowded minimap, item icons take priority over arrows.

Use **Icon size (%)** to resize this mod's markers on both maps. The default is **50%** (half size), and the slider goes from **25% to 150%**.

## Need help?

If markers are missing, make sure the category is enabled and **Show on full map** or **Show on minimap** is turned on for that map. For minimap markers, also check that the game's minimap is visible. There may be no matching items close enough to you.

Collection status is read from the loaded game's records, including items collected before you installed the mod. Keep **Acquired** turned off in each category to hide collected items. No separate pickup history or save conversion is required.

Restart the game after installing or updating. If you see an error, include its message when reporting the problem. Other mods that change map markers may conflict.

## Update or uninstall

To update, replace this mod's files with the new download. Keep `reframework/data/raze_MapMarkersAndCollectables_settings.json` to keep your choices.

To uninstall, close the game and disable the mod in Fluffy Mod Manager. If you installed manually, remove these files and folders:

- `reframework/autorun/raze_MapMarkersAndCollectables.lua`
- `reframework/autorun/raze_MapMarkersAndCollectables/`
- `reframework/data/raze_MapMarkersAndCollectables/`
- `natives/stm/raze/mapmarkers/`
- `docs/raze_MapMarkersAndCollectables/`

You can keep the settings file if you plan to reinstall. Leave REFramework installed if your other mods use it.

## Credits

Mod adaptation and added features by Raze. Original code and location data are credited in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
