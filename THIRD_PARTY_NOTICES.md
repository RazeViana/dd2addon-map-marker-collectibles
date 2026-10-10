# Third-party notices

**gibbed** created Arisen's Almanac, the original full-map implementation used in this adaptation, and the location datasets. Map Markers and Collectables by Raze retains adapted source and 1,296 locations from the original 1,298 entries. Dataset credits are centralized here; dataset metadata points to this file.

Version 1.4 adds 54 chest placements read from the installed game's version 3.2.0.0 resources, removes two original chest GUIDs absent from the extraction, and corrects one original chest coordinate. The resulting location total is 1,350. Retained GUIDs are unchanged. Supplemental source metadata distinguishes additions from original datasets; the development manifest preserves original provenance and explicitly records retirements and coordinate corrections. Chest availability metadata is derived from the game's placement records and catalog references.

- [Original mod](https://www.nexusmods.com/dragonsdogma2/mods/194)
- [Original source](https://github.com/gibbed/DD2-REFramework-Scripts/blob/main/gibbed_Almanac.lua)
- [Minimap investigation reference](https://github.com/gibbed/DD2-REFramework-Scripts/blob/main/gibbed_MinimapTest.lua)
- [First-token saved-ID investigation reference](https://github.com/gibbed/DD2-REFramework-Scripts/blob/main/gibbed_RiddleOfRuminationMarker.lua)
- [Original author's profile](https://github.com/gibbed)

**Raze** maintains this adaptation and its identity, nearby minimap rendering, upright symbols, expanded icon capacity, settings validation, error handling, and diagnostics. Compatibility changes already present in the supplied source are retained; their separate authorship has not been independently established.

The twelve object-marker designs are included as SVG source: the original eight, three Norgan symbols and a Spoils chest symbol. The extended atlas layouts retain Dragon's Dogma 2's native UV coordinates and reference its installed map textures; those game textures remain Capcom's assets and are not bundled in this download. The UVS and TEX file formats were checked against [REE-Lib](https://github.com/kagenocookie/RE-Engine-Lib) and [RE Engine 010 Templates](https://github.com/alphazolam/RE-Engine-010-Templates).

Dark Arisen placement additions and trial map associations are extracted from the installed Title Update 4.0 game resources. Version 1.5 includes 714 DLC records. Version 1.5.1 adds 97 missing native chest records, bringing DLC coverage to 811 records and the full data total to 2,161. Potential repeatable locations do not establish active events, unlock conditions or guaranteed loot.

The upstream Nexus permissions checked on 2026-09-06 require permission for modification and asset reuse and disallow Donation Points for mods using the assets. Permission has not been obtained. This notice preserves attribution and does not grant redistribution rights. [Nexus submission guidelines](https://help.nexusmods.com/article/28-file-submission-guidelines) distinguish attribution from permission.
