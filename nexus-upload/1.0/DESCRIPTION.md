# Map Markers and Collectables by Raze

**Version 1.0**

Spend less time searching and more time exploring. This mod shows Seeker's Tokens, Golden Trove Beetles, and chests on your full map, with nearby items also appearing on your minimap.

## What you can do

- **Find collectables:** see where tokens, beetles, and different types of chests are located.
- **Explore with your minimap:** spot nearby items without opening the full map.
- **Choose what appears:** show only the items you are looking for, with separate options for things you have already collected.
- **Make markers easy to recognize:** change their symbols and colors.
- **Keep your map comfortable to use:** adjust how far away items appear and how many nearby markers you see.
- **See more at once:** both maps have more room for markers.

Minimap symbols stay upright as you turn the camera. Your choices are saved for your next play session.

## Getting started

Install [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8) first.

1. Close the game and disable other collectable-marker mods to avoid duplicate markers.
2. Install the downloaded ZIP with Fluffy Mod Manager. If you prefer to install manually, open the ZIP and copy its `reframework` folder into your game folder, alongside `DD2.exe`.
3. Start the game and open **REFramework > Script Generated UI > Map Markers and Collectables by Raze**.
4. Choose what you want to see and start exploring.

**Tokens and beetles are shown by default.** Enable chest categories in the menu to show chests too.

## Choosing your markers

Each category lets you choose whether its markers appear and which symbol and color they use. In the menu, **Unacquired** means items you have not collected, and **Acquired** means items you have already collected.

Use **Show on minimap** to turn nearby markers on or off. Open **Minimap settings** to change how far away items can be, limit items above or below you, and set how many markers appear. Nearby items are shown first. If the minimap feels crowded, lower the number or hide categories you do not need.

## Need help?

- **No markers?** Check that the item category is enabled.
- **Nothing on the minimap?** Make sure the game's minimap is visible and **Show on minimap** is on. The nearest matching item may be too far away or too far above or below you.
- **Duplicate markers?** Disable other mods that add collectable markers.
- **Just installed or updated?** Restart the game.
- **Seeing an error?** Include the error message when reporting it. Other mods that change the map may conflict.

## Updating or removing the mod

To update, replace the mod's files with the new download. Keep `reframework/data/raze_MapMarkersAndCollectables_settings.json` to keep your choices.

To remove the mod, close the game and disable it in Fluffy Mod Manager. For a manual installation, remove:

- `reframework/autorun/raze_MapMarkersAndCollectables.lua`
- `reframework/autorun/raze_MapMarkersAndCollectables_Diagnostics.lua`
- `reframework/autorun/raze_MapMarkersAndCollectables/`
- `reframework/data/raze_MapMarkersAndCollectables/`

You can keep the settings file if you plan to reinstall. Leave REFramework installed if your other mods use it.

## Credits

**Raze** - this adaptation, minimap support, and improvements to marker display and settings.

**[gibbed](https://github.com/gibbed)** - [Arisen's Almanac](https://www.nexusmods.com/dragonsdogma2/mods/194), the original full-map code and collectable locations. Full source credits are included in `THIRD_PARTY_NOTICES.md` in the download.
