# Map Markers and Collectables by Raze Implementation Plan

**Goal:** Rebuild the supplied mod under the requested identity, preserve its full-map behavior and location data, and add nearby minimap markers.

**Architecture:** Keep the supplied map implementation and compatibility fixes. Isolate settings normalization, nearby selection, sprite lifecycle, and runtime diagnostics in small Lua modules. Render nearby markers after `app.ui020301.updateIcon` using unused native sprite slots and `getIconPos`; restore borrowed slots before each native update. Share category settings between the two maps, with a separate minimap toggle, distance/height filters, and marker cap. Ship one map entry point and an independent diagnostic entry point.

**Tech stack:** REFramework Lua, JSON datasets, Python with Lupa for offline tests and ZIP packaging.

**Constraints:** Use the exact display name `Map Markers and Collectables by Raze`; author `Raze`; internal prefix `raze_MapMarkersAndCollectables`. Preserve original source attribution and dataset provenance. No invented minimap method signatures. No game-save changes. No Git repository exists in the supplied directory.

- [x] Preserve the supplied package in `reference/almanac-source.zip` before changing files.
- [x] Test settings loading with absent, malformed, legacy, and current settings; verify category ordering, invalid values, and one-time migration.
- [x] Rename runtime/data paths and metadata; extract settings normalization; retain GUID and icon-pool compatibility fixes; guard missing managers during transitions and report write failures.
- [x] Test diagnostic collection against absent types, overloaded methods, inherited fields, and partial reflection failures. Implement metadata-only export using documented REFramework reflection APIs.
- [x] Create installation/migration instructions and a package builder that includes runtime files and documentation only. Exclude the old preview, original backup, tools, and saved settings.
- [x] Run Lua syntax and behavioral tests, verify all 12 dataset hashes against the backup, and inspect the built ZIP.
- [x] Stage the diagnostic entry point for the user's game installation.
- [x] Obtain runtime reports and implement native minimap rendering using verified interfaces.
- [x] Confirm visible minimap markers in game: Raze reports eight custom icons.
- [x] Reproduce camera-driven glyph rotation and failed slot restoration in offline tests, then fix both.
- [x] Confirm upright glyphs after reloading the fix in game: Raze verified they stay upright when the camera turns.
- [x] In-game follow-up: full-map/minimap transitions and the minimap visibility toggle work, confirmed by Raze.

Additional playtesting beyond these confirmed checks: collection removal and save/load behavior. Offline tests cover collection refresh and missing-player state; native save/load behavior has not been confirmed.

**Evidence:** Before adaptation, the supplied and installed Almanac scripts had identical SHA-256 hashes. The author's `gibbed_MinimapTest.lua` only inspects the minimap and toggles backgrounds. Reports in `reference/runtime/minimap-types-2026-09-06.json` and `minimap-probe-2026-09-06.json` verify TDB 83, `updateIcon`, `getIconPos`, and a 50-slot `MapIconList` of `app.GUIBase.MapIconSpriteRef`. Runtime hooks loaded without a minimap error. Raze subsequently showed the previously hidden HUD and confirmed eight custom markers, then reported their symbols turning with the camera. The fix replaces directional heading conversion with zero glyph rotation; marker positions still use the game's projection.

**Verification (2026-09-06):** Five Lua test files pass under Lua 5.4. Coverage includes the full-map fixture, settings migration/validation, diagnostics, nearby selection, native slot priority, state restoration, acquired-marker refresh, and missing-player handling. Both rotation and partial restoration regressions failed before their respective fixes and pass afterward. All runtime Lua files compile. All 12 datasets remain byte-identical to the supplied package and contain 1,298 positions. Review found a restoration failure-path issue; the corrected implementation restores each slot independently and retains failed snapshots for retry. Follow-up review found no remaining actionable issue in those fixes.

**Installation:** Six Lua files and 12 location datasets are installed under `E:/SteamLibrary/steamapps/common/Dragons Dogma 2/reframework`. The rotation and restoration fixes were copied with SHA-256 verification. The old entry point is preserved as `gibbed_Almanac.lua.disabled-by-raze`, with another copy in `reference/runtime/installed-almanac-before-minimap.lua`. Original settings/data are preserved; the new settings file was migrated successfully. The pre-fix minimap module is backed up in `reference/runtime/minimap-before-upright-fix.lua`. The package version is 1.1.0; runtime reports, backups, development scripts, and user settings are excluded.

**Release:** `dist/Map-Markers-and-Collectables-by-Raze-v1.1.0.zip` contains 21 files. All 18 installed runtime files match the project by SHA-256. REFramework logged the fixed script loading at 20:57:11 without a minimap error; Raze confirmed camera rotation, both maps, and the visibility toggle afterward.

## Expanded icon capacity — version 1.2.0

Raze requested higher limits on both maps. A native probe established a 1,024-slot full-map sprite array and a 50-slot minimap list. The new pool module preserves existing entries, clones initialized sprite references and their foreground/background sprites, then expands the full map to 2,048 slots and the minimap to 256. The custom minimap allowance is adjustable to 200; the default remains 24 and existing settings are retained. Raze's installed limit was raised to 200 through the mod menu.

- [x] Verify native sprite allocation, array allocation, atlas context, and sprite-set attachment interfaces.
- [x] Test expansion, preservation of native slots, reuse after script reset, cached failures, and recreated HUDs.
- [x] Cover 200 custom minimap markers alongside 56 native icons and restoration of all borrowed slots.
- [x] Correct reflection writes to use `REManagedObject:set_field` and allocate the parameterized icon wrapper with simplified construction before copying initialized fields.
- [x] Install the corrected runtime and confirm both capacities without a new script error.
- [x] Verify 1,272 custom full-map markers plus three native icons, with 773 slots free. Disable small chests to reduce the custom count to 683, then restore 1,272.
- [x] Confirm the 256-slot minimap survives another script reset and continues showing nearby markers.
- [x] Verify all six Lua test files and runtime syntax; compare all 19 installed runtime/data files to the project by SHA-256.
- [x] Probe native full-map visibility across category changes: total visible sprites 1,275 → 686 → 1,275; visible slots at indices 1,024 and above 251 → 0 → 251. Save the error-free report to `reference/runtime/icon-capacity-cleanup-2026-09-06.json` and remove the temporary installed probe.

The capacity probe and native reports are development-only. The version 1.2.0 package contains 22 runtime, data, and documentation files. The live test area has not naturally reached 200 simultaneous minimap markers; that maximum has offline stress coverage. Collection and save/load checks remain as noted above.

## Public release preparation — version 1.0

At Raze's request, public numbering starts at 1.0 and includes the completed minimap and capacity work. Updated the UI label, diagnostic metadata, mod metadata, README, and package filename. The builder derives the archive version from `modinfo.ini` and checks the UI, diagnostics, and README for agreement. Added the initial changelog and prepared `nexus-upload/1.0/` with the archive, listing fields, BBCode description, gameplay image, checksum, and upload notes. Original credits remain at the bottom of the Nexus description and in the source/data notices. No gameplay logic was changed for this release preparation.

The original Nexus page's permissions were checked on 2026-09-06. They require permission for modification and asset reuse and prohibit Donation Points for mods using the assets. Raze confirmed permission has not been obtained and requested bottom-of-page credit. The local upload kit records the outstanding publication permission; nothing was published or sent to the original author.
