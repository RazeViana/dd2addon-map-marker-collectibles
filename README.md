# Map Markers and Collectables by Raze

Find Seeker's Tokens, Golden Trove Beetles, chests, and Dark Arisen collectibles in Dragon's Dogma 2. This mod marks their locations on your full map and shows nearby items on your minimap while you explore.

**Current version: 1.5.**

Version 1.5 is an unpublished Dark Arisen test patch prepared October 9, 2026. Install the complete `Map-Markers-and-Collectables-by-Raze-v1.5.zip` package. DLC native acceptance checks are pending; see the supported scope below.

## Dark Arisen additions

- Add 140 Norgan Ducat placements and 389 Norgan chests, split into 267 ordinary and 122 rare chests.
- Add separate Norgan Ducat, chest and rare-chest artwork while preserving the new native map symbol added in Title Update 4.0.
- Retain 185 fixed Lost Rites chest placements in one category. Their trial activation and renewal are not yet verified, so unopened markers stay hidden with progression filtering enabled. Disable **Hide unobtainable chests** to preview their recorded positions; a preview does not mean the chest is currently available.
- Keep six Norgan rare chests with unresolved quest-variable requirements hidden while unopened with progression filtering enabled. The other 383 Norgan chest records have supported normal-world placement rules.
- Keep existing category choices, colors, artwork, collection GUIDs and first-token guidance. All 1,350 original bundled locations match the updated game's placement data.

Dark Arisen is optional. Base-game markers work without the expansion; DLC categories and collectible queries activate only when Steam confirms Dark Arisen is owned and installed. Unavailable or initializing DLC access leaves base-game features active and is retried later. DLC preferences are retained while the expansion is absent.

Uncollected DLC categories start enabled with the new Norgan artwork; collected markers start hidden. Saved visibility and artwork choices take precedence. Base-game chest defaults are unchanged. Norgan Ducats have their own **Hide Norgan Ducats in unexplored areas** control. Ducat history uses the game's current pickup flag; if it cannot be read, the menu reports the limitation and previously collected Ducats can remain visible. Nearby confirmed pickups and native never-generate records still hide acquired coins.

These are fixed placements extracted from the installed DLC. Random monster drops and appraised relic contents are not fixed collectible destinations. Loading an existing save and displaying markers on the full map and minimap passed an in-game check on Title Update 4.0 with compatible REFramework. Native DLC map routing, pickup/hand-in, save reload, and trial renewal still need in-game validation. This patch follows the stable 1.4.1 line; the separate 2.0 quest development build is preserved.

## What it does

- Shows tokens, beetles, and different types of chests on both maps.
- Omits the inaccessible sealed-room chest in Vernworth from both maps, including when showing collected items or previewing unobtainable chests.
- Lets you turn full-map and minimap markers on or off independently.
- Uses recognizable token and beetle symbols, with distinct artwork for small, medium, large, sunken and special chests.
- Shows simple names when you hover over full-map markers, such as **Chest (S)** and **Special Chest (L)**.
- Lets you choose which items to show, including items you have already collected.
- Refreshes chest data with 54 additions, removes two unsupported originals, and corrects one position while preserving retained collection IDs.
- Marks your first collected Seeker's Token in red, with an option to keep its location visible after Finder's Token collection.
- Hides unopened chests blocked by current world, quest and environment requirements by default, with an option to reveal Unmoored-only placements early.
- Independently hides chests, Golden Trove Beetles, or Seeker's Tokens in unexplored areas on both maps, with chests ignoring fog on cave and city local maps.
- Lets you change marker symbols and colors to suit your preferences.
- Starts with smaller icons and lets you adjust their size on both maps.
- Gives collectible markers priority over ordinary full-map game icons when they overlap.
- Keeps minimap symbols upright as you turn the camera.
- Shows minimap arrows for collectibles above or below you, with an adjustable height tolerance.
- Gives you more room for markers on both maps.
- Lets you adjust how far away nearby items appear and how many markers appear on the minimap.

Tokens and beetles are shown by default. Uncollected DLC categories and their artwork also start enabled when Dark Arisen is owned and installed. Turn on base-game chest categories in the mod's menu if you want to find those too. Saved choices take precedence.

## Install

You need [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8). Install it first.

1. Close the game and disable any other mod that adds collectable markers, so you do not see duplicates.
2. Install `Map-Markers-and-Collectables-by-Raze-v1.5.zip` with Fluffy Mod Manager. For a manual installation, open the ZIP and copy both its `reframework` and `natives` folders into your game folder, alongside `DD2.exe`.
3. Start the game. In the REFramework menu, open **Script Generated UI > Map Markers and Collectables by Raze**.
4. Choose the items you want to see, then explore with your full map or minimap.

## Make it your own

Use the category options to choose what appears on your maps and change its symbol or color. **Unacquired** means items you have not collected; **Acquired** means items you have already collected.

**Use object icons** sets the default artwork. Inside a category's **Unacquired Settings** or **Acquired Settings**, use **Artwork** to follow that default, choose a chest design, or choose **Game symbol** and set its **Icon Type**. Each state has its own color and reset button. Category overrides work with the global object-icon setting either on or off. Your existing colors, game symbols and category choices are kept.

New category color defaults are copper for small, silver for medium, gold for large, blue for extra-large/sunken, and purple for special chests. Acquired markers use a dimmer version. Existing saved colors take precedence; use a category's reset button to apply its new defaults. The crown-style Sphinx artwork is an optional symbol, not an additional Sphinx reward category.

Base-game chest data contains 637 small, 232 medium, 63 large, 82 extra-large/sunken, and six special chests split by size. Every source record matches the fresh game-data extraction; the inaccessible Vernworth sealed-room chest is omitted from map display. Two unsupported original locations were removed and one extra-large chest position was corrected. Current progression and collection state determine how many appear.

**Hide unobtainable chests** starts enabled. It filters unopened chests using their world, quest and environment conditions. **Reveal Unmoored-only chests early** starts disabled: normally those locations appear automatically in the Unmoored World. Enable it to preview recorded Unmoored-only placements early; separate quest and environment requirements still apply. Disable **Hide unobtainable chests** to preview recorded locations allowed by your category and fog settings. The inaccessible Vernworth sealed-room marker remains omitted.

Availability is checked per chest, independently of its size or artwork. Acquired markers follow the category's **Acquired** setting even when that location is currently unavailable. Three quest-controlled chest locations have unresolved availability and remain hidden while unopened with progression filtering on; the menu reports unresolved checks. Their placements exist in the fresh data, but their activation rules need further verification. The retained Sphinx reward datasets are not exposed as a category because their seal conditions are not yet verified.

Use **Show on full map** and **Show on minimap** to turn collectible markers on or off independently. Both start enabled. Changing the full-map toggle refreshes an open map and keeps your category, symbol, color, and size choices.

**Show first Seeker's Token** starts enabled. After your first Seeker's Token pickup, its location is marked in red on both maps to help you return for the Finder's Token. By default, the red marker disappears after you collect the Finder's Token. Enable **Show after Finder's Token collection** beneath this control to keep the saved location visible after collection or hand-in; this extra option starts disabled and requires **Show first Seeker's Token** to remain enabled. It reads the current playthrough's saved first-token and pickup state, including when installed later in a playthrough. No fresh save is required. Starting the Sphinx riddle does not hide the marker. It has its own visibility toggle and remains available when ordinary acquired tokens are hidden. It follows your token artwork, icon size, fog and map settings; minimap distance and height limits still apply.

Use **Hide chests in unexplored areas**, **Hide beetles in unexplored areas**, and **Hide Seeker's Tokens in unexplored areas** to choose which collectible types follow the map's fog of war. Each option works independently on both maps and starts disabled. Enable an option to show that type's markers only as their locations are revealed; your category and Acquired/Unacquired choices still apply.

The chest option covers regular and special chests on outdoor maps. Chests ignore fog on cave and city local maps, then follow your saved option again when the map returns outdoors. Your enabled chest categories, progression rules and Acquired/Unacquired choices still apply. Beetles and tokens continue to follow their own fog options on all maps.

If fog data is temporarily unavailable, markers that require a fog check stay hidden until it can be read, and the mod's menu shows a message. Chests on cave and city local maps do not require that fog data.

Under **Minimap settings**, you can change how far away items appear, limit markers above or below you, and choose how many nearby markers to show. Nearby items appear first. Lower the number if your minimap feels crowded.

**Show height indicators** adds an upward arrow above an item icon when it is higher than you, or a downward arrow below it when it is lower. It starts enabled. **Height tolerance (world units)** defaults to **3** and can be set from **0 to 30**; items within that difference have no arrow. The arrows work with object icons and game symbols and use the item's marker color. They show relative height, not the route to the item. Items beyond **Maximum height difference** remain hidden. On a crowded minimap, item icons take priority over arrows.

Use **Icon size (%)** to resize this mod's markers on both maps. The default is **50%** (half size), and the slider goes from **25% to 150%**.

## Need help?

If markers are missing, make sure the category is enabled and **Show on full map** or **Show on minimap** is turned on for that map. Check **Hide unobtainable chests** and the separate fog options. For minimap markers, also check that the game's minimap is visible. There may be no matching items close enough to you.

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
