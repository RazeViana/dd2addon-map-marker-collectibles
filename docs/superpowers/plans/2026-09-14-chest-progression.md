# Chest Progression Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement the tasks with verification checkpoints.

**Goal:** Update chest placements and make collected-state tracking, progression visibility and category appearance work together on both maps.

**Architecture:** Keep stable location GUIDs and store availability metadata separately. A chest availability module evaluates metadata against native state after the marker cache, while acquisition remains sourced from the save database. Category settings select glyphs and colors through the existing additive icon atlas.

**Tech Stack:** Lua 5.4, REFramework, Python 3.12/Lupa, existing SVG/Sharp atlas builder.

**Spec:** `docs/superpowers/specs/2026-09-14-chest-progression-design.md`

## Global constraints

- Version remains 1.4; default branch is master.
- Preserve original GUIDs, unrelated edits, saved settings and original dataset attribution.
- Never write acquisition state or quest flags into the game save.
- Keep extracted game files and diagnostic schemas out of the package.

## Task 1: Saved acquisition state

Files: main autorun Lua and `tests/test_map_runtime.lua`.

- [x] Add late-install tests with existing `GmItemContext.IsPick`, unloaded objects and a loaded object returning false; add context replacement/reload tests.
- [x] Run the regression tests and observe the saved-true/loaded-false precedence failure.
- [x] Make a loaded positive chest-open result conclusive and allow false to fall through to saved context. Preserve existing save-reset hooks.
- [x] Verify map/minimap state and context-lock cleanup.

## Task 2: Appearance customization

Files: `settings.lua`, `object_icons.lua`, main autorun Lua, `assets/icons/`, `scripts/icon_assets.py`, `scripts/render-icons.cjs`, settings/object-icon/runtime tests.

Interfaces: `object_icons.resolve_type(marker_type, marker_settings, prefix, use_objects)` returns a validated glyph index. `unacquired_icon_style` and `acquired_icon_style` use stable string keys; `default` follows the existing global object-icon setting, `native` uses the preserved native type.

- [x] Test migration of saved colors/native indices, invalid style values, per-state overrides and new glyph fallback/restoration.
- [x] Add small, large and sunken chest silhouettes to the existing SVG system and atlas; preserve original native patterns and existing custom indices 76–79.
- [x] Add named per-state appearance selectors and distinct category defaults; reset only the selected appearance state.
- [x] Render/view the atlas and run settings, icon and package asset checks.

## Task 3: Availability data and runtime policy

Files: new `chest_availability.lua`, native adapter if useful, separate chest availability JSON, numerical chest datasets, dataset manifest, `scripts/build.py`, new availability/data tests, main autorun integration.

Interface: `availability:filter(markers, settings, kind)` returns visible markers, preserving acquired markers and non-chest markers. `availability:reset()` invalidates saved-session-dependent state. Metadata uses stable GUID keys and explicit world/quest rules; native evaluation must return true, false or unknown.

- [x] Generate metadata from verified placement rows/catalog membership and audit every new candidate's catalog source reference.
- [x] Test normal/Unmoored transitions, early reveal without quest bypass, acquired-history visibility, unknown native state, quest completion, filter disabling and independent fog filtering.
- [x] Implement native state reads only with verified signatures and enum meanings; cache bounded state snapshots, not permanent availability decisions.
- [x] Append 54 GUIDs while preserving original locations, update data provenance/hashes and validate every rule's reference to a bundled GUID.
- [x] Apply progression filtering after cached marker creation and before map range/capacity selection; invalidate on settings/save transitions.

## Task 4: Packaging and documentation

Files: README, CHANGELOG, DEVELOPMENT, build allowlists and tests.

- [x] Document defaults, overrides, category customization and late-install collection tracking with native-test limitations.
- [x] Run `tests/run.py` with bundled Python 3.12, inspect all results, and run `scripts/build.py`.
- [x] Review the combined diff and inspect the ZIP for availability data, runtime modules and icon assets; exclude settings/diagnostics.
- [x] Leave an in-game checklist for collected chests predating install, save/NG+ changes, normal/Unmoored transitions and conditional chest rewards.

## Follow-up: Reconcile originals with fresh data

The user's subsequent request supersedes the initial decision to retain unmatched original locations.

- [x] Recompare all chest GUIDs/types/positions and recheck unmatched GUID bytes across all 21,374 extracted resources.
- [x] Remove two unsupported active records and correct the one position difference beyond 0.01 world units, keeping retained GUIDs stable.
- [x] Preserve original provenance in the development manifest and enforce the verified fresh GUID set during builds.
- [x] Cover reconciliation, original baseline reconstruction and repeated import with regression tests; refresh the audit report and packaged documentation.
