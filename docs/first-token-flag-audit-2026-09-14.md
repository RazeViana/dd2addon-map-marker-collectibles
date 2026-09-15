# First-token marker flag correction

## Report and cause

The red first Seeker's Token marker was absent after starting the Sphinx quest even though the Finder's Token had not been collected. No unavailable-state message appeared.

Version 1.4 used `GimmickManager:isGimmickFlag(18)` as its completion check. That is the token's display flag. A true result intentionally returned no overlay and no error, matching the report. The saved first-token lookup itself does not require the mod to have been installed when that token was collected.

The earlier prefab interpretation used a stale inherited-field layout. It omitted `app.GimmickBase.WetCtrl`, shifting the interpretation of the following flag values by four bytes. The old audit's claim that `GmFlagGetBeginner` equals 18 is superseded by this document.

## Corrected native evidence

Installed executable: Dragon's Dogma 2 version 3.2.0.0, TDB 83. The local extraction of `natives/stm/appsystem/gimmick/prefab/gm82_036.pfb.18` has SHA-256:

```text
8ef29324640660245de5ae88587fe2eed1dbb3e9871b29a7bc160d96c86a8fe2
```

Component 37 is `app.Gm82_036` (type `726c7d9f`, serialized CRC `c483caaa`), starting at file offset `0x1030`. The relevant tail is:

| File offset | Serialized field | Value | Native enum |
| --- | --- | --- | --- |
| `0x10b4` | `_StartPositionNaviMeshRange` | `1.0` | — |
| `0x10b8` | `_TargetPositionNaviMeshRange` | `1.0` | — |
| `0x10bc` | `WetCtrl` | `0` (null reference) | — |
| `0x10c0` | `GmFlagGet` | `40` | `GmFlag_Get_Item_0` |
| `0x10c4` | `GmFlag` | `18` | `GmFlag_Item_Disp_0` |
| `0x10c8` | `GmFlagGetBeginner` | `122` | `GmFlag_Get_Item_1` |

TDB metadata independently identifies `WetCtrl` as an `app.WetController` field on the base type, all three flag fields as `app.GimmickFlag`, and `isGimmickFlag(app.GimmickFlag)` as returning a boolean. The saved `GimmickManager.GameSaveData` contains both `FirstSeekerProof` and `GmFlagBits`.

The next inline component provides an independent boundary check. Instance 38 is external `Job09_00_HintData` userdata. Instance 39, `app.Job09_00_HintController`, starts at `0x10cc` with enabled byte 1, a valid object GUID at `0x10d0`, `_Data = 38` at `0x10e0`, and `IsNearest = false` at `0x10e4`. Instance 40 is external sound userdata. Instance 41, `app.WwiseContainerApp`, follows at `0x10e5`, references `[40]`, contains distances `30.0` and `0.05`, and ends at `0x10fc`. These neighboring values agree with the corrected component boundary.

The extracted Sphinx `resident.scn.21` also contains a flag-setting parameter with flag ID 18 and status 0 (`True`), referenced by a `GimmickOptionSetting`. This supports its role in quest-controlled display. The complete scene has not been decoded successfully with the retained schemas, so this audit does not claim to have verified every processor condition or the scene's complete control flow.

This is a targeted correction of the token component. Other stale-schema differences exist; adding `WetCtrl` is not a general repair of the RSZ schema or a claim that the entire prefab passed full parsing.

## Runtime change

The marker now checks saved pickup flag 122. Display flag 18 and ordinary-token pickup flag 40 do not hide it. There is no quest-acceptance, journal-selection or installation-time requirement. It continues to use the saved first-token GUID and existing token coordinates.

The change adds no save writes, pickup hooks, inventory dependence or persistent completion cache. Loading another save or NG+ follows that save's first-token ID and pickup flag. Existing marker visibility, fog and minimap distance/height preferences still apply.

## Verification

The module and complete-map regression tests independently model the display, ordinary pickup and Finder pickup flags. Both tests failed against the old flag-18 implementation at Sphinx display activation and passed after the correction.

Coverage includes:

- A saved first-token location from before installation, before the riddle starts.
- Installing during the riddle with the Finder displayed but not collected.
- Enabling Finder display while the full map is open and minimap candidates are cached.
- Removing the overlay on Finder pickup on both maps.
- Keeping it removed when display is later cleared, including a newly created tracker after pickup.
- Loading a different first-token ID with an uncollected Finder state.
- Existing category independence, artwork, visibility toggle, fog, and unavailable-state handling.

Automated tests emulate native reads. Raze confirmed on 2026-09-15 that the corrected test patch works in-game. The report does not enumerate actual Finder pickup/hand-in or native NG+ flag reset, so those individual scenarios are not described as live-tested.

The separate 2.0 development tree passed 15 Lua test files, 29 Python tests, syntax and asset checks, and its package build during the initial correction. These counts refer to that tree, not the v1.4.1 package. The published `v1.4` source was also tested in an isolated temporary directory with only the corrected module and updated first-token regression fixtures; both module and full-map/minimap tests passed.

A local, unpublished v1.4 test patch contains only `reframework/autorun/raze_MapMarkersAndCollectables/first_token.lua`. Its payload differs from the published v1.4 module only in the pickup flag and explanatory comments. It requires the complete v1.4 mod already installed: close the game, extract the patch into the game folder beside `DD2.exe`, allow replacement of that one file, then restart. It does not contain the 2.0 quest features.

## Version 1.4.1

The complete v1.4.1 package includes this correction and supersedes the one-file test patch. It also adds the opt-in **Show after Finder's Token collection** control, which bypasses the pickup-state check while keeping the saved first-token location, main visibility switch, token fog and map/range settings. The option starts disabled, so automatic removal remains the default. No first-token location can be shown until the current playthrough has recorded one.

On 2026-09-15, the isolated v1.4.1 tree passed all 12 Lua test files, 13 Python tests, runtime/development syntax and asset checks. The 31-file package retains the v1.4 dataset and artwork bytes; only version metadata, player documentation, the entry-point Lua file, `first_token.lua` and `settings.lua` change. Automated retention coverage includes both maps, cached minimap candidates, saved preferences, the main switch, missing saved locations and token fog. The new retention option has not yet been confirmed in-game.
