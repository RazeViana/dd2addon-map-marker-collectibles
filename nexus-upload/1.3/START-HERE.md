# Nexus upload kit - version 1.3

This folder contains the 1.3 release package and Nexus page materials. Uploading to Nexus is manual; the GitHub release does not update the Nexus page.

## Files to use

- [Map-Markers-and-Collectables-by-Raze-v1.3.zip](Map-Markers-and-Collectables-by-Raze-v1.3.zip) - the complete main download.
- [NEXUS-DETAILS.txt](NEXUS-DETAILS.txt) - copy-ready summary, file description, and version changelog.
- [DESCRIPTION.txt](DESCRIPTION.txt) - complete plain-text Nexus page description.
- [listing.json](listing.json) - structured upload metadata.
- [RELEASE-NOTES.md](RELEASE-NOTES.md) - GitHub release announcement and update instructions.
- [CHANGELOG.md](CHANGELOG.md) - full version history.
- [images/logo.png](images/logo.png) and [images/banner.png](images/banner.png) - existing branding.
- [images/minimap-gameplay.jpg](images/minimap-gameplay.jpg) - existing gameplay image; it does not demonstrate the new fog toggle.
- [SHA256SUMS.txt](SHA256SUMS.txt) and [package-manifest.json](package-manifest.json) - archive checksum and per-file hashes.

## Upload details

| Field | Value |
|---|---|
| Game | Dragon's Dogma 2 |
| Mod name | Map Markers and Collectables by Raze |
| Version | 1.3 |
| Author | Raze |
| Category | User Interface |
| Download category | Main Files |
| Required mod | [REFramework](https://www.nexusmods.com/dragonsdogma2/mods/8) |
| Donation Points | Disabled under the recorded source terms |

Use `NEXUS-DETAILS.txt` for the individual form fields and `DESCRIPTION.txt` for the main description editor. Both use plain text. Keep the source credits and the existing source notice in [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md).

The fog toggle starts disabled. After installing, enable **Hide chests in unexplored areas** directly in the mod's menu and enable the chest categories you want to see. Existing settings can be retained. Install the complete ZIP; replacing only the entry-point Lua file omits the new fog module.

Offline checks pass. The user is handling in-game verification; no fog-edge or native HUD result has been recorded for this release.

## Rebuilding

Run `python tests/run.py` followed by `python scripts/build.py` with the dependencies documented in [DEVELOPMENT.md](../../docs/DEVELOPMENT.md). The builder refreshes this version's ZIP, changelog, checksum, and manifest and preserves the earlier release packages.
