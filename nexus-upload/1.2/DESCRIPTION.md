# Map Markers and Collectables by Raze

**Version 1.2**

Spend less time searching and more time exploring. This mod shows Seeker's Tokens, Golden Trove Beetles, and chests on your full map, with nearby items also appearing on your minimap.

## What you can do

- **Find collectables:** see where tokens, beetles, and different types of chests are located.
- **Know what you are looking at:** tokens, beetles, chests, and special chests have their own recognizable symbols. Hover over a full-map marker to see its name, such as **Chest (M)**.
- **Explore with your minimap:** spot nearby items without opening the full map.
- **See relative height:** arrows above or below minimap icons tell you whether the item is higher or lower than you.
- **Choose your maps:** turn full-map and minimap collectible markers on or off independently.
- **Choose what appears:** show only the items you are looking for, with separate options for things you have already collected.
- **Make markers easy to recognize:** change their symbols and colors.
- **Choose a comfortable size:** icons start at half size, with a size slider for both maps.
- **Keep your map comfortable to use:** adjust how far away items appear and how many nearby markers you see.
- **See more at once:** both maps have more room for markers.

Minimap symbols stay upright as you turn the camera. Your choices are saved for your next play session.

## Getting started

Install [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8) first.

1. Close the game and disable other collectable-marker mods to avoid duplicate markers.
2. Install the downloaded ZIP with Fluffy Mod Manager. If you prefer to install manually, open the ZIP and copy both its `reframework` and `natives` folders into your game folder, alongside `DD2.exe`.
3. Start the game and open **REFramework > Script Generated UI > Map Markers and Collectables by Raze**.
4. Choose what you want to see and start exploring.

**Tokens and beetles are shown by default.** Enable chest categories in the menu to show chests too.

## Choosing your markers

Each category lets you choose whether its markers appear and which symbol and color they use. In the menu, **Unacquired** means items you have not collected, and **Acquired** means items you have already collected.

**Use object icons** is on by default. Turn it off if you prefer the game's symbols; your saved symbol choices and colors are kept. Chest names use **S**, **M**, **L**, and **XL** for small, medium, large, and extra large. Special chests use a chest symbol with a sparkle.

Use **Show on full map** and **Show on minimap** to turn collectible markers on or off independently. Both start enabled. Changing the full-map toggle refreshes an open map and keeps your category and appearance preferences.

Open **Minimap settings** to change how far away items can be, limit items above or below you, and set how many markers appear. Nearby items are shown first. If the minimap feels crowded, lower the number or hide categories you do not need.

**Show height indicators** starts enabled. An upward arrow above an icon means the item is higher than you; a downward arrow below it means it is lower. **Height tolerance (world units)** defaults to **3** and can be set from **0 to 30**. Items within that difference have no arrow. Arrows work with object icons and game symbols, use the item's color, and stay upright. They show relative height, not the route to the item. Items beyond **Maximum height difference** remain hidden. Item icons take priority over arrows if the minimap runs out of room.

**Icon size (%)** changes the size of this mod's markers on both maps. It starts at **50%** and can be adjusted from **25% to 150%**.

## Need help?

- **No markers?** Check that the item category and the corresponding **Show on full map** or **Show on minimap** option are enabled.
- **No height arrows?** Enable **Show height indicators** under **Minimap settings**. An item may be within the height tolerance, or its arrow may fall outside the minimap boundary.
- **Nothing on the minimap?** Make sure the game's minimap is visible and **Show on minimap** is on. The nearest matching item may be too far away or too far above or below you.
- **Duplicate markers?** Disable other mods that add collectable markers.
- **Just installed or updated?** Restart the game.
- **Seeing an error?** Include the error message when reporting it. Other mods that change the map may conflict.

## Updating or removing the mod

To update, install the complete new download, including both the `reframework` and `natives` folders so the arrow artwork is available. Restart the game afterward. Keep `reframework/data/raze_MapMarkersAndCollectables_settings.json` to keep your choices.

To remove the mod, close the game and disable it in Fluffy Mod Manager. For a manual installation, remove:

- `reframework/autorun/raze_MapMarkersAndCollectables.lua`
- `reframework/autorun/raze_MapMarkersAndCollectables/`
- `reframework/data/raze_MapMarkersAndCollectables/`
- `natives/stm/raze/mapmarkers/`
- `docs/raze_MapMarkersAndCollectables/`

You can keep the settings file if you plan to reinstall. Leave REFramework installed if your other mods use it.

## Credits

**Raze** - this adaptation, minimap support, and improvements to marker display and settings.

**[gibbed](https://github.com/gibbed)** - [Arisen's Almanac](https://www.nexusmods.com/dragonsdogma2/mods/194), the original full-map code and collectable locations. Full source credits are included in `docs/raze_MapMarkersAndCollectables/THIRD_PARTY_NOTICES.md` in the download.
