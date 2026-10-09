# Dark Arisen placement audit — October 9, 2026

The installed Steam build is 25290080; `DD2.exe` reports version 4.0.0.0 and TDB 83. The Dark Arisen archive `dlc/re_dlc_stm_2593290.pak` contains 114,168 entries and is 26,906,257,761 bytes. Its decrypted entry-table SHA-256 is `02876e88fe318eb0f0d94bff4c09089e812eb1f28b5cbaf1a5334357f60a0ff0`.

The current upstream filename catalog resolves 4,746 DLC generation USER resources, including 3,279 manual placement resources. All 3,279 parse after checking new resource structures against the current executable; 21,959 placement rows result. Identity, finite coordinates, source variants and catalog references are preserved before importing the fixed collectible subset.

| Native gimmick ID | Fixed placements | Category |
| --- | ---: | --- |
| 826 | 267 | Norgan chests |
| 885 | 122 | Norgan rare chests |
| 894 | 140 | Norgan Ducat coin/medal placements |
| 755 | 119 | Lost Rites chest subclass |
| 757 | 47 | Lost Rites chest subclass |
| 758 | 10 | Lost Rites chest subclass |
| 795 | 9 | Lost Rites chest subclass |

The total is 714 distinct GUIDs: 574 chests and 140 fixed coin/medal placements. Lost Rites resources contain 187 serialized rows representing 185 distinct chest GUIDs; duplicate source variants have identical coordinates. Item-drop objects with ID 756 are excluded even when their paths contain `chest`, because their native class is not a chest. Random drops and appraised relic contents are outside fixed-placement coverage.

Norgan records have normal-world catalog references. Six rare chests carry a quest-variable condition for quest 40010 (variable-name hash 1963397663); that native condition is not yet evaluated by the patch, so unopened records remain hidden while progression filtering is on. Lost Rites trial activation and renewal are unverified. All 185 trial records remain guarded, including three uncatalogued subquest-only records with unresolved availability. Previewing those positions by disabling the progression filter does not establish availability.

The installed English item message `item_name_711`, GUID `c6f5b10d-4f8f-4144-8775-77ec81eff88d`, names **Norgan Ducat**. Its matching item-detail entry describes the Norgan collectible and exchange rewards. The coin/medal paths, coin-shop resource and native `app.Gm83_169` prefab support the placement classification. The native class exposes static `FreeBitGet` and `get_IsGetFreeBit`; the initialized mask must be read at runtime. Static metadata alone does not establish a bit-16 save interpretation.

The effective October 9 base and DLC resources reproduce all 1,350 existing bundled placements across twelve datasets. No GUID is missing or added, and no position differs by more than 0.01 world units (maximum rounding difference approximately 0.000123). Existing datasets are retained byte-for-byte.

Both native map UVS resources gained one pattern: full-map 84→85 and minimap 81→82. Their earlier pattern prefixes are identical. The new tuple uses UV coordinates `(0.3125, 0.5, 0.375, 0.625)` with full-map texture index 1 and minimap texture index 0. The new glyph resembles a loot bag; it is preserved without assuming it is the Ducat icon.

Reviewed compact imports have SHA-256 `50600c88ce668ba2b30621d8d0d309c395c7b891382f91f9d6304cc6cedf9d1f` (Norgan) and `f4b48a01f413b87f3fa7a4567d7bae9a47b62f62dbc92227bb9edb7ad057366e` (Lost Rites). Original-data alignment report SHA-256 is `e394cacc8801df64db0a1095c638973f59e5f6da148f0aacc6aae2398634c96f`. Committed dataset/availability manifests preserve these provenance hashes. Local extraction artifacts live under ignored `reference/runtime/dlc-audit`; they are excluded from the mod ZIP.

To repeat an accepted import, run `scripts/dlc_data.py --collectibles <reviewed-Norgan-audit> --ritual <reviewed-Lost-Rites-audit>`, then the test runner and release builder. Validate new extraction structures and review gates before accepting a changed audit. Native map routing, pickup/hand-in, save reload and trial renewal remain pending.
