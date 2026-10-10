# Chest Coverage Implementation Plan

**Goal:** Add the omitted chest families from the current game scan and make Lost Rites locations usable without disabling the general DLC filter.

**Architecture:** Extend the existing audited JSON/import pipeline and category registration. Route trial markers with source-derived map IDs and bounds, and handle repeatable acquisition separately from permanent base-game pickups.

**Tech Stack:** Python 3.12, Lua 5.4/REFramework, SVG/Sharp, existing package builder.

**Spec:** ../specs/2026-10-10-chest-coverage.md

## Global Constraints

- Version 1.5.1; master default branch; preserve released v1.5 and unrelated quest work.
- Exact GUIDs and positions from the installed game, no inferred unlock conditions or floor assignments.
- Preserve non-owner support and saved category/artwork preferences.
- Nexus main file description is plain text, 1–250 characters; aligned release documents.
- No assistant/provider contributor attribution.

## Review Focus

- Alternate identities at a shared position must remain distinct for native collection lookup.
- A selected remote trial must route by the displayed UI area, not player location.
- A renewed loaded chest must override old picked history on both maps.
- Existing owners' explicit category visibility/artwork choices must survive upgrade.
- Missing/initializing DLC access must prevent queries of every new DLC type.

### Task 1: Audited chest payload

**Files:** scripts/dlc_data.py, scripts/chest_coverage.py, scripts/dataset-manifest.json, DLC JSON, tests/test_chest_coverage.py.

**Interfaces:** `import_coverage(audit_path, trial_path, map_path, data_dir, manifest_path)` consumes accepted missing-chest and trial/map audits and produces four new datasets, trial map associations and extended DLC availability. `validate_dlc_availability(metadata, locations_by_type)` retains structural/unknown-gate checks.

- [x] Add failing checks for 40/48/6 Spoils identities, three quest chests, exact sample coordinates, 185 complete trial map associations and rejection of lost unknown gates.
- [x] Run the tests against v1.5; expect missing payload/unsupported type failures.
- [x] Implement the incremental importer; validate all inputs before replacing output and preserve original base bytes.
- [x] Import the current accepted audit and rerun payload/import validation.

### Task 2: Category, visibility and acquisition behavior

**Files:** dlc_collectibles.lua, chest_availability.lua, map_routing.lua, settings.lua, main Lua, tests/test_dlc_collectibles.lua, tests/test_map_runtime.lua, tests/test_dlc_icons.py, object_icons.lua, icon asset builder/SVG.

**Interfaces:** `map_routing.filter(markers, ui, kind)` uses each marker's optional `map_area` and `map_bounds`; Lost Rites `preview_setting` controls its unsupported availability previews. Spoils follows the general DLC filter, which defaults off. `repeatable_chest_callbacks(chest_callbacks)` queries a loaded chest before saved context.

- [x] Add failing full-script checks for default Lost Rites visibility, selected trial routing despite a field-only range check, Spoils emission on both maps and renewal against picked history.
- [x] Add a 12th nonempty icon-tile check and run it red against existing assets.
- [x] Register the new categories, normalize their preview controls, preserve checked world/quest gates, and route both maps by source data.
- [x] Render the added SVG tile, regenerate additive atlases and run runtime/asset checks.

### Task 3: Release and installation

**Files:** README.md, CHANGELOG.md, THIRD_PARTY_NOTICES.md, docs chest audit, modinfo.ini, nexus-upload/1.5.1, tests/test_build.py if its payload expectations change.

- [x] Update gamer-facing descriptions and limitation text; retain the Dark Arisen section first and base-game compatibility.
- [x] Run the complete test suite and package builder; inspect the exact archive and description length.
- [x] Review the diff for routing, renewal, ownership and packaging errors; correct issues and rerun affected checks.
- [x] With DD2 closed, back up and install only the new marker payload; preserve user settings.
- [x] Commit and push the patch branch and provide an installable kit. Keep native acceptance pending until tested inside a trial.

Review corrected trial routing after the first-token minimap overlay, independent Lost Rites previews with the general DLC filter off, and protection against the legacy import erasing extended trial data. The complete automated run passed 14 Lua suites and 25 Python tests, including removal of the Spoils preview preference, DLC filtering default-off, and preservation of explicit saved choices. Coverage-import fixtures verify idempotence and rejection before writes. Native trial rendering and event renewal still require in-game acceptance.

The fresh archive contains 45 verified files; 44 owned payload files are installed and match the archive. The requested DLC filter is off in the local settings, the obsolete Spoils preference is removed, and all other preferences are preserved. The previous install and settings are backed up locally. The 218-character Nexus file description and all package hashes validate. The published v1.5 archive and twelve base-game datasets remain byte-identical.

Final release preparation exports the mod archive and a separate complete Nexus upload kit to the ignored dist/release-ready/1.5.1 directory. The prepared listing uses release-ready status; GitHub remains staged as a draft for publication. Runtime, data and artwork stay identical to the installed build. In-game DLC validation remains explicitly unverified.
