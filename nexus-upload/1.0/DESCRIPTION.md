# Map Markers and Collectables by Raze

**Version 1.0**

Find Seeker's Tokens, Golden Trove Beetles, and chests with customizable markers on your full map and minimap. Choose the categories, icons, and colors you want, and keep nearby collectables in view while exploring.

## Features

- Full-map and nearby minimap markers for Seeker's Tokens, Golden Trove Beetles, four chest sizes, and three special chest categories.
- Separate visibility, icon, and color controls for acquired and unacquired items.
- Shared category settings across both maps, with category priority controls.
- Minimap symbols stay upright when you turn the camera.
- Adjustable minimap distance, height, and custom-marker limits.
- **2,048 total full-map sprite slots** and **256 total minimap slots**, with up to **200 custom minimap markers**. Native game icons take priority.
- Dedicated settings storage and runtime diagnostics.

## Requirements

Install [REFramework for Dragon's Dogma 2](https://www.nexusmods.com/dragonsdogma2/mods/8) before this mod. Fluffy Mod Manager is optional; manual installation is supported.

## Installation

1. Close the game and disable any other collectable-marker scripts to avoid duplicate markers.
2. Import `Map-Markers-and-Collectables-by-Raze-v1.0.zip` into Fluffy and enable it, or extract the ZIP's `reframework` folder into the game folder containing `DD2.exe`.
3. Launch the game and expand **REFramework > Script Generated UI > Map Markers and Collectables by Raze**.
4. Choose your categories, show the minimap, and open the full map.

## Settings

Tokens and beetles are enabled by default. Enable chest categories in the menu if you want to see them.

**Show on minimap** enables nearby markers. **Minimap settings** controls:

| Setting | Default | Range |
|---|---:|---:|
| Search radius | 180 world units | 25â€“300 |
| Maximum height difference | 60 | 10â€“150 |
| Maximum custom icons | 24 | 1â€“200 |

The nearest eligible locations are selected first. The number drawn can be lower than the limit because of the minimap boundary, category filters, collected state, or space used by native icons. Higher counts can increase clutter and rendering work.

Preferences are stored in `reframework/data/raze_MapMarkersAndCollectables_settings.json`. Keep this file when updating. Missing or malformed settings use defaults.

## Compatibility and troubleshooting

- Other collectable-marker scripts can create duplicates. Mods that modify map icon pools may conflict; compatibility with every UI mod has not been verified.
- If no minimap markers appear, check that the game's minimap is visible, **Show on minimap** is enabled, and eligible items are within the distance and height ranges.
- After replacing Lua files while the game is running, use **REFramework > ScriptRunner > Reset scripts** or restart the game.
- For errors, include the message and `re2_framework_log.txt` in a bug report. The included **Diagnostics** menu can export a runtime report.

## Testing

Both maps, camera rotation, category toggles, and script reloads have been checked in game with REFramework TDB 83. The full map displayed 1,272 custom markers plus three native icons. Markers beyond the previous capacity cleared and returned correctly when their category was toggled.

The maximum 200-marker minimap load has automated test coverage but has not been reached naturally in the live test area. Collection removal and save/load behavior still need broader in-game testing.

## Uninstall

Close the game and disable the mod in Fluffy. For a manual installation, remove:

- `reframework/autorun/raze_MapMarkersAndCollectables.lua`
- `reframework/autorun/raze_MapMarkersAndCollectables_Diagnostics.lua`
- `reframework/autorun/raze_MapMarkersAndCollectables/`
- `reframework/data/raze_MapMarkersAndCollectables/`

Keep the separate settings JSON to retain your preferences. Leave REFramework installed for your other mods.

## Credits

**Raze** â€” this adaptation, minimap support, expanded icon capacity, settings validation, and diagnostics.

**[gibbed](https://github.com/gibbed)** â€” [Arisen's Almanac](https://www.nexusmods.com/dragonsdogma2/mods/194), the original full-map implementation, and the location datasets. Source and dataset attribution is retained in `THIRD_PARTY_NOTICES.md` in the download.
