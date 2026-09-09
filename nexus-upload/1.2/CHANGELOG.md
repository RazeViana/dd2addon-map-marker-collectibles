# Changelog

## 1.2 (2026-09-09)

- Add minimap height arrows: upward above higher collectibles and downward below lower collectibles, with a visibility toggle and adjustable height tolerance.
- Add a **Show on full map** toggle so full-map and minimap collectible markers can be enabled independently.
- Avoid the reported full-map `newindex` script error when assigning marker names by applying hover labels through the existing text-display hook.

## 1.1

- Fix collectible icons appearing at different sizes after zooming the full map by sizing them from the current map zoom instead of each reused slot's previous scale.
- Move packaged documentation into this mod's own folder to remove Fluffy overwrite warnings with Crowded Cities and other mods that include a root README.
- Fix previously collected beetle markers reappearing when approaching their locations by honoring the collection state already recorded in the loaded save.

## 1.0

First release of Map Markers and Collectables by Raze.

- Find Seeker's Tokens, Golden Trove Beetles, and chests on the full map and minimap.
- Choose which items to show, including items you have already collected.
- Customize marker symbols and colors.
- Start with half-size icons and adjust their size on both maps with a 25–150% slider.
- Recognize tokens, beetles, chests, and special chests by their own symbols, with an option to use the game's symbols instead.
- Read simple hover labels on the full map, including Chest (S/M/L/XL) and Special Chest (S/M/L).
- Keep minimap symbols upright while turning the camera.
- Show more markers on both maps.
- Adjust how far away items appear and how many nearby markers you see.
- Keep your preferences between play sessions.
