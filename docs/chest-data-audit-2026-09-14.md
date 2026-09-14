# Chest data audit — 14 September 2026

## Current reconciliation

After testing v1.4, Raze requested that every original chest retained in the list exist in the fresh extraction. The two unmatched original GUIDs were removed from active location data and availability metadata, and the extra-large coordinate difference was corrected. The 54 additions remain. Retained GUIDs are unchanged, so saved collection lookup keeps the same identities.

All **1,032 active chest GUIDs and types exactly match the fresh extraction**, including the 12 retained, unexposed Sphinx records. The seven displayed categories contain **1,020 chests**. All coordinates agree within 0.01 world units; the largest remaining rounding difference is approximately 0.000123. Tokens and beetles are unchanged, bringing all twelve location datasets to 1,350 entries.

| Category | Current list | Fresh extraction |
| --- | ---: | ---: |
| Small | 637 | 637 |
| Medium | 232 | 232 |
| Large | 63 | 63 |
| Extra large | 82 | 82 |
| Special, all sizes | 6 | 6 |
| Unexposed Sphinx records | 12 | 12 |
| **Total** | **1,032** | **1,032** |

The removal check re-read and verified the hashes of all 21,374 extracted generation resources. Neither missing GUID's serialized bytes appeared in any file. The installed executable still reports version 3.2.0.0. This establishes absence from the audited extraction, not proof that no unexamined runtime mechanism could ever create a chest.

Original positions for the two retirements and one correction remain in the development dataset manifest, outside the runtime location data. The build checks per-type fresh GUID hashes/counts and reconstructs the original baseline from retained, added, retired and corrected records. The importer requires `--reconcile` for removals or position changes and rejects duplicate fresh GUIDs and incomplete type coverage. A second import leaves the accepted data unchanged.

## Initial audit

The initial comparison found **54 chest candidates absent from the original datasets**: 39 small and 15 medium. Two original chest IDs were not found, and one extra-large chest had a different placement coordinate. The first v1.4 update accepted the additions with progression metadata after tracing catalog references, while retaining unmatched originals. The reconciliation above supersedes that retention decision.

## Comparison

The comparison keys each chest by its gimmick type and manual placement GUID. Coordinate agreement means the three-dimensional distance is at most 0.01 world units; this avoids treating the bundled JSON's rounded coordinates as movement.

| Category | Bundled | Extracted unique IDs | Additional candidates | Bundled IDs not found | Coordinate changes |
| --- | ---: | ---: | ---: | ---: | ---: |
| Small (10) | 599 | 637 | 39 | 1 | 0 |
| Medium (11) | 217 | 232 | 15 | 0 | 0 |
| Large (12) | 63 | 63 | 0 | 0 | 0 |
| Extra large (495) | 83 | 82 | 0 | 1 | 1 |
| Special small (692) | 1 | 1 | 0 | 0 | 0 |
| Special medium (693) | 4 | 4 | 0 | 0 | 0 |
| Special large (694) | 1 | 1 | 0 | 0 | 0 |
| **Displayed categories total** | **968** | **1,020** | **54** | **2** | **1** |

Of the 968 original displayed chest records, 965 had the same GUID and agreed within the coordinate tolerance, one had a coordinate difference, and two were not found. The 12 retained Sphinx records in datasets 13, 465 and 653 also match; these are outside the mod's seven displayed chest categories. No extracted chest GUID has conflicting placement coordinates.

The additional candidates come from five placement groups. These are internal asset identifiers, not verified player-facing location names:

| Placement group | Candidates | With explicit row quest conditions |
| --- | ---: | ---: |
| `content/twn01_04/.../chest` | 24 | 1 |
| `content/town_017/.../chest` | 13 | 13 |
| `field/editfield_151/.../chest` | 11 | 0 |
| `content/spot_04/.../chest/sub` | 5 | 1 |
| `field/editfield_70/.../chest` | 1 | 0 |

Fifteen candidates have explicit quest records: 13 refer to quest 11020, one to 10190 and one to 30210. Their check flags are preserved in the audit JSON. The other 39 have no explicit row quest records; that does not establish unconditional availability, since area activation, table references and other game logic can still matter.

The unmatched bundled records are:

- Small `039111c8-215f-0eb0-21fd-d03f0ea5b286`, at `[-282.1467, 18.8624325, 1068.55725]`.
- Extra large `1bb96bde-8889-484a-9f9a-c245c35988ba`, at `[-368.9458, -0.0318337567, -649.773438]`.

Neither GUID's serialized bytes occur anywhere in the 21,374 extracted generation resources. This supports “not found in this scope,” not a claim that the chest was definitively removed from the game.

Extra-large chest `6675ab01-d4a7-4db9-afc7-54b825cf043c` differed by approximately 1.314 world units. Its original position was `[1034.27722, -2.64327669, -1122.24377]`; it now uses the extracted placement `[1033.7398681640625, -1.4862895011901855, -1121.9281005859375]`. It comes from `field/editfield_90/gimmick_back/normal/normal.user.3`. The correction aligns the marker with placement data; final visual positioning still needs an in-game check.

## Source and validation

- Source: the local Dragon's Dogma 2 installation, executable file/product version **3.2.0.0**. Archives were read without modifying the installation or launching the game.
- Filename coverage: the union of the workspace's older `DD2.list` and [REE-Lib-Resources' DD2 catalog](https://github.com/kagenocookie/REE-Lib-Resources/tree/master/dd2). All 21,374 generation paths in the newer catalog were found as `.user.3`; 22 paths unique to the older catalog were not found. Unknown filenames outside these catalogs remain outside coverage.
- Extraction: 21,374 generation resources, totaling 104,837,152 bytes. Matching resources were all in `re_chunk_000.pak`; the installed patch archives contained no matching generation paths. Resource hashes and archive inventories are recorded locally.
- A schema-independent scan of every USER/RSZ instance table found `app.GenerateRowData` in 2,256 files, all inside `manualset`. No grid resource contains that direct record type.
- Parsing: all **2,573 manual placement files** parsed, producing **22,147 rows** across all entity types, with no bounds, reference or unconsumed-data errors. This is structural validation, not proof of in-game spawning.
- [REE-Lib's USER/RSZ implementation](https://github.com/kagenocookie/RE-Engine-Lib) was used as a binary-format reference. Public DD2 schemas have stale class CRCs for this installation. The parser rejects CRC differences by default; this audit explicitly used diagnostic mode.
- Installed executable metadata supports three schema adjustments: `_EventFlags` on `app.GenerateTable` is 64-bit; `app.GenerateTable.SetInfo` no longer has `_RefillNodes`; and current `app.RandomManualSetTable.RandomManualSetInfo` uses the two-field layout previously named `app.GenerateTableListData.RandomManualSetInfo`. `via.Position` contains three 64-bit coordinates. These checks do not certify the current serialized class CRCs.

## Local audit artifacts

Extracted game resources and working schemas stay in the ignored `reference/runtime/chest-audit/` directory and are excluded from the mod package.

- `fresh-chest-records.json`: extracted chest GUIDs, types, positions, source paths, parameters and placement conditions, retaining all source records.
- `chest-comparison.json`: category counts and full additional, unmatched and changed records.
- `catalog-coverage.json`, `generation-coverage.json`, `pak-inventory.json`, `extraction-all.json`: scope and extraction provenance.
- `diagnostic-manual-tdb.json`: parsed records and every encountered schema CRC mismatch.
- `format-evidence.md`, `current-tdb-schema-evidence.json`: binary-format evidence, precise schema changes, artifact hashes and reproduction commands. `inspect_current_types.py` and `make_diagnostic_schema.py` regenerate the executable evidence and adjusted schema.
- `audit_pak.py`, `parse_rsz.py`, `inspect_coverage.py`, `compare_chests.py`: local extraction, parsing and comparison scripts. `audit_pak.py all` recreates the complete extraction; the parser requires the adjusted schema and explicit `--diagnostic-ignore-crc` for this game build.

The accepted list now matches the fresh extraction. Native quest activation, world transitions and exact visual placement remain distinct from this data-alignment verification. Three displayed quest-action chests have supported placements but unresolved activation rules, and are hidden while unopened when progression filtering is enabled.
