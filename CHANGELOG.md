# Changelog

## 1.5 (test patch, 2026-10-09)

- Add 140 Norgan Ducat and 389 Norgan chest placements from the installed Dark Arisen DLC, with separate ordinary/rare categories and three new object icons.
- Enable uncollected DLC categories and their new artwork by default, including when the legacy global preference uses game symbols. Retain saved appearance/visibility choices and restore category artwork when resetting its appearance.
- Keep the DLC optional: gate expansion controls and collectible queries on Steam ownership/installation, retain DLC preferences when absent, and refresh map caches when access becomes available or is lost.
- Split progression and chest-fog filters into independent base-game and DLC settings. Preserve the old shared values when upgrading. Group the UI into Maps and appearance, Base game and Dark Arisen, including category rows, group-specific availability messages and ordering within each group.
- Omit the inaccessible Vernworth sealed-room chest from both maps in either collection state, even when previewing unobtainable chests. Keep its source record for data reconciliation.
- Preserve the native map symbol appended by Title Update 4.0 on both maps. Retain the original eight custom designs and all earlier native atlas entries.
- Add an independent Ducat fog setting. Read its native static pickup flag instead of assuming the Seeker's Token bit, and report unavailable history reads.
- Retain 185 fixed Lost Rites chest placements in one category, with acquisition refreshed instead of permanently cached. Hide unopened trial placements until activation rules are verified; explicit progression-filter overrides can preview them.
- Keep six quest-variable-controlled Norgan rare chests hidden with progression filtering enabled. Do not infer activation from a catalog entry alone.
- Verify all 1,350 existing locations against effective Title Update 4.0 base and DLC files without changing their GUIDs or coordinates.
- Include the unpublished 1.4.1 Finder's Token correction and retention option. Preserve existing collectible settings and any separate quest development preferences.
- Add import, provenance, gate, pickup-mask, category and atlas regressions. Existing-save loading and full-map/minimap markers passed an in-game check on Title Update 4.0 with compatible REFramework. This package is unpublished; native DLC acceptance remains pending.

## 1.4.1 (2026-09-15)

- Fix the first Seeker's Token marker disappearing when the Sphinx riddle begins, before the Finder's Token is collected.
- Read the game's saved first-token location and Finder pickup state, including when installing into an existing playthrough. No fresh save is required.
- Add **Show after Finder's Token collection**, disabled by default, to keep the red first-token location visible after collecting or handing in the Finder's Token.
- Save the new preference and refresh it on both maps. The main first-token switch, token fog and map settings, and minimap distance and height limits still apply.

## 1.4 (2026-09-14)

- Add **Show first Seeker's Token**, enabled by default: a red marker on both maps at the saved first-token location, removed after collecting the Finder's Token. Keep its visibility independent of ordinary Acquired/Unacquired token filters, replace duplicate token markers, and refresh it across pickups and save changes.
- Add 54 chest locations: 39 small and 15 medium. Reconcile the original list against the fresh extraction: remove one small and one extra-large chest GUID absent from the extracted resources, and correct one extra-large chest position by about 1.31 world units. All remaining chest GUIDs and types match the fresh data; preserve their identities for saved collection tracking.
- Honor saved chest collection history even when a nearby loaded object reports closed. Previously opened chests remain tracked when installing into an existing save; loading another save clears cached acquisition.
- Add **Hide unobtainable chests**, enabled by default, using per-location world, quest and environment rules. Add **Reveal Unmoored-only chests early**, disabled by default, without bypassing separate quest or environment conditions. Acquired history remains controlled by each category's acquired setting.
- Keep unresolved unopened locations hidden with a menu message while progression filtering is enabled. Three existing quest-controlled locations have unresolved activation rules; all 54 additions have supported metadata. Sphinx reward datasets remain retained but are not exposed as a category.
- Add distinct small, large and sunken chest artwork, optional crown artwork, category color defaults, and independent acquired/unacquired artwork selectors. Preserve saved symbols, colors, visibility and ordering; retain native atlas patterns.
- Raise collectible markers above ordinary full-map game markers to address overlaps such as Dragon's Gaze Wakestone shard icons covering Seeker's Tokens at smaller icon sizes. Keep the chosen marker size and position, and restore the original drawing priority when slots are reused or scripts reset.
- Make **Hide chests in unexplored areas** apply only on outdoor maps. Regular and special chests ignore fog on cave and city local maps, then follow the saved option again outdoors. Category and Acquired/Unacquired choices still apply on both maps; beetle and token fog options remain independent.

## 1.3 (2026-09-10)

- Add independent **Hide chests in unexplored areas**, **Hide beetles in unexplored areas**, and **Hide Seeker's Tokens in unexplored areas** toggles for the full map and minimap. The chest option covers regular and special chests.
- All three fog options default off and preserve category and Acquired/Unacquired choices. Updating the earlier chest-only 1.3 package preserves its chest preference.
- Update minimap visibility as fog clears, including while nearby collectible positions are cached. Hidden collectibles do not count toward the minimap marker limit.
- Keep affected markers hidden when fog data is temporarily unavailable, with a status message in the mod menu and automatic recovery once the data is ready.

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
- Start with half-size icons and adjust their size on both maps with a 25â€“150% slider.
- Recognize tokens, beetles, chests, and special chests by their own symbols, with an option to use the game's symbols instead.
- Read simple hover labels on the full map, including Chest (S/M/L/XL) and Special Chest (S/M/L).
- Keep minimap symbols upright while turning the camera.
- Show more markers on both maps.
- Adjust how far away items appear and how many nearby markers you see.
- Keep your preferences between play sessions.
