# Map Markers and Collectables by Raze 1.5

This unpublished Dark Arisen test patch adds 140 Norgan Ducat placements and 389 Norgan chests, split into ordinary and rare categories. It includes three new object icons and preserves the native map symbol added in Title Update 4.0. All 1,350 earlier collectible locations still match the updated game data.

Dark Arisen is optional. Base-game markers work without the expansion; DLC controls and queries activate only when Steam confirms ownership and installation. Uncollected DLC categories and the new artwork start enabled, while collected markers start hidden. Saved choices take precedence, and DLC preferences are retained if the expansion is absent. Appearance reset restores the category's artwork.

The package retains 185 fixed Lost Rites chest placements in one category. Trial activation and renewal are unverified, so unopened trial markers remain hidden with progression filtering enabled. Six Norgan rare chests with unresolved quest-variable requirements also remain hidden. Disable **Hide unobtainable chests** only to preview those placements; their presence on the map does not establish current availability.

Norgan Ducats have a separate fog switch and use the game's native pickup flag. If history cannot be read, the menu reports the limitation; already collected Ducats can remain visible. Existing category choices, colors, collection IDs and first-token guidance are retained, including the 1.4.1 Finder correction and retention preference. Separate quest-development settings are preserved, but the 2.0 quest overlay is not part of this stable-line test patch.

Automated runtime, data, provenance, atlas and package checks passed. Loading an existing save and displaying full-map/minimap markers passed an in-game check on Title Update 4.0 with compatible REFramework. Native DLC map routing, pickup/hand-in, save reload and trial renewal remain pending. The package does not repair an incompatible REFramework or graphics injector.

Close DD2 and install the complete ZIP with Fluffy Mod Manager. For manual installation, copy both **reframework** and **natives** beside DD2.exe, then restart. Keep reframework/data/raze_MapMarkersAndCollectables_settings.json. Disable other collectible-marker mods to avoid overlapping overlays.

Requires a [REFramework build compatible with your game update](https://github.com/praydog/REFramework-nightly/releases/latest). Source credits and notices are included in docs/raze_MapMarkersAndCollectables/THIRD_PARTY_NOTICES.md.
