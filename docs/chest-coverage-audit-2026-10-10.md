# Installed-game chest coverage audit

Compared the published v1.5 datasets with the installed Title Update 4.0 base and Dark Arisen archives. The current executable is 4.0.0.0, TDB 83.

The current native gimmick catalog resolved all 1,023 prefab IDs. Transitive subclasses of `app.gm80_001` identify actual chest prefabs, including `app.gm80_097`, `app.Gm83_016` and `app.Gm83_025`. Loose `app.Gm82_000` pickups were not counted as chests.

Effective placement coverage includes 5,144 base and 3,279 DLC manual resources. A structural parse produced no errors. The 603 relevant chest placement source files were reread from the current archives and matched the reviewed extraction. All 1,606 previously imported chest GUIDs retain their coordinates within 0.01 world units. Another 19,667 effective generation resources outside manualset contained no current `app.GenerateRowData` instances.

| Native ID | Prefab | Added records |
| --- | --- | ---: |
| 908 | Gm83_102 | 40 |
| 1004 | Gm83_102_01 | 48 |
| 1023 | Gm83_102_02 | 6 |
| 994 | Gm80_096_30 | 3 |

The Gm83_102 family strongly matches the reported Spoils chest category: 92 records occur in AppraiseCycle event placements and two in normal icebox placements. Their 94 identities occupy 86 distinct positions. The three Gm80_096_30 records are quest-linked placements. Loot contents and active event/quest availability are not inferred from prefab membership.

All 185 Lost Rites chest positions were matched to their source trial, `rdl_01` through `rdl_012`, and its native UI map ID, 6001 through 6012. Every position lies within that map's installed `MapTexListData.Param` rectangle. Full-map routing uses the displayed trial; minimap routing uses `MapAreaNow`. Trial positions are excluded from outdoor maps. Individual floor assignments are not guessed: full-map markers cover all floors of the selected trial.

Potential Lost Rites/Spoils positions have separate default-on preview controls. Ordinary unresolved DLC quest gates remain guarded. A loaded closed repeatable chest overrides an older acquired context. These are Lua/data regression findings; native DLC rendering, pickup, save reload and renewal acceptance remain pending.

Archive entry-table SHA-256:

- Base: `f3f16130d8609da884e470c333bd42d9c4ecd173d0956daf96c047f3e6cdd9fb`
- Dark Arisen: `02876e88fe318eb0f0d94bff4c09089e812eb1f28b5cbaf1a5334357f60a0ff0`

The ignored local audit contains exact source paths, positions, native prefab hashes and raw placement settings. `scripts/chest_coverage.py` accepts that audited result, attaches verified trial map bounds, validates complete availability coverage before writing, and updates the committed dataset manifest. Normal release builds require no game installation or extraction files.
